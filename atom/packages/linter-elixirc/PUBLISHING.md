# Publishing

A few pointers if you haven't published a package on Atom before:
You will need to publish new versions by checking out this base repository somewhere, then running apm publish {major|minor|patch} in that directory. It will create a new tag and modify the version in package.json for you. If you want GitHub to also show which is the latest release you will need to go to the releases and edit the latest tag to mark it as latest on GitHub.
