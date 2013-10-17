function gi -d "gitignore.io: generate useful .gitignore files for your project. Run 'gi list' to see available keywords."
    curl http://gitignore.io/api/$argv[1]
end
