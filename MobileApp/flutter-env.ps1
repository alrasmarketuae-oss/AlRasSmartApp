$env:ANDROID_HOME = "$env:LOCALAPPDATA\Android\Sdk"
$env:ANDROID_SDK_ROOT = $env:ANDROID_HOME
$env:GRADLE_USER_HOME = "$env:USERPROFILE\.gradle"
$env:JAVA_HOME = "C:\src\jdk-17"
$env:Path = @(
  "C:\src\flutter\bin",
  "$env:ANDROID_HOME\platform-tools",
  "$env:ANDROID_HOME\emulator",
  $env:Path
) -join ";"
Write-Host "Flutter ready: $(flutter --version | Select-Object -First 1)"
Write-Host "adb: $(adb version 2>&1 | Select-Object -First 1)"
