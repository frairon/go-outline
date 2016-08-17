# [Go Outline](https://atom.io/packages/go-outline) [![Build Status](https://travis-ci.org/frairon/go-outline.svg?branch=master)](https://travis-ci.org/frairon/go-outline)
Simple outline for golang files.

![Go Outline Screenshot](https://github.com/frairon/go-outline/blob/master/resources/screenshot.png?raw=true)


It shows all following symbols contained in the whole package:
* global variables/constants
* global functions
* types
* functions with receivers

If a file changes, the tree will be updated.

You need `go-outline-parser` on your `$PATH`.

Having set `$GOPATH`, then this will do:
```
go get github.com/frairon/go-outline-parser
```

## Usage
* `go-outline:toggle` [ctrl-alt-o] -> activates the outline
* `go-outline:focus-filter` [ctrl-shift-E] -> jumps directly in the filter input

In the filter input:
* `ESC`  clears the filter
* `Enter` jumps to the first filtered item

## Contributing

Bug reports, Issues and PRs are always welcome!

## License

[MIT License](http://opensource.org/licenses/MIT) - see the [LICENSE](https://github.com/frairon/go-outline/blob/master/LICENSE) for more details.
