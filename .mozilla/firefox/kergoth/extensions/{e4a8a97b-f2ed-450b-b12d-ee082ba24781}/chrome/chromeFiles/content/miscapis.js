

function GM_ScriptStorage(script) {
  this.prefMan = new GM_PrefManager(["scriptvals.",
                                     script.namespace,
                                     "/",
                                     script.name,
                                     "."].join(""));
}

GM_ScriptStorage.prototype.setValue = function(name, val) {
  this.prefMan.setValue(name, val);
}

GM_ScriptStorage.prototype.getValue = function(name, defVal) {
  return this.prefMan.getValue(name, defVal);
}


function GM_ScriptLogger(script) {
  var namespace = script.namespace;
  
  if (namespace.substring(namespace.length - 1) != "/") {
    namespace += "/";
  }
  
  this.prefix = [namespace, script.name, ": "].join("");
}

GM_ScriptLogger.prototype.log = function(message) {
  GM_log(this.prefix + message, true);
}


// Based on Mark Pilgrim's GM_addGlobalStyle from 
// http://diveintogreasemonkey.org/patterns/add-css.html. Used by permission
// under GPL: http://diveintogreasemonkey.org/license/gpl.html
function GM_addStyle(doc, css) {
  var head, style;
  head = doc.getElementsByTagName('head')[0];
  if (!head) { return; }
  style = doc.createElement('style');
  style.type = 'text/css';
  style.innerHTML = css;
  head.appendChild(style);
}