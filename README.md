# Go Outline
Simple outline for golang files.

![Go Outline Screenshot](https://github.com/frairon/go-outline/blob/master/resources/screenshot.png?raw=true)


It shows the symbols of the whole package:
* global variables/constants
* global functions
* types
* functions with receivers

If a file changes, the tree will be updated.

You need `go-outline-parser` on your `$PATH`!!

Having set `$GOPATH`, this should do:
```
go get github.com/frairon/go-outline-parser
```

## Usage
* `go-outline:toggle` [ctrl-alt-o] -> activates the outline
* `go-outline:focus-filter` [ctrl-shift-E] -> activates the filter input

In the filter:
* `ESC`  resets the filter
* `Enter` jumps to the first filtered item

## Contributing

Bug reports, Issues and PRs are always welcome!

## License

[MIT License](http://opensource.org/licenses/MIT) - see the [LICENSE](https://github.com/frairon/go-outline/blob/master/LICENSE) for more details.
