Package = require '../lib/package'

describe "The package", ->
  it "should be initialized correctly", ->
    pkg = new Package("/tmp/")
    expect(pkg.type).toEqual("package")

  
