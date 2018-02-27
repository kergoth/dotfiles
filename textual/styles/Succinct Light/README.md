Succinct Style for Textual
==========================

Succinct is a theme for the Textual IRC client based on the [Colloquy theme of the same name](https://github.com/TempSpas/succinct-for-colloquy). It utilizes the [Solarized](http://ethanschoonover.com/solarized) color palette. The code was originally built off of the [Sulaco](https://github.com/rgrove/textual-sulaco) dark theme. A dark variant of this theme is available [here](https://github.com/TempSpas/textual-succinct).

![Screenshot](/screenshots/screenshot1.png?raw=true)

## Features

* Simple, clean design that emphasizes what you need and de-emphasizes what you don’t.

* Doesn't overwrite any of your preferences. Want to use a light UI with Succinct?
  You can. Want to change how nicknames or timestamps are formatted? Great! The theme is unobtrusive.

* Coalesces multiple consecutive messages from the same sender rather than
  displaying the same nickname over and over.

* Provides handy start and end markers for ZNC playback.

* Plucks the ugly in-message timestamps out of ZNC playback and puts them in the
  timestamp column where they belong.

## Installing

1. Download the Succinct theme by going to the [release page](https://github.com/TempSpas/SuccinctLight/releases) and downloading the latest version of `SuccinctLight.zip`.

2. Open Textual's preferences. Go to `Addons`->`Installed Addons` and click the
   `Open in Finder` button next to the `Custom Addons Location` label.

3. Browse to Textual's `Styles` directory.

4. Extract the Succinct theme here, into its own folder.

The theme will now be ready to use, accessible in Textual's preferences under `Style`.

<!-- NOTE: The theme currently displays the full topic bar at all times. If you wish to have it display a shortened version that lengthens upon hovering, uncomment the lines marked at 576 and 584. -->

## TO-DO

* Still not really happy with the highlight message color. Suggestions welcome.

## License

Copyright (c) 2018

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the ‘Software’), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED ‘AS IS’, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
