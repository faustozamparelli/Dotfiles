'use strict';
const path = require('node:path');
const os = require('node:os');

function localPdfPath(uri, home = os.homedir()) {
  if (uri.scheme === 'file') return uri.fsPath;
  if (uri.scheme !== 'vscode-remote' || !uri.authority.startsWith('attached-container+')) {
    throw new Error('This remote PDF has no local path. Download it first to open it in Preview.');
  }
  const encoded = uri.authority.slice('attached-container+'.length).split('@')[0];
  const target = JSON.parse(Buffer.from(encoded, 'hex').toString('utf8'));
  if (!['amsc', '/amsc'].includes(target.containerName) || !uri.path.startsWith('/shared-folder/')) {
    throw new Error('Only PDFs in the AMSC shared folder have a known local path.');
  }
  const root = path.join(home, 'shared-folder');
  const local = path.resolve(root, uri.path.slice('/shared-folder/'.length));
  if (!local.startsWith(root + path.sep)) throw new Error('Invalid shared-folder PDF path.');
  return local;
}

function activate(context) {
  const vscode = require('vscode');
  context.subscriptions.push(vscode.window.registerCustomEditorProvider('fausto.previewPdf', {
    openCustomDocument(uri) { return { uri, dispose() {} }; },
    async resolveCustomEditor(document, panel) {
      panel.webview.html = '<meta http-equiv="Content-Security-Policy" content="default-src \'none\'"><p>Opening PDF in your default app…</p>';
      try {
        const uri = vscode.Uri.file(localPdfPath(document.uri));
        if (!await vscode.env.openExternal(uri)) throw new Error('The system could not open this PDF.');
        // Let VS Code finish resolving its custom editor before closing it.
        // Dispose only this panel, never an unrelated active tab.
        setTimeout(() => panel.dispose(), 250);
      } catch (error) {
        panel.webview.html = '<meta http-equiv="Content-Security-Policy" content="default-src \'none\'"><p>Unable to open this PDF externally. See the notification.</p>';
        vscode.window.showErrorMessage(String(error.message || error));
      }
    }
  }, { supportsMultipleEditorsPerDocument: false }));
}

module.exports = { activate, localPdfPath };
