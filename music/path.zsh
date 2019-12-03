if [[ $OSTYPE =~ darwin* ]]; then
    # Ensure we can run `fpcalc`
    path=(/Applications/MusicBrainz\ Picard.app/Contents/MacOS $path)
fi
