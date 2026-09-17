from pathlib import Path

p = Path("/opt/alrasmarket/app/docker-compose.yml")
text = p.read_text()
if "6333:6333" in text:
    print("ports_already_present")
else:
    needle = (
        "  qdrant:\n"
        "    image: qdrant/qdrant:v1.13.2\n"
        "    container_name: alras-qdrant\n"
        "    restart: unless-stopped\n"
        "    volumes:\n"
        "      - qdrant_data:/qdrant/storage\n"
        "    networks:\n"
        "      - alras\n"
        "    expose:\n"
        '      - "6333"\n'
    )
    repl = (
        "  qdrant:\n"
        "    image: qdrant/qdrant:v1.13.2\n"
        "    container_name: alras-qdrant\n"
        "    restart: unless-stopped\n"
        "    volumes:\n"
        "      - qdrant_data:/qdrant/storage\n"
        "    networks:\n"
        "      - alras\n"
        "    ports:\n"
        '      - "6333:6333"\n'
        '      - "6334:6334"\n'
        "    expose:\n"
        '      - "6333"\n'
    )
    if needle not in text:
        raise SystemExit("qdrant block not found")
    p.write_text(text.replace(needle, repl, 1))
    print("patched")
