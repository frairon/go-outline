const {
  BufferedProcess
} = require('atom');
const path = require('path');
const fs = require('fs');
const _ = require('underscore-plus');

const {
  watchPath
} = require('atom');

const Package = require('./package');

const {
  CompositeDisposable,
  Emitter
} = require('event-kit');


class Folder {
  static initClass() {
    // static variable makes sure we only show the warning
    // about using an old browser only once
    this.oldParserWarningShown = false;
    this.parserErrorShown = false;
  }

  constructor(path1, getParserExecutable) {
    this.showParserError = this.showParserError.bind(this);
    this.path = path1;
    this.getParserExecutable = getParserExecutable;
    this.packages = {};

    this.fileStats = {};

    // create watches for the directory
    // and rescan if anything changes.
    this.watch();
  }

  setUpdateCallback(updateCallback) {
    this.updateCallback = updateCallback;
  }

  setParserStatusCallback(parserStatusCallback) {
    this.parserStatusCallback = parserStatusCallback;
  }

  getPackages() {
    return _.values(this.packages);
  }

  watch() {
    if(this.watchSubscription === null) {
      return;
    }

    this.watchSubscription = watchPath(this.path, {}, events => {
      var changed = false;
      for(const event of events) {
        if(['modified', 'created', 'deleted'].indexOf(event.action) > -1){
          changed=true;
          break;
        }
      }
      if(changed) {
        return this.fullReparse();
      }
    });
  }

  fullReparse() {
    let names;
    try {
      names = fs.readdirSync(this.path);
    } catch (error) {
      names = [];
    }

    // ignore non-go-files
    names = _.filter(names, x => x.endsWith('.go'));

    const files = [];
    const promises = [];
    this.parserStatusCallback(names, [], []);

    const doneFiles = new Set();
    const failedFiles = new Set();
    for(let name of Array.from(names)) {
      var result = this.parseFile(name);

      if(result != null) {
        const f = n => {
          result.then(code => {
            if(code === 0) {
              doneFiles.add(n);
            } else {
              failedFiles.add(n);
            }
            return this.parserStatusCallback(names, doneFiles, failedFiles);
          });
          return promises.push(result);
        };
        f(name);
      } else {
        // if the result was no promise, the file was ignored
        // meaning it was not updated or different type, so we count a success
        doneFiles.add(name);
      }
    }

    return Promise.all(promises).then(() => {
      this.parserStatusCallback(names, doneFiles, failedFiles);
      for(let pkgName in this.packages) {
        const pkg = this.packages[pkgName];
        pkg.sortChildren();
      }
      return this.updateCallback(this);
    });
  }

  parseFile(name) {

    // check stats of file, load symlinks etc.
    const fullPath = path.join(this.path, name);
    let stat = fs.statSync(fullPath);
    if(typeof stat.isSymbolicLink === 'function' ? stat.isSymbolicLink() : undefined) {
      stat = fs.lstatSync(fullPath);
    }
    if((typeof stat.isDirectory === 'function' ? stat.isDirectory() : undefined) || !(typeof stat.isFile === 'function' ? stat.isFile() : undefined)) {
      return null;
    }

    // file stats exist, and file is not newer -> has not changed
    if(fullPath in this.fileStats && (this.fileStats[fullPath].mtime.getTime() >= stat.mtime.getTime())) {
      return null;
    }

    this.fileStats[fullPath] = stat;

    return this.reparseFile(fullPath);
  }

  reparseFile(filePath) {
    const out = [];
    const parserExecutable = this.getParserExecutable();
    const promise = new Promise((resolve, reject) => {
      const proc = new BufferedProcess({
        command: parserExecutable,
        args: ['-f', filePath],
        stdout: data => {
          return out.push(data);
        },
        exit: code => {
          return resolve(code);
        }
      });

      proc.onWillThrowError(c => {
        resolve(c);
        this.showParserError(c.error);
        return c.handle();
      });

      return proc;
    }).then(code => {
      if(code !== 0) {
        return code;
      }

      try {
        return this.updateFolder(out.join("\n"));

      } catch (error) {
        return console.log("Error creating outline from parser-output", error, out);
      } finally {
        return code;
      }
    });

    return promise;
  }

  showParserError(error) {
    if(Folder.parserErrorShown) {
      return;
    }

    atom.notifications.addError("Error executing go-outline-parser", {
      detail: error + "\nExecutable not found?",
      dismissable: true,
    });
    return Folder.parserErrorShown = true;
  }

  updateFolder(parserOutput) {
    const parsed = JSON.parse(parserOutput);

    // maybe the file does not have any entries? Ignore it
    if((parsed.Entries == null)) {
      return;
    }

    if(!(parsed.Entries instanceof Array)) {

      // for the first time this happens per session
      // show a warning to update go-outline-parser
      if(!Folder.oldParserWarningShown) {
        atom.notifications.addInfo("Update go-outline-parser", {
          detail: "It seems like you're using an outdated version of go-outline.\nUpdate to get more features/bugfixes.",
          dismissable: true
        });
        Folder.oldParserWarningShown = true;
      }

      // convert it to a list anyway to be backwards compatible
      parsed.Entries = _.values(parsed.Entries);
    }
    const file = parsed.Filename;
    const packageName = parsed.Packagename;

    const pkg = this.updatePackage(file, packageName);

    return pkg.updateChildrenForFile(parsed.Entries, file);
  }

  updatePackage(file, packageName) {

    if(!(packageName in this.packages)) {
      this.packages[packageName] = new Package(packageName);
    }

    const pkg = this.packages[packageName];

    // add the parsed file to its package and remove it from all the other
    // packages. This covers the case when the package has been renamed.
    pkg.addFile(file);
    for(var name in this.packages) {
      const p = this.packages[name];
      if(p === pkg) {
        continue;
      }

      p.removeFile(file);
    }

    // remove all packages that don't have any files
    for(name of Array.from(_.keys(this.packages))) {
      if(!this.packages[name].hasFiles()) {
        delete this.packages[name];
      }
    }

    return pkg;
  }

  expandPackages() {
    return Array.from(this.getPackages()).map((pkg) =>
      pkg.expand());
  }

  collapsePackages() {
    return Array.from(this.getPackages()).map((pkg) =>
      pkg.collapse());
  }

  destroy() {
    this.unwatch;
    return this.emitter.emit("did-destroy");
  }

  unwatch() {
    if(this.watchSubscription != null) {
      this.watchSubscription.close();
      return this.watchSubscription = null;
    }
  }
};
Folder.initClass();


module.exports = Folder;
