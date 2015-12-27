helpers = require '../lib/helpers'

describe "HelpersTest", ->
  it "basename test", ->
    expect(helpers.basename("/file.d")).toEqual("file.d")
    expect(helpers.basename("file.d")).toEqual("file.d")
    expect(helpers.basename("/path-only/")).toEqual("")


  it "dirname test", ->
    expect(helpers.dirname("/file.d")).toEqual("/")
    expect(helpers.dirname("file.d")).toEqual("")
    expect(helpers.dirname("/path-only/")).toEqual("/path-only/")
