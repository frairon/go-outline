Entry = require '../lib/entry'
Package = require '../lib/package'
GoOutlineView = require '../lib/go-outline-view'

describe "Entry", ->
  it "should update correctly", ->
    entry = new Entry("entry")
    expect(entry.name).toEqual("entry")

    entry.updateEntry({Elemtype:"type"})
    expect(entry.type).toEqual("type")
    expect(entry.fileLine).toEqual(-1)

    entry.updateEntry({Line:23})
    expect(entry.type).toEqual("type")
    expect(entry.fileLine).toEqual(23)

  it "checks hasChild", ->
    entry = new Entry("A")
    expect(entry.hasChild("B")).toBeFalsy()

    entry.addChild("B", {name:"B"})
    expect(entry.hasChild("B")).toBeTruthy()

  it "removes parents when there's no child anymore.", ->
    p = new Package("package")

    A =
      Name: "A"
      FileName: "fileA"
      Elemtype: "type"

    B =
      Name: "B"
      Receiver: "A"
      FileName: "fileA"
      Elemtype: "function"


    p.updateChildrenForFile([A, B], "fileA")

    expect(p.hasChild("A")).toBeTruthy()
    expect(p.children[0].hasChild("B")).toBeTruthy()

    A.Name = "newA"
    p.updateChildrenForFile([A, B], "fileA")

    expect(p.hasChild("A")).toBeTruthy()
    expect(p.getChild("A").isImplicitParent()).toBeTruthy()
    expect(p.getChild("newA").children.length).toEqual(0)
    expect(p.getChild("A").children.length).toEqual(1)

    B.Receiver="newA"
    p.updateChildrenForFile([A, B], "fileA")
    expect(p.getChild("newA").children.length).toEqual(1)
    expect(p.hasChild("A")).toBeFalsy()

  it "should filter empty", ->
    pkg = new Package("test")
    expect(pkg.filterChildren("file", {})).toHaveLength(0)

  it "should hide privates", ->

    pkg = new Package("test")
    pkg.updateChildrenForFile([{
      Name: "test",
    }], "file")

    expect(pkg.filterChildren("file", {
      private:false,
      })).toHaveLength(0)

    expect(pkg.filterChildren("file", {})).toHaveLength(0)
    expect(pkg.filterChildren("file", {
      private:true,
      })).toHaveLength(1)
  it "should show from implicit symbols from other files", ->
    pkg = new Package("test")
    pkg.updateChildrenForFile([{
      Name: "Test",
    }], "file")

    pkg.updateChildrenForFile([{
      Name: "children",
      Receiver: "Test",
    }], "otherfile")

    expect(pkg.filterChildren("file", {
      private:true,
      })).toHaveLength(1)

    expect(pkg.filterChildren("otherfile", {
      private:true,
      })).toHaveLength(1)

  it "should hide and show test-files", ->
    pkg = new Package("abc")
    pkg.updateChildrenForFile([{
      Name: "TestSomething",
      Type: "function",
      Public: true,
    }], "mod_test.go")

    v = new GoOutlineView()

    expect(pkg.filterChildren("mod_test.go", v.createFilterOptions()))
      .toHaveLength(0)

    # modify the options to show the tests. Now the tests should be visible
    v.showTests=true

    expect(pkg.filterChildren("mod_test.go", v.createFilterOptions()))
      .toHaveLength(1)
