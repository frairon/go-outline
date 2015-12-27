Entry = require '../lib/entry'

describe "child_handling", ->
  it "checks hasChild", ->
    entry = new Entry("A")
    expect(entry.hasChild("B")).toBeFalsy()

    entry.addChild("B", {name:"B"})
    expect(entry.hasChild("B")).toBeTruthy()
  it "checks parent index", ->
    a = new Entry("A")
    b = new Entry("B")
    c = new Entry("C")
    a.addChild(b.name, b)
    a.addChild(c.name, c)
    expect(a.hasChild("B")).toBeTruthy()
    expect(a.hasChild("C")).toBeTruthy()

    expect(b.parentIndex()).toEqual(0)
    expect(c.parentIndex()).toEqual(1)

  it "checks getOrCreateChild", ->
    a = new Entry("A")

    expect(a.getOrCreateChild("B").parentIndex()).toEqual(0)
    expect(a.getOrCreateChild("C").parentIndex()).toEqual(1)
    expect(a.getOrCreateChild("B").parentIndex()).toEqual(0)

  it "does nothing", ->
    expect(true).toBeTruthy()
