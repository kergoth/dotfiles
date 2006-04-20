Viamatic.Xpose.Colors = new Object();
Viamatic.Debug = new Object();
Viamatic.Xpose.Visible = false;
Viamatic.Xpose.CurrentWindow = null;
Viamatic.Xpose.UpdateTimer = null;
Viamatic.Xpose.LastTab = new Object();
Viamatic.Xpose.LastTab.href = null;
Viamatic.Xpose.LastTab.title = null;
Viamatic.Xpose.HasFocus		 = true;

/* Run the first time settings if it is the first time */
if(Viamatic.Xpose.getUnicodePref("version") != Viamatic.Xpose.Version) Viamatic.Xpose.Settings.FirstTime();

Viamatic.Xpose.OnLoad = function() 
{
    var foXposeShortCut = document.getElementById("foXpose-key");
    foXposeShortCut.setAttribute("keycode", Viamatic.Xpose.getUnicodePref("shortcutkey"));
    foXposeShortCut.setAttribute("modifiers", Viamatic.Xpose.getUnicodePref("shortcutmodifier"));
 
    if(Viamatic.Xpose.getUnicodePref("showicon") != "true") {
        var xpose_statusbar_panel = document.getElementById("xpose_statusbar_panel");
        xpose_statusbar_panel.style.display = "none";
    }    
}

window.addEventListener('load', Viamatic.Xpose.OnLoad, false); 

Viamatic.Xpose.Colors.BackgroundColor = "white";
Viamatic.Xpose.Colors.TitleBackground = "white";
Viamatic.Xpose.Colors.TitleColor      = "black";
Viamatic.Xpose.Colors.SelectedBorder  = "black";
Viamatic.Xpose.Colors.NormalBorder    = "#CCCCCC";
Viamatic.Xpose.Colors.KeyBackColor    = "#FFFFCC";

Viamatic.Xpose.Colors.Default = function()
{
    Viamatic.Xpose.Colors.BackgroundColor = "white";
    Viamatic.Xpose.Colors.TitleBackground = "white";
    Viamatic.Xpose.Colors.TitleColor      = "black";
    Viamatic.Xpose.Colors.SelectedBorder  = "black";
    Viamatic.Xpose.Colors.NormalBorder    = "#CCCCCC";
    Viamatic.Xpose.Colors.KeyBackColor    = "#FFFFCC";
}

Viamatic.Xpose.Colors.Black = function()
{
    Viamatic.Xpose.Colors.BackgroundColor = "black";
    Viamatic.Xpose.Colors.TitleBackground = "grey";
    Viamatic.Xpose.Colors.TitleColor      = "white";
    Viamatic.Xpose.Colors.SelectedBorder  = "white";
    Viamatic.Xpose.Colors.NormalBorder    = "grey";
    Viamatic.Xpose.Colors.KeyBackColor    = "#F0F0F0";
}

Viamatic.Xpose.Colors.UserDefined = function()
{

}

Viamatic.Debug.writeln = function (aMessage) 
{
  var consoleService = Components.classes["@mozilla.org/consoleservice;1"].getService(Components.interfaces.nsIConsoleService);
  consoleService.logStringMessage(aMessage);
}

Viamatic.Xpose.Unload = function()
{	
    Viamatic.Xpose.RemoveWindowHandler();
	this.removeEventListener("blur", Viamatic.Xpose.LostFocus,false);
	Viamatic.Xpose.WindowVisible(false);		
}

Viamatic.Xpose.LostFocus = function()
{   
    Viamatic.Xpose.RemoveWindowHandler();
    this.removeEventListener("blur", Viamatic.Xpose.LostFocus,false);
	
    
    if(Viamatic.Xpose.getUnicodePref("showtab") == "false") { 
		/*	
		Viamatic.Xpose.ShowPreviousTab(); 
		this.close();        
	    Viamatic.Xpose.WindowVisible(false);    
		*/
		Viamatic.Xpose.HasFocus	= false;
		this.addEventListener("focus", Viamatic.Xpose.GotFocus,false);
		Viamatic.Xpose.Update();
    } else {
        this.addEventListener("focus", Viamatic.Xpose.GotFocus,false);
	    window.clearInterval(Viamatic.Xpose.UpdateTimer);
	    Viamatic.Xpose.UpdateTimer = null;
	 //   Viamatic.Debug.writeln("Lost focus");
	    Viamatic.Xpose.RemoveWindowHandler();
	}
}


Viamatic.Xpose.GotFocus = function()
{
//	Viamatic.Debug.writeln("Got focus");
	Viamatic.Xpose.HasFocus	= true;
	var myBrowser = getBrowser();
	var tabs = myBrowser.tabContainer;
	if(tabs.childNodes.length == 2 ) {
		Viamatic.Xpose.RemoveWindowHandler();
		this.close();
		return; // Only two tabs
	}
	
	if(tabs.childNodes.length == 1 ) {
		Viamatic.Xpose.RemoveWindowHandler();
		this.location.href="about:blank";
		return; // Only two tabs
	}
	
	Viamatic.Xpose.RePaint(this);
	this.removeEventListener("focus", Viamatic.Xpose.GotFocus,false);
	
	//this.addEventListener("blur", Viamatic.Xpose.LostFocus,false);
	/*
	Viamatic.Xpose.LastTab.href = null;
	Viamatic.Xpose.LastTab.title = null;
	*/
}

Viamatic.Xpose.KeyPress = function(e)
{
	var chr = String.fromCharCode(e.keyCode);
	if(Viamatic.Tabs[Viamatic.Xpose.GetIDFromKeyCode(e.keyCode)]) {
	    document.getElementById("content").selectedTab = Viamatic.Tabs[Viamatic.Xpose.GetIDFromKeyCode(e.keyCode)];
	    Viamatic.Xpose.WindowVisible(false);	
	 }
}

Viamatic.Xpose.CloseWindow = function()
{
    Viamatic.Xpose.CloseTab(this);
}

Viamatic.Xpose.CloseTab = function(tab) 
{
    Viamatic.Xpose.RemoveWindowHandler();
	Viamatic.Browsers[tab.id].contentWindow.close();
	Viamatic.Browsers[tab.id] = null;
	Viamatic.Tabs[tab.id] = null;
	
	if(getBrowser().tabContainer.childNodes.length == 2 ) {
		Viamatic.Xpose.CurrentWindow.close();
		return;
	}
	
	tab.parentNode.parentNode.removeChild(tab.parentNode);
	Viamatic.Xpose.SetWindowHandler();
}

Viamatic.Xpose.OnClick_Canvas = function(e) 
{
    if(e.button == 1) {
        Viamatic.Xpose.CloseTab(this);
        e.stopPropagation();
    }
}

Viamatic.Xpose.ChangeFocus = function()
{
	document.getElementById("content").selectedTab = Viamatic.Tabs[this.id];
	Viamatic.Xpose.WindowVisible(false);
}

Viamatic.Xpose.MouseOver = function()
{
	this.style.border = "thin solid";	
	this.style.borderColor = Viamatic.Xpose.Colors.NormalBorder;
}

Viamatic.Xpose.MouseOut = function()
{
	this.style.border = "thin solid";
	this.style.borderColor = Viamatic.Xpose.Colors.SelectedBorder;  
}

Viamatic.Xpose.CloseMouseOver = function()
{
	this.style.MozOpacity = .2;  	
}

Viamatic.Xpose.CloseMouseOut = function()
{
	this.style.MozOpacity = 1; 	  	
}

Viamatic.Xpose.GetDigit = function()
{
    if(Viamatic.Counter > -1 && Viamatic.Counter <9) return (Viamatic.Counter + 1);
    return String.fromCharCode(65 + Viamatic.Counter - 9);
}

Viamatic.Xpose.GetIDFromKeyCode = function(KeyCode)
{
    if(KeyCode >= 49 && KeyCode <= 57) return KeyCode - 49;
    return (KeyCode - 65 + 9);

}

Viamatic.Xpose.PictureViewer = function(doc, w , h)
{
	var outerDiv = doc.createElement("div");
	var textDiv = doc.createElement("div");
	var closeDiv = doc.createElement("img");
	
	var keyCodeSpan = doc.createElement("div");
	keyCodeSpan.style.border = "1px solid";
	keyCodeSpan.style.borderColor = Viamatic.Xpose.Colors.NormalBorder;
	keyCodeSpan.style.padding = "1px 3px 1px 3px";
	keyCodeSpan.style.margin  = "1px 1px";
	keyCodeSpan.style.width = "6px";
	keyCodeSpan.style.backgroundColor =  Viamatic.Xpose.Colors.KeyBackColor;
	keyCodeSpan.innerHTML = Viamatic.Xpose.GetDigit();
	keyCodeSpan.style.color = "black";
	keyCodeSpan.style.cssFloat = "left";
	keyCodeSpan.id = "VSI_KeyCode_" + Viamatic.Xpose.GetDigit();
	
	outerDiv.id = "VSIOD" + Viamatic.Counter;
	
	outerDiv.className = "textOverflow";
	
	closeDiv.id = Viamatic.Counter;
		
	closeDiv.height = 16;
	closeDiv.width = 16;
	closeDiv.src = "";
	closeDiv.style.cssFloat = "right";
	closeDiv.style.margin = "1px 0px 0 0px";
	closeDiv.src = "chrome://xpose/skin/close.png"
	closeDiv.style.MozOpacity = 20/100;
	
	closeDiv.style.padding = "1px 1px 1px";
	outerDiv.style.cssFloat="left";
	outerDiv.style.width = w + "px";
	outerDiv.style.border = "thin solid";
	outerDiv.style.borderColor =  Viamatic.Xpose.Colors.NormalBorder;	  
	outerDiv.style.margin = "1px";
	outerDiv.id = "testID";
	outerDiv.style.fontFamily = "Arial, Helvetica, sans-serif";
	outerDiv.style.fontSize = "11px";
	//textDiv.style.float="left";
	
	outerDiv.appendChild(closeDiv);	
	
	textDiv.style.paddingTop = "2px";
	textDiv.style.paddingLeft = "2px";
	textDiv.style.whiteSpace = "nowrap";
	textDiv.style.overflow = "hidden";
	outerDiv.style.overflow = "hidden";
	
	if(Viamatic.Xpose.getUnicodePref("showkeyboardtitle") == "true") outerDiv.appendChild(keyCodeSpan);
	outerDiv.appendChild(textDiv);
	
	outerDiv.style.color = Viamatic.Xpose.Colors.TitleColor;
	outerDiv.style.backgroundColor = Viamatic.Xpose.Colors.TitleBackground;

	var cnv = doc.createElement('canvas');
	this.canvas = cnv;
	this.textPanel = textDiv;
	cnv.width = w;
	cnv.height = h;
	outerDiv.appendChild(cnv);
	doc.body.appendChild(outerDiv);
	//return cnv;
	cnv.id = Viamatic.Counter;
	
	closeDiv.addEventListener("click", Viamatic.Xpose.CloseWindow, true);
	
	closeDiv.addEventListener("mouseover", Viamatic.Xpose.CloseMouseOut, true);
	closeDiv.addEventListener("mouseout", Viamatic.Xpose.CloseMouseOver, true);
	
	outerDiv.addEventListener("mouseover", Viamatic.Xpose.MouseOut, true);
	outerDiv.addEventListener("mouseout", Viamatic.Xpose.MouseOver, true);
	cnv.addEventListener("click", Viamatic.Xpose.ChangeFocus, true);	
	cnv.addEventListener("mousedown", Viamatic.Xpose.OnClick_Canvas, true);
	this.setTitle = function(win) {
		
		if (win.document.title == "") {
			this.textPanel.innerHTML = win.document.location.href;
			this.canvas.title = win.document.location.href;
		} else {
			this.textPanel.innerHTML = win.document.title;
			this.canvas.title = win.document.title;
		}		
	}
	
	this.updateView = function(win) {
		var cWindow = win;
		var w = cWindow.innerWidth;// + content.scrollMaxX;
		var h = cWindow.innerHeight;// + content.scrollMaxY;
		var canvas = this.canvas;
		
		if (w > 2500) w = 2500;
		if (h > 2500) h = 2500;
		
		var canvasW = Viamatic.Xpose.canvasW;
		var canvasH = Viamatic.Xpose.canvasH ;
	
		
		var ctx = canvas.getContext("2d");
		ctx.clearRect(0, 0, canvasW, canvasH);
		ctx.save();
		ctx.scale(canvasW/w, canvasH/h);
		ctx.drawWindow(cWindow, cWindow.scrollX, cWindow.scrollY, w+cWindow.scrollX, h+cWindow.scrollY, "rgb(255,255,255)");		
		ctx.restore();	
	}
}

Viamatic.Xpose.WindowVisible = function(state)
{
	Viamatic.Xpose.Visible = state;
	var xposeStatusBar = document.getElementById("xpose_statusbar");
	if(state) { 
        xposeStatusBar.style.backgroundPosition = "0 0";
		window.clearInterval(Viamatic.Xpose.UpdateTimer);
		Viamatic.Xpose.UpdateTimer = window.setInterval("Viamatic.Xpose.Update()", 1000 * 2);
    } else {
        xposeStatusBar.style.backgroundPosition = "-20px 0";
		window.clearInterval(Viamatic.Xpose.UpdateTimer);
		Viamatic.Xpose.UpdateTimer = null;
		Viamatic.Browsers = ""; // A little cleanup helps
		Viamatic.Tabs = ""; 	// A little cleanup helps
		Viamatic.Canvas = "";
		Viamatic.PictureViewers = "";
    }
}

Viamatic.Xpose.UpdateView = function(browser, canvas)
{	
	var cWindow = browser.contentWindow;
	var w = cWindow.innerWidth;// + content.scrollMaxX;
	var h = cWindow.innerHeight;// + content.scrollMaxY;
	if (w > 2500) w = 2500;
	if (h > 2500) h = 2500;
	
	var canvasW = Viamatic.Xpose.canvasW;
	var canvasH = Viamatic.Xpose.canvasH ;

	
	var ctx = canvas.getContext("2d");
	ctx.clearRect(0, 0, canvasW, canvasH);
	ctx.save();
	ctx.scale(canvasW/w, canvasH/h);
	ctx.drawWindow(cWindow, cWindow.scrollX, cWindow.scrollY, w+cWindow.scrollX, h+cWindow.scrollY, "rgb(255,255,255)");		
	ctx.restore();
	
}

Viamatic.Xpose.UpdateTitle = function(browser, title)
{	
	
}

Viamatic.Xpose.Update = function()
{
	if(Viamatic.Xpose.getUnicodePref("showtab") == "false") { 
		var cWindow = getBrowser().contentWindow;
		if(cWindow.document.location.href != "about:blank" || cWindow.document.title != "Viamatic foXpose") {
			try {
			Viamatic.Xpose.CurrentWindow.close();        
	    	Viamatic.Xpose.WindowVisible(false);
			} catch(e) {Viamatic.Debug.writeln("foXpose: Warning while closing " + e)}
		}
		if(!Viamatic.Xpose.HasFocus) return;
    }
	
    if(Viamatic.Xpose.getUnicodePref("autorefresh") == "false") return;
	for(var i = 0; i < Viamatic.Browsers.length; i++) {
		if(Viamatic.Browsers[i] == null) continue;
		var browser = Viamatic.Browsers[i];
		var pv = Viamatic.PictureViewers[i];
		if (browser.webProgress.isLoadingDocument) {
			//Viamatic.Xpose.UpdateView(Viamatic.Browsers[i], Viamatic.Canvas[i]); 
			pv.setTitle(browser.contentWindow);
			pv.updateView(browser.contentWindow);
		}
	}
}

Viamatic.Xpose.UnloadWindowHandler = function()
{
	var tabs = getBrowser().tabContainer;
    if(tabs.childNodes.length == 2 ) {
		Viamatic.Xpose.RemoveWindowHandler();
		Viamatic.Xpose.CurrentWindow.close();
		return; // Only two tabs
	}
	
	Viamatic.Xpose.RePaint(Viamatic.Xpose.CurrentWindow);
}

Viamatic.Xpose.SetWindowHandler = function() 
{
	for(var i = 0; i < Viamatic.Browsers.length; i++) {
		if(Viamatic.Browsers[i] == null) continue;
		try {
		Viamatic.Browsers[i].contentWindow.addEventListener("unload", Viamatic.Xpose.UnloadWindowHandler,false);		
		} catch (e) {}
	}	
}

Viamatic.Xpose.RemoveWindowHandler = function() 
{
	for(var i = 0; i < Viamatic.Browsers.length; i++) {
		if(Viamatic.Browsers[i] == null) continue;
		try {
		Viamatic.Browsers[i].contentWindow.removeEventListener("unload", Viamatic.Xpose.UnloadWindowHandler,false);	
		} catch (e) {}
	}
}


Viamatic.Xpose.RePaint = function(win)
{
    var themeCSS = Viamatic.Xpose.getUnicodePref("theme");
    if(themeCSS == "black") Viamatic.Xpose.Colors.Black();
    if(themeCSS == "white") Viamatic.Xpose.Colors.Default();
	
	Viamatic.Counter  = 0;
	Viamatic.Browsers = new Array();
	Viamatic.Tabs = new Array();
	Viamatic.Canvas = new Array();
	Viamatic.PictureViewers = new Array();
	
	var tBrowser = document.getElementById("content");
	var myBrowser = getBrowser();
	var tabs = myBrowser.tabContainer;
	
	win.addEventListener("blur", Viamatic.Xpose.LostFocus,false);
	win.addEventListener("unload", Viamatic.Xpose.Unload,false);
	win.addEventListener("keyup",Viamatic.Xpose.KeyPress,true); 
	
	var doc = win.document;
	
	doc.body.innerHTML = ""; 
	doc.body.style.margin = "0px";
    doc.body.style.backgroundColor = Viamatic.Xpose.Colors.BackgroundColor;
    doc.title = "Viamatic foXpose";
	var divFactor = 4.05;
	var nTabs = tabs.childNodes.length - 1;
	
	if(nTabs <= 9) divFactor = 3;
	if(nTabs <= 4) divFactor = 2;
	
	if(Viamatic.Xpose.getUnicodePref("autosize") != "true") {
	    if(Viamatic.Xpose.getUnicodePref("thumbsize") == "large")  divFactor = 2;
	    if(Viamatic.Xpose.getUnicodePref("thumbsize") == "medium") divFactor = 3;
	    if(Viamatic.Xpose.getUnicodePref("thumbsize") == "small")  divFactor = 4.05;
    }   
	
	for (var t = 0; t < tabs.childNodes.length; t++)
	{
		
		try
		{
			if (tabs.childNodes[t].boxObject.firstChild)
			{
				var cWindow = myBrowser.getBrowserForTab(tabs.childNodes[t]).contentWindow;
		
				if(cWindow.document.location.href == "about:blank" && cWindow.document.title == "Viamatic foXpose") continue;
				   

				var w = cWindow.innerWidth;// + content.scrollMaxX;
				var h = cWindow.innerHeight;// + content.scrollMaxY;
				if (w > 2500) w = 2500;
				if (h > 2500) h = 2500;

				var canvasW = w / (divFactor + .11);
				var canvasH = h / (divFactor + .11);
				var pv = new Viamatic.Xpose.PictureViewer(doc, canvasW, canvasH);
				var cnv = pv.canvas;	
				pv.setTitle(cWindow);
				
				Viamatic.Xpose.canvasW = canvasW;
				Viamatic.Xpose.canvasH = canvasH;
				
				var ctx = cnv.getContext("2d");
				ctx.clearRect(0, 0, canvasW, canvasH);
				ctx.save();
				ctx.scale(canvasW/w, canvasH/h);
				ctx.drawWindow(cWindow, cWindow.scrollX, cWindow.scrollY, w+cWindow.scrollX, h+cWindow.scrollY, "rgb(255,255,255)");		
				Viamatic.Browsers[Viamatic.Counter] 		= myBrowser.getBrowserForTab(tabs.childNodes[t]); //cWindow;
				Viamatic.Tabs[Viamatic.Counter]     		= tabs.childNodes[t];
				Viamatic.Canvas[Viamatic.Counter]   		= cnv;
				Viamatic.PictureViewers[Viamatic.Counter]   = pv;
				ctx.restore();
			}
		} catch(ex) {
			alert(ex);
		}
		
		Viamatic.Counter++;
			
	}
	Viamatic.Xpose.WindowVisible(true); 
	Viamatic.Xpose.SetWindowHandler(); 	
}

Viamatic.Xpose.ShowPreviousTab = function()
{
	var myBrowser = getBrowser();
	var tBrowser = document.getElementById("content");
	var selectedWindow = myBrowser.contentWindow;
	var tabs = myBrowser.tabContainer;
	if(Viamatic.Xpose.LastTab.href != null && Viamatic.Xpose.LastTab.title != null) {
		if(selectedWindow.document.location.href == "about:blank" && selectedWindow.document.title == "Viamatic foXpose") {
			for (var t = 0; t < tabs.childNodes.length; t++)
			{
				try
				{
					if (tabs.childNodes[t].boxObject.firstChild)
					{
						
						var cWindow = myBrowser.getBrowserForTab(tabs.childNodes[t]).contentWindow;
						if(cWindow.document.location.href == Viamatic.Xpose.LastTab.href 
						   && cWindow.document.title == Viamatic.Xpose.LastTab.title) {
							tBrowser.selectedTab = tabs.childNodes[t];
							return true;
						}
					}
				 } catch (e) {}
			 }
		}			
	} 
		
	Viamatic.Xpose.LastTab.href = myBrowser.contentWindow.document.location.href;
	Viamatic.Xpose.LastTab.title = myBrowser.contentWindow.document.title;
	
	return false;
}

Viamatic.Xpose.Main = function()
{
	if(Viamatic.Xpose.ShowPreviousTab()) return;
	
	var tBrowser = document.getElementById("content");	
	var myBrowser = getBrowser();
	var tabs = myBrowser.tabContainer;
	if(tabs.childNodes.length == 1 ) return; // Only one tab

	var win = null;	
	
	
	for (var t = 0; t < tabs.childNodes.length; t++)
	{
		try
		{
			if (tabs.childNodes[t].boxObject.firstChild)
			{
				
				var cWindow = myBrowser.getBrowserForTab(tabs.childNodes[t]).contentWindow;
				if(cWindow.document.location.href == "about:blank" && cWindow.document.title == "Viamatic foXpose") {
				    win = cWindow;
				    tBrowser.selectedTab = tabs.childNodes[t];
				    break;
				}
	        }
	     } catch (e) {}
	 }
	 if(Viamatic.Xpose.Visible) return;
	 
	if(win == null) {
	    var tab = tBrowser.addTab(null);
	    tBrowser.selectedTab = tab;
	    win = tBrowser.getBrowserForTab(tab).contentWindow;
	  
	    if(Viamatic.Xpose.getUnicodePref("showtab") == "false") {
	        tab.style.visibility = "collapse";
	        tab.style.width = "0px";
	        tab.maxWidth = 0;
	        tab.minWidth = 0;
	        tab.collapsed = true;
	    }

	}
	
	Viamatic.Xpose.CurrentWindow = win;
	var doc = win.document;
	doc.open(); doc.write(""); doc.close();
	Viamatic.Xpose.RePaint(win); 
	Viamatic.Xpose.HasFocus		 = true;
}
