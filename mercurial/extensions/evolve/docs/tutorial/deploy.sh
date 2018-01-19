mkdir -p html

cp index.html html/
cp *.css html/
cp *.js html/
cp -R img html/
cp -R graphviz-images/ html/

netlify deploy
