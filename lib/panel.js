'use babel'
/** @jsx etch.dom */

const etch = require('etch');

export default class Panel {
  // Required: Define an ordinary constructor to initialize your component.
  constructor (props, children) {
    // perform custom initialization here...
    // then call `etch.initialize`:
    etch.initialize(this)
    // use the component's associated DOM element however you wish...
    this.panel = atom.workspace.addRightPanel({
      item: this
    });




    this.reloadConfiguration();
    this.initializeButtons();
    // this.handleEvents();
  }

  reloadConfiguration(){
    this.showTests = atom.config.get('go-outline.showTests')
    this.showPrivate = atom.config.get('go-outline.showPrivates')
    this.showVariables = atom.config.get('go-outline.showVariables')
    this.showInterfaces = atom.config.get('go-outline.showInterfaces')
    this.showTree = atom.config.get('go-outline.showTree')
    this.linkFile = atom.config.get('go-outline.linkFile')
    this.viewMode = atom.config.get('go-outline.viewMode')
  }

  updateButtons(){
    this.setOptionActive(this.refs.btnShowTree, this.showTree);
    this.setButtonVisible(this.refs.btnCollapse, this.showTree);
    this.setButtonVisible(this.refs.btnExpand, this.showTree);
    this.setOptionActive(this.refs.btnShowPrivate, this.showPrivate);
    this.setOptionActive(this.refs.btnShowTests, this.showTests);
    this.setOptionActive(this.refs.btnShowVariables, this.showVariables);
    this.setOptionActive(this.refs.btnShowInterfaces, this.showInterfaces);
    this.setOptionActive(this.refs.btnLinkFile, this.linkFile);
  }

  initializeButtons(){

    this.updateViewTabs();
    this.updateButtons();
    // @observeConfigChanges()


    atom.tooltips.add(this.refs.bdgErrors, {title:this.parserStatusTooltip})

    @subscribeTo(@btnShowTree[0], { 'click': (e) =>
      @showTree = !@showTree
      @updateButtons()
      @updateSymbolList(@currentFolder())
    })

    @subscribeTo(@btnShowPrivate[0], { 'click': (e) =>
      @showPrivate = !@showPrivate
      @updateButtons()
      @updateSymbolList(@currentFolder())
    })

    @subscribeTo(@btnShowTests[0], { 'click': (e) =>
      @showTests = !@showTests
      @updateButtons()
      @updateSymbolList(@currentFolder())
    })

    @showMenu = false

    updateMenu = =>
      if @showMenu
        $(@menu[0]).removeClass('hidden')
      else
        $(@menu[0]).addClass('hidden')


    @subscribeTo(@btnOptions[0], {'click': (e) =>
      @showMenu = !@showMenu
      updateMenu()
    })

    @subscribeTo(@menu[0], {'mouseleave': (e) =>
      @showMenu = false
      updateMenu()
    })

    @subscribeTo(@btnShowVariables[0], { 'click': (e) =>
      @showVariables = !@showVariables
      @updateButtons()
      @updateSymbolList(@currentFolder())
    })

    @subscribeTo(@btnShowInterfaces[0], { 'click': (e) =>
      @showInterfaces = !@showInterfaces
      @updateButtons()
      @updateSymbolList(@currentFolder())
    })

    @subscribeTo(@tabFileView[0], { 'click': (e) =>
      @viewMode = 'file'
      @updateViewTabs()
      @updateSymbolList(@currentFolder())
    })

    @subscribeTo(@tabPackageView[0], { 'click': (e) =>
      @viewMode = 'package'
      @updateViewTabs()
      @updateSymbolList(@currentFolder())
    })

    @subscribeTo(@btnCollapse[0], {'click':(e) =>
      folder = @currentFolder()
      if folder?
        folder.collapsePackages()
        @updateSymbolList(folder)
    })

    @subscribeTo(@btnExpand[0], {'click':(e) =>
      folder = @currentFolder()
      if folder?
        folder.expandPackages()
        @updateSymbolList(folder)
    })

    @subscribeTo(@btnLinkFile[0], { 'click': (e) =>
      @linkFile = !@linkFile
      @updateButtons()
      if @linkFile
        @onActivePaneChange(atom.workspace.getActiveTextEditor())
    })

    @subscribeTo(@btnResetFilter[0], {'click': (e) =>@resetFilter()})


    @filterText = null;

    @searchBuffer().onDidChange(@applyFilter)

    editorView = atom.views.getView(@searchField)
    editorView.addEventListener 'keydown', (e) =>
      if e.keyCode == 13 # pressed enter
        hits = d3.select(@list[0]).select("li ol li").data()
        if hits.length>0 and hits[0]?
          @jumpToEntry(hits[0])
          @resetFilter()
      else if e.keyCode == 27 # pressed ESC
        @resetFilter()

    editorView.addEventListener 'focus', (e) =>
      @searchField.getModel().selectAll()
  }

  setButtonEnabled(element, enabled){
    if(enabled){
      $(element).addClass("selected")
    }else{
      $(element).removeClass("selected");
    }
  }

  setButtonVisible(element, enabled){
    if(enabled){
      $(element).removeClass("hidden");
    }else{
      $(element).addClass("hidden");
    }
  }


  updateViewTabs(){
    this.setButtonEnabled(this.refs.tabFileView, this.viewMode == 'file');
    this.setButtonEnabled(this.refs.tabPackageView, this.viewMode == 'package');
  }
  // Required: The `render` method returns a virtual DOM tree representing the
  // current state of the component. Etch will call `render` to build and update
  // the component's associated DOM element. Babel is instructed to call the
  // `etch.dom` helper in compiled JSX expressions by the `@jsx` pragma above.
  render () {
    return (
      <div className="go-outline-tree-resizer tool-panel"  data-show-on-right-side="true">
        <nav className="go-outline-navbar">
          <div className="go-outline-nav">
            <div className="go-outline-views">
              <button className="btn selected icon icon-file-directory inline-block-tight" ref="tabFileView">file</button>
              <button className="btn icon icon-file-text inline-block-tight" ref="tabPackageView">package</button>
            </div>
            <div className="go-outline-options">
              <button className="go-outline-btn-options btn icon icon-three-bars" title="Options" ref="btnOptions"></button>
              <div className="go-outline-options-popover select-list popover-list hidden" ref="menu">
                <ol className="list-group">
                  <li className="show variables" ref="btnShowVariables" />
                  <li className="show interfaces" ref="btnShowInterfaces" />
                  <li className="show private symbols" ref="btnShowPrivate" />
                  <li className="show test symbols" ref="btnShowTests" />
                  <li className="show as tree" ref="btnShowTree" />
                  <li className="Link go-outline with editor" ref="btnLinkFile" />
                </ol>
              </div>
            </div>
          </div>
          <div className="go-outline-search">
            <div className="icon icon-x hidden" ref="btnResetFilter" />
          </div>
          <div className="go-outline-status">
            <div className="icon icon-chevron-up" title="collapse all" ref="btnCollapse" />
            <div className="icon icon-chevron-down" title="expand all" ref="btnExpand" />
            <span ref="bdgErrors" />
          </div>
        </nav>
        <div className="go-outline-tree-scroller order--center" ref="scroller">
          <ol className="go-outline-tree full-menu list-tree has-collapsable-children focusable-panel" tabindex="-1" ref="list" />
        </div>
        <div className="go-outline-tree-resize-handle" ref="resizeHandle" />
      </div>
    );
  }

    // <subview 'searchField" new TextEditorView({mini: true, placeholderText:'filter'})

  // Required: Update the component with new properties and children.
  update (props, children) {
    // perform custom update logic here...
    // then call `etch.update`, which is async and returns a promise
    return etch.update(this)
  }

  // Optional: Destroy the component. Async/await syntax is pretty but optional.
  async destroy () {
    // call etch.destroy to remove the element and destroy child components
    await etch.destroy(this)
    // then perform custom teardown logic here...
  }

  toggle() {
    if (this.panel.isVisible()) {
      this.cancel();
    } else {
      this.populate();
      this.attach();
    }
  }

  async populate() {
  }

  attach() {
    // this.previouslyFocusedElement = document.activeElement;
    this.panel.show();
    // this.selectListView.reset();
    // this.selectListView.focus();
  }

  async cancel() {
  }
}
