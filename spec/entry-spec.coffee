Entry = require '../lib/entry'
Package = require '../lib/package'

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
