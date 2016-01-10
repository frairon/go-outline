Entry = require '../lib/entry'

describe "Entry", ->
  it "should update correctly", ->
    entry = new Entry("entry")
    expect(entry.name).toEqual("entry")

    entry.updateEntry({ElemType:"type"})
    expect(entry.type).toEqual("type")
    expect(entry.fileLine).toEqual(-1)

    entry.updateEntry({Line:23})
    expect(entry.type).toEqual("type")
    expect(entry.fileLine).toEqual(23)
