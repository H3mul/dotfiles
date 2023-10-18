function win_cmd () {
    cmd.exe /C "$@" 2>/dev/null | tr -d '\r'
}
