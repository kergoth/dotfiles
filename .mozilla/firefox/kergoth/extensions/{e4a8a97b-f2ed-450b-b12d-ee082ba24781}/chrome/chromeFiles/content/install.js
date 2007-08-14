var GMInstall = {
  init: function() {
    var ioservice = Components.classes["@mozilla.org/network/io-service;1"]
                              .getService(Components.interfaces.nsIIOService);

    this.htmlNs_ = "http://www.w3.org/1999/xhtml";

    this.scriptDownloader_ = window.arguments[0];
    this.script_ = this.scriptDownloader_.script;

    this.setupIncludes("includes", "includes-desc", this.script_.includes);
    this.setupIncludes("excludes", "excludes-desc", this.script_.excludes);

    this.dialog_ = document.documentElement;
    this.extraButton_ = this.dialog_.getButton("extra1");
    this.extraButton_.setAttribute("type", "checkbox");

    this.acceptButton_ = this.dialog_.getButton("accept");
    this.acceptButton_.baseLabel = this.acceptButton_.label;

    this.timer_ = null;
    this.seconds_ = 0;
    this.startTimer();

    this.bundle = document.getElementById("gm-browser-bundle");
    this.greetz = new Array();
    for(var i = 0; i < 6; i++){
      this.greetz.push(this.bundle.getString('greetz.' + i));
    }

    var pick = Math.round(Math.random() * (this.greetz.length - 1));
    var heading = document.getElementById("heading");
    heading.appendChild(document.createElementNS(this.htmlNs_, "strong"));
    heading.firstChild.appendChild(document.createTextNode(this.greetz[pick]));
    heading.appendChild(document.createTextNode(" " + this.bundle.getString("greeting.msg")));

    var desc = document.getElementById("scriptDescription");
    desc.appendChild(document.createElementNS(this.htmlNs_, "strong"));
    desc.firstChild.appendChild(document.createTextNode(this.script_.name));
    desc.appendChild(document.createElementNS(this.htmlNs_, "br"));
    desc.appendChild(document.createTextNode(this.script_.description));
  },

  onFocus: function(e) {
    this.startTimer();
  },

  onBlur: function(e) {
    this.stopTimer();
  },

  startTimer: function() {
    this.seconds_ = 4;
    this.updateLabel();

    if (this.timer_) {
      window.clearInterval(this.timer_);
    }

    this.timer_ = window.setInterval(function() { GMInstall.onInterval() }, 500);
  },

  onInterval: function() {
    this.seconds_--;
    this.updateLabel();

    if (this.seconds_ == 0) {
      this.timer_ = window.clearInterval(this.timer_);
    }
  },

  stopTimer: function() {
    this.seconds_ = 5;
    this.timer_ = window.clearInterval(this.timer_);
    this.updateLabel();
  },

  updateLabel: function() {
    if (this.seconds_ > 0) {
      this.acceptButton_.focus();
      this.acceptButton_.disabled = true;
      this.acceptButton_.label = this.acceptButton_.baseLabel + " (" + this.seconds_ + ")";
    } else {
      this.acceptButton_.disabled = false;
      this.acceptButton_.label = this.acceptButton_.baseLabel;
    }
  },

  setupIncludes: function(box, desc, includes) {
    if (includes.length > 0) {
      desc = document.getElementById(desc);
      document.getElementById(box).style.display = "";

      for (var i = 0; i < includes.length; i++) {
	desc.appendChild(document.createTextNode(includes[i]));
	desc.appendChild(document.createElementNS(this.htmlNs_, "br"));
      }

      desc.removeChild(desc.lastChild);
    }
  },

  onOK: function() {
    var config = new Config();
    config.load();
    config.install(this.script_);
    window.opener.GM_BrowserUI.showHorrayMessage(this.script_.name);
    window.setTimeout("window.close()", 0);
  },

  onCancel: function(){
    window.close();
  },

  onShowSource: function() {
    this.scriptDownloader_.showScriptView();
    window.setTimeout("window.close()", 0);
  },
};
