if [[ $OSTYPE = WSL ]]; then
    path=(${0:h:A}/scripts-wsl $path)

    # %PATH% isn't necessarily set when we ssh in
    path=($WslDisks/c/Windows $WslDisks/c/Windows/SysWOW64 $WslDisks/c/Windows/System32 $path)

    # adb
    path=($WslDisks/c/Android/android-sdk/platform-tools $path)
fi
