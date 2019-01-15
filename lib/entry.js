const path = require('path');
const _ = require('underscore-plus');
class Entry {
  constructor(name) {
    this.filterChildren = this.filterChildren.bind(this);
    this.name = name;
    this.children = [];

    this.type = null;
    this.fileDef = null;
    this.fileLine = -1;
    this.fileColumn = -1;
    this.isPublic = false;

    this.expanded = true;

    this.parent = null;
  }


  getNameAsParent() {
    return this.name;
  }

  getIdentifier() {

    let identifier = this.name;
    const parentName = this.parent != null ? this.parent.getNameAsParent() : undefined;
    if((parentName != null) && (this.parent.type !== 'package')) {
      identifier = parentName + "::" + identifier;
    }

    return identifier;
  }


  getTitle() {
    if((this.fileDef != null) && (this.fileLine != null)) {
      path.basename(this.fileDef) + ":" + this.fileLine;
    }

    if(this.isImplicitParent()) {
      return this.name + " (definition not found)";
    } else {
      return this.name;
    }
  }

  updateChild(child) {

    // if entry has a receiver
    if((child != null ? child.Receiver : undefined) != null) {
      const receiver = this.getOrCreateChild(child.Receiver);
      return receiver.getOrCreateChild(child.Name).updateEntry(child);
    } else {
      return this.getOrCreateChild(child.Name).updateEntry(child);
    }
  }

  getOrCreateChild(name) {
    let child = this.getChild(name);
    if((child == null)) {
      child = this.addChild(name, new Entry(name));
    }

    return child;
  }

  sorter(children) {
    const sortedChildren = children.slice(0);

    sortedChildren.sort(function(l, r) {
      const typeDiff = l.getTypeRank() - r.getTypeRank();
      if(typeDiff !== 0) {
        return typeDiff;
      }

      return l.name.localeCompare(r.name);
    });

    return sortedChildren;
  }

  isTestEntry() {
    const suffix = 'test.go';
    return (this.fileDef != null) && (this.fileDef.length !== suffix.length) && this.fileDef.endsWith('test.go');
  }

  sortChildren() {
    this.children = this.sorter(this.children);

    return _.each(this.children, c => c.sortChildren(true));
  }


  // returns all children recursively.
  getChildrenFlat() {
    const flatChildren = _.flatten([this.children, _.map(this.children, c => c.getChildrenFlat())]);
    return this.sorter(flatChildren);
  }

  hasChild(name) {
    return _.some(this.children, child => child.name === name);
  }

  getChild(name) {
    return _.find(this.children, child => child.name === name);
  }

  addChild(name, child) {
    this.children.push(child);
    child.parent = this;

    return child;
  }

  hasChildren() {
    return this.children.length > 0;
  }

  removeChild(name) {
    return this.children = _.filter(this.children, c => c.name !== name);
  }

  expandAll(expanded) {
    this.expanded = expanded;
    return _.each(this.children, c => c.expandAll(expanded));
  }

  updateEntry(data) {
    if(data.Name != null) {
      this.name = data.Name;
    }
    if(data.FileName != null) {
      this.fileDef = data.FileName;
    }
    if(data.Line != null) {
      this.fileLine = data.Line;
    }
    if(data.Column != null) {
      this.fileColumn = data.Column;
    }
    if(data.Public != null) {
      this.isPublic = data.Public;
    }
    if(data.Elemtype != null) {
      return this.type = data.Elemtype;
    }
  }

  getTypeRank() {
    switch (this.type) {
      case "variable":
        return 0;
      case "type":
        return 1;
      case "field":
        return 2;
      case "func":
        return 3;
    }
  }

  usageFiles() {
    return _.pluck(this.children, "fileDef").length;
  }

  isUsedInFile(file) {
    return _.some(this.children, c => c.fileDef === file);
  }

  removeRemainingChildren(fileName, existingChildren) {
    let myChildFilter;
    let i = 0;

    // filter the existing children for the children that are assigned to me.
    // I don't have a parent, that means I'm a package
    if((this.parent == null)) {
      // so my children don't have a receiver
      myChildFilter = c => (c.Receiver == null) && (c.FileName === fileName);
    } else {
      // otherwise I must be their receiver
      myChildFilter = c => (c.Receiver === this.name) && (c.FileName === fileName);
    }

    const myChildren = _.pluck(_.filter(existingChildren, myChildFilter), 'Name');

    return (() => {
      const result = [];
      while(i < this.children.length) {
        const child = this.children[i];
        child.removeRemainingChildren(fileName, existingChildren);

        // the child was defined in this file, but is not anymore and doesn't have any children.
        if((child.fileDef === fileName) && !Array.from(myChildren).includes(child.name)) {
          if(!child.hasChildren()) {
            this.removeChild(child.name);
            continue;
          } else { // it still has children, so let's remove the definition
            // since we couldn't delete it we'll remove the fileDef
            child.fileDef = null;
          }
        }

        // in case it was an implicit parent (e.g. after renaming), but now all the children are gone,
        // finally remove it now too.
        if((child.fileDef == null) && (child.children.length === 0)) {
          this.removeChild(child.name);
          continue;
        }

        result.push(i += 1);
      }
      return result;
    })();
  }

  isImplicitParent() {
    return this.hasChildren() && (this.fileDef == null);
  }


  filterChildren(path, options) {
    // params:
    //  path: file path of active file
    //  options: <object>
    //     text: filter text
    //     flat true|false -> return all children flattened
    //     variables: show variables
    //     tests: show tests
    //     interfaces: show interfaces
    //     viewMode: package|file
    //     private: show unexported symbols
    let children;
    if((options != null ? options.flat : undefined)) {
      children = this.getChildrenFlat();
    } else {
      ({
        children
      } = this);
    }

    return _.filter(children, c => {
      let searcher = c => true;

      if(options != null ? options.text : undefined) {
        const needles = options.text.toLowerCase().split(" ");
        searcher = function(c) {
          const lowName = c.name.toLowerCase();
          return _.every(needles, n => lowName.indexOf(n) > -1);
        };
      }
      return (
        ((options != null ? options.variables : undefined) || (c.type !== "variable")) &&
        ((options != null ? options.tests : undefined) || (c.type === "package") || !c.isTestEntry()) &&
        ((options != null ? options.interfaces : undefined) || (c.type !== "interface")) &&
        (((options != null ? options.viewMode : undefined) === "package") || (c.fileDef === path) || c.isUsedInFile(path)) &&
        ((options != null ? options.private : undefined) || c.isPublic) &&
        (!(options != null ? options.text : undefined) || searcher(c))
      );
    });
  }
}
module.exports = Entry;
