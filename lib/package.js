const Entry = require('./entry');
const _ = require('underscore-plus');

class Package extends Entry {
  constructor(name){
    super(name);
    this.updateEntry({Elemtype:"package"});

    this.containingFiles = new Set();
  }

  addFile(file) {
    return this.containingFiles.add(file);
  }

  removeFile(file) {
    return this.containingFiles.delete(file);
  }

  hasFiles() {
    return this.containingFiles.size > 0;
  }

  collapse() {
    // collapse all children, let me expanded
    this.expandAll(false);
    return this.expanded = true;
  }

  expand() {
    return this.expandAll(true);
  }

  updateChildrenForFile(children, file) {

    for (let symbol of Array.from(children)) {
      symbol.FileName = file;
      this.updateChild(symbol);
    }

    return this.removeRemainingChildren(file, children);
  }
};

module.exports = Package;
