function win_cmd () {
    cmd.exe /C "$@" | tr -d '\r'
}

function win_path_to_wsl () {
    echo $(wslpath $(win_cmd "echo $@" | sed 's/WINDOWS/Windows/'))
}