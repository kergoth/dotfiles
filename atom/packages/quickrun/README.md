# Quickrun package

Execute whole/part of editing file.
Inspired by [vim-quickrun](https://github.com/thinca/vim-quickrun).

## Installation

Find from Settings pane or run `apm install quickrun`.

## Usage

Write code and `Ctrl-Cmd-r` then show result on another pane.

![usage](http://s1.directupload.net/images/140414/iavncl4p.gif)

## Commands

| name | description | key binding | selector |
|:----:|:-----------:|:-----------:|:--------:|
| quickrun:execute | execute whole of editing file | ctrl-cmd-r |.editor:not(.mini)|
| quickrun:select | execute selected text | -|-|

## Supported Languages

* Ruby
* Perl
* Python

## TODO

* Configuration, especially custom Languages.
* More flexible Language spec format. (file name, and so on).
* Test, test, test!

## Contributing
1. Fork it ( http://github.com/Sixeight/atom-quickrun/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. nPush to the branch (git push origin my-new-feature)
5. Create new Pull Request
