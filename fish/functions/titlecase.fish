function titlecase -d 'convert text to title case with the python titlecase module'
    if test (count $argv) -gt 0
        python -c 'import titlecase; import sys; print(titlecase.titlecase(" ".join(sys.argv[1:])))' $argv
    else
        python -c 'import titlecase; import sys; print(titlecase.titlecase(sys.stdin.read().rstrip()))'
    end
end
