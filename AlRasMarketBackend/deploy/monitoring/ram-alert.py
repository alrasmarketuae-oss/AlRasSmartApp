#!/usr/bin/env python3
"""Tiered RAM alerts with container diagnostics — no automatic restarts."""

from __future__ import annotations

import json
import os
import smtplib
import ssl
import subprocess
import sys
import time
from dataclasses import dataclass
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from pathlib import Path


@dataclass
class MemSnapshot:
    percent: float
    total_gb: float
    used_gb: float
    available_gb: float
    swap_total_gb: float
    swap_used_gb: float
    swap_percent: float


@dataclass
class ContainerStat:
    name: str
    mem_usage: str
    mem_percent: float
    cpu_percent: float


def load_env(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    if not path.is_file():
        return values

    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        values[key.strip()] = value.strip().strip('"').strip("'")
    return values


def kb_to_gb(value_kb: int) -> float:
    return value_kb / (1024 * 1024)


def read_mem_snapshot() -> MemSnapshot:
    meminfo = Path("/proc/meminfo").read_text(encoding="utf-8")
    data: dict[str, int] = {}
    for line in meminfo.splitlines():
        if ":" not in line:
            continue
        key, raw_value = line.split(":", 1)
        data[key.strip()] = int(raw_value.strip().split()[0])

    total = data.get("MemTotal", 0)
    available = data.get("MemAvailable", data.get("MemFree", 0))
    if total <= 0:
        raise RuntimeError("Could not read MemTotal from /proc/meminfo")

    used = total - available
    swap_total = data.get("SwapTotal", 0)
    swap_free = data.get("SwapFree", 0)
    swap_used = max(swap_total - swap_free, 0)
    swap_percent = (swap_used / swap_total * 100.0) if swap_total > 0 else 0.0

    return MemSnapshot(
        percent=(used / total) * 100.0,
        total_gb=kb_to_gb(total),
        used_gb=kb_to_gb(used),
        available_gb=kb_to_gb(available),
        swap_total_gb=kb_to_gb(swap_total),
        swap_used_gb=kb_to_gb(swap_used),
        swap_percent=swap_percent,
    )


def parse_docker_mem_percent(raw: str) -> float:
    cleaned = raw.strip().rstrip("%")
    try:
        return float(cleaned)
    except ValueError:
        return 0.0


def read_top_containers(limit: int = 5) -> list[ContainerStat]:
    try:
        result = subprocess.run(
            [
                "docker",
                "stats",
                "--no-stream",
                "--format",
                "{{json .}}",
            ],
            capture_output=True,
            text=True,
            timeout=20,
            check=False,
        )
    except (OSError, subprocess.TimeoutExpired):
        return []

    if result.returncode != 0:
        return []

    containers: list[ContainerStat] = []
    for line in result.stdout.splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            row = json.loads(line)
        except json.JSONDecodeError:
            continue

        name = str(row.get("Name", "unknown"))
        containers.append(
            ContainerStat(
                name=name,
                mem_usage=str(row.get("MemUsage", "n/a")),
                mem_percent=parse_docker_mem_percent(str(row.get("MemPerc", "0"))),
                cpu_percent=parse_docker_mem_percent(str(row.get("CPUPerc", "0"))),
            )
        )

    containers.sort(key=lambda item: item.mem_percent, reverse=True)
    return containers[:limit]


def read_load_average() -> tuple[float, float, float]:
    one, five, fifteen = os.getloadavg()
    return one, five, fifteen


def read_recent_oom_events(max_lines: int = 5) -> list[str]:
    commands = [
        ["dmesg", "-T"],
        ["journalctl", "-k", "-n", "200", "--no-pager"],
    ]
    keywords = ("out of memory", "oom-kill", "killed process")

    for command in commands:
        try:
            result = subprocess.run(
                command,
                capture_output=True,
                text=True,
                timeout=15,
                check=False,
            )
        except (OSError, subprocess.TimeoutExpired):
            continue

        if result.returncode != 0 or not result.stdout.strip():
            continue

        matches = [
            line.strip()
            for line in result.stdout.splitlines()
            if any(keyword in line.lower() for keyword in keywords)
        ]
        if matches:
            return matches[-max_lines:]

    return []


def read_state(path: Path) -> dict[str, str]:
    if not path.is_file():
        return {}
    data: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        if "=" not in line:
            continue
        key, value = line.split("=", 1)
        data[key.strip()] = value.strip()
    return data


def write_state(path: Path, data: dict[str, str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    content = "\n".join(f"{key}={value}" for key, value in data.items()) + "\n"
    path.write_text(content, encoding="utf-8")


def clear_state(path: Path) -> None:
    if path.is_file():
        path.unlink(missing_ok=True)


def cooldown_elapsed(last_sent_raw: str | None, cooldown_seconds: int) -> bool:
    if not last_sent_raw:
        return True
    try:
        last_sent = float(last_sent_raw)
    except ValueError:
        return True
    return (time.time() - last_sent) >= cooldown_seconds


def format_container_lines(containers: list[ContainerStat]) -> str:
    if not containers:
        return "Top containers: unavailable (docker stats failed)\n"

    lines = ["Top containers:"]
    for index, container in enumerate(containers, start=1):
        display_name = container.name.replace("alras-", "").upper()
        lines.append(
            f"{index}. {display_name:<8} {container.mem_usage:<18} "
            f"({container.mem_percent:.1f}% mem, {container.cpu_percent:.1f}% cpu)"
        )
    return "\n".join(lines)


def format_diagnostics(snapshot: MemSnapshot, containers: list[ContainerStat]) -> str:
    load1, load5, load15 = read_load_average()
    oom_events = read_recent_oom_events()

    lines = [
        f"RAM Usage: {snapshot.percent:.1f}%",
        f"Memory: {snapshot.used_gb:.2f} GB used / {snapshot.total_gb:.2f} GB total "
        f"({snapshot.available_gb:.2f} GB available)",
        "",
        format_container_lines(containers),
        "",
        f"Swap: {snapshot.swap_used_gb:.2f} GB / {snapshot.swap_total_gb:.2f} GB "
        f"({snapshot.swap_percent:.1f}%)",
        f"Load average (1/5/15m): {load1:.2f}, {load5:.2f}, {load15:.2f}",
        "Recent OOM events: "
        + ("none detected" if not oom_events else "\n  - " + "\n  - ".join(oom_events)),
        "",
        "No automatic restart was performed.",
        "Review docker stats, swap, OOM, and CPU before restarting any service.",
    ]
    return "\n".join(lines)


def build_warning_message(snapshot: MemSnapshot, hostname: str, containers: list[ContainerStat]) -> tuple[str, str]:
    diagnostics = format_diagnostics(snapshot, containers)
    subject = f"[Warning] RAM usage is high ({snapshot.percent:.1f}%) on {hostname}"
    body = f"""السلام عليكم،

تنبيه Warning: استخدام الرام مرتفع على السيرفر ({hostname}).

{diagnostics}

هذا تنبيه مبكر بين 80% و90%. الرجاء مراجعة السيرفر قبل وصول الاستخدام لمستوى حرج.

---
تم تعيين هذه الرسالة من المطور ناصر مصطفي لتنبيهك بشأن اقتراب السيرفر من السقوط.

Warning: RAM usage is elevated on server ({hostname}).

{diagnostics}
"""
    return subject, body


def build_critical_message(snapshot: MemSnapshot, hostname: str, containers: list[ContainerStat]) -> tuple[str, str]:
    diagnostics = format_diagnostics(snapshot, containers)
    subject = f"[Critical] RAM usage sustained at {snapshot.percent:.1f}% on {hostname}"
    body = f"""السلام عليكم،

تنبيه Critical: استخدام الرام وصل 90% أو أكثر لمدة 5 دقائق على السيرفر ({hostname}).

{diagnostics}

تم وصول الرام 90% من الاستخدام. يرجى مراجعة السيرفر فوراً قبل حدوث توقف في الخدمة.
توقف الخدمة تعني توقف كل شيء في النظام من تسجيل الدخول إلى نشر الإعلانات.

---
تم تعيين هذه الرسالة من المطور ناصر مصطفي لتنبيهك بشأن اقتراب السيرفر من السقوط.

Critical: RAM usage remained at or above 90% for 5 minutes on server ({hostname}).

{diagnostics}

--- This message was set by the developer, Nasser Mustafa, to warn you about the server's imminent failure.
"""
    return subject, body


def send_email(
    smtp_server: str,
    smtp_port: int,
    sender_email: str,
    sender_password: str,
    sender_name: str,
    recipients: list[str],
    subject: str,
    body: str,
) -> None:
    message = MIMEMultipart()
    message["From"] = f"{sender_name} <{sender_email}>"
    message["To"] = ", ".join(recipients)
    message["Subject"] = subject
    message.attach(MIMEText(body, "plain", "utf-8"))

    context = ssl.create_default_context()
    with smtplib.SMTP(smtp_server, smtp_port, timeout=30) as client:
        client.ehlo()
        client.starttls(context=context)
        client.ehlo()
        client.login(sender_email, sender_password)
        client.sendmail(sender_email, recipients, message.as_string())


def main() -> int:
    script_dir = Path(__file__).resolve().parent
    env = load_env(script_dir / "ram-alert.env")

    force_test = "--test-email" in sys.argv
    force_warning = "--test-warning" in sys.argv
    force_critical = "--test-critical" in sys.argv

    warning_threshold = float(env.get("WARNING_THRESHOLD_PERCENT", "80"))
    critical_threshold = float(env.get("CRITICAL_THRESHOLD_PERCENT", "90"))
    critical_sustain_seconds = int(env.get("CRITICAL_SUSTAIN_SECONDS", "300"))
    warning_cooldown_seconds = int(env.get("WARNING_COOLDOWN_SECONDS", "3600"))
    critical_cooldown_seconds = int(env.get("CRITICAL_COOLDOWN_SECONDS", "3600"))
    warning_reset_below = float(env.get("WARNING_RESET_BELOW_PERCENT", "78"))
    critical_reset_below = float(env.get("CRITICAL_RESET_BELOW_PERCENT", "85"))

    smtp_server = env.get("SMTP_SERVER", "smtp.gmail.com")
    smtp_port = int(env.get("SMTP_PORT", "587"))
    sender_email = env.get("SENDER_EMAIL", "")
    sender_password = env.get("SENDER_PASSWORD", "")
    sender_name = env.get("SENDER_NAME", "Al Ras Server Monitor")

    recipients_raw = env.get(
        "ALERT_RECIPIENTS",
        "nasermostafa.ma122@gmail.com,alrasmarketuae@gmail.com,merge.foodstuff.ae@gmail.com",
    )
    recipients = [item.strip() for item in recipients_raw.split(",") if item.strip()]

    warning_state_file = Path(env.get("WARNING_STATE_FILE", str(script_dir / ".ram-warning-state")))
    critical_state_file = Path(env.get("CRITICAL_STATE_FILE", str(script_dir / ".ram-critical-state")))

    if not sender_email or not sender_password:
        print("Missing SENDER_EMAIL or SENDER_PASSWORD in ram-alert.env", file=sys.stderr)
        return 2

    if not recipients:
        print("No recipients configured.", file=sys.stderr)
        return 2

    snapshot = read_mem_snapshot()
    hostname = os.uname().nodename
    containers = read_top_containers()

    if force_test or force_warning or force_critical:
        if force_warning:
            test_snapshot = MemSnapshot(
                percent=max(snapshot.percent, warning_threshold),
                total_gb=snapshot.total_gb,
                used_gb=snapshot.used_gb,
                available_gb=snapshot.available_gb,
                swap_total_gb=snapshot.swap_total_gb,
                swap_used_gb=snapshot.swap_used_gb,
                swap_percent=snapshot.swap_percent,
            )
            subject, body = build_warning_message(test_snapshot, hostname, containers)
            prefix = "[اختبار Warning]"
        elif force_critical:
            test_snapshot = MemSnapshot(
                percent=max(snapshot.percent, critical_threshold),
                total_gb=snapshot.total_gb,
                used_gb=snapshot.used_gb,
                available_gb=snapshot.available_gb,
                swap_total_gb=snapshot.swap_total_gb,
                swap_used_gb=snapshot.swap_used_gb,
                swap_percent=snapshot.swap_percent,
            )
            subject, body = build_critical_message(test_snapshot, hostname, containers)
            prefix = "[اختبار Critical]"
        else:
            subject, body = build_critical_message(
                MemSnapshot(
                    percent=max(snapshot.percent, critical_threshold),
                    total_gb=snapshot.total_gb,
                    used_gb=snapshot.used_gb,
                    available_gb=snapshot.available_gb,
                    swap_total_gb=snapshot.swap_total_gb,
                    swap_used_gb=snapshot.swap_used_gb,
                    swap_percent=snapshot.swap_percent,
                ),
                hostname,
                containers,
            )
            body = "رسالة اختبار من نظام مراقبة الرام على السيرفر.\n\n" + body
            prefix = "[اختبار]"

        send_email(
            smtp_server=smtp_server,
            smtp_port=smtp_port,
            sender_email=sender_email,
            sender_password=sender_password,
            sender_name=sender_name,
            recipients=recipients,
            subject=f"{prefix} {subject}",
            body=body,
        )
        print(f"Test alert email sent to {len(recipients)} recipient(s).")
        return 0

    percent = snapshot.percent
    now = time.time()

    if percent < warning_reset_below:
        clear_state(warning_state_file)
    if percent < critical_reset_below:
        clear_state(critical_state_file)

    if percent < warning_threshold:
        print(f"RAM OK: {percent:.1f}% (warning >= {warning_threshold:.1f}%, critical >= {critical_threshold:.1f}%)")
        return 0

    # Warning tier: 80% <= RAM < 90%
    if warning_threshold <= percent < critical_threshold:
        warning_state = read_state(warning_state_file)
        if cooldown_elapsed(warning_state.get("last_sent"), warning_cooldown_seconds):
            subject, body = build_warning_message(snapshot, hostname, containers)
            send_email(
                smtp_server=smtp_server,
                smtp_port=smtp_port,
                sender_email=sender_email,
                sender_password=sender_password,
                sender_name=sender_name,
                recipients=recipients,
                subject=subject,
                body=body,
            )
            write_state(
                warning_state_file,
                {"last_sent": str(now), "last_percent": f"{percent:.1f}"},
            )
            print(f"Warning alert sent at {percent:.1f}%.")
        else:
            print(f"Warning level ({percent:.1f}%) but warning alert is in cooldown.")
        return 0

    # Critical tier: RAM >= 90%, must stay there for 5 minutes
    critical_state = read_state(critical_state_file)
    since_raw = critical_state.get("since")
    if not since_raw:
        write_state(
            critical_state_file,
            {"since": str(now), "last_percent": f"{percent:.1f}"},
        )
        print(f"Critical threshold reached ({percent:.1f}%). Waiting {critical_sustain_seconds}s before alert.")
        return 0

    try:
        since = float(since_raw)
    except ValueError:
        since = now
        write_state(critical_state_file, {"since": str(now), "last_percent": f"{percent:.1f}"})

    sustained_for = now - since
    if sustained_for < critical_sustain_seconds:
        write_state(
            critical_state_file,
            {"since": str(since), "last_percent": f"{percent:.1f}"},
        )
        print(
            f"Critical level ({percent:.1f}%) for {int(sustained_for)}s "
            f"(need {critical_sustain_seconds}s)."
        )
        return 0

    if not cooldown_elapsed(critical_state.get("last_sent"), critical_cooldown_seconds):
        print(f"Critical sustained ({percent:.1f}%) but critical alert is in cooldown.")
        return 0

    subject, body = build_critical_message(snapshot, hostname, containers)
    send_email(
        smtp_server=smtp_server,
        smtp_port=smtp_port,
        sender_email=sender_email,
        sender_password=sender_password,
        sender_name=sender_name,
        recipients=recipients,
        subject=subject,
        body=body,
    )
    write_state(
        critical_state_file,
        {
            "since": str(since),
            "last_sent": str(now),
            "last_percent": f"{percent:.1f}",
        },
    )
    print(f"Critical alert sent at {percent:.1f}% after {int(sustained_for)}s sustained.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
