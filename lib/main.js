/** @babel */

export default {
  activate() {
    this.config = {
      showTests: {
        type: 'boolean',
        default: true
      },
      showPrivates: {
        type: 'boolean',
        default: true
      },
      showVariables: {
        type: 'boolean',
        default: true
      },
      showInterfaces: {
        type: 'boolean',
        default: true
      },
      viewMode: {
        type: 'string',
        default: 'file',
        description: "Display the whole package or just the current file",
        enum: ['package', 'file']
      },
      showTree: {
        type: 'boolean',
        default: true
      },
      showOnRightSide: {
        type: 'boolean',
        default: true
      },
      linkFile: {
        type: 'boolean',
        default: true,
        description: 'When disabled, the outline is not synchronized with the active file'
      },
      parserExecutable: {
        type: 'string',
        default: 'go-outline-parser'
      }
    };
    this.element = null;

    this.subscription = atom.commands.add('atom-workspace', {
      'go-outline:toggle': () => {
        this.togglePanel()
      }
    });
  },

  togglePanel() {
    if(this.view == null) {
      const Panel = require('./panel');
      this.view = new Panel();
    }
    this.view.toggle();
  },

  deactivate() {
    if(this.view !== null) {
      this.view.destroy();
      return this.view = null;
    }
    if(this.subscription !== null) {
      this.subscription.dispose();
      this.subscription = null;
    }
  }
};
