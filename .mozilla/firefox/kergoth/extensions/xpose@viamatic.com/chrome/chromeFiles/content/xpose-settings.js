
Viamatic.Xpose.Settings.getComboPref = function(element, value) {
   var comboElement = document.getElementById(element);
   if(comboElement) comboElement.value = Viamatic.Xpose.getUnicodePref(value);
}

Viamatic.Xpose.Settings.setComboPref = function(element, value) {
   var comboElement = document.getElementById(element);
   if(comboElement) Viamatic.Xpose.setUnicodePref(value, comboElement.value);
}

Viamatic.Xpose.Settings.getCheckboxPref = function(element, value) {
   var checkboxElement = document.getElementById(element);
   if(checkboxElement) {
        if (Viamatic.Xpose.getUnicodePref(value) == "false") checkboxElement.checked = false;
        else checkboxElement.checked = true;
   }
}

Viamatic.Xpose.Settings.setCheckboxPref = function(element, value) {
   var checkboxElement = document.getElementById(element);
   if(checkboxElement) { 
        if(checkboxElement.checked == true) Viamatic.Xpose.setUnicodePref(value, "true");  
        else Viamatic.Xpose.setUnicodePref(value, "false");
   }
}

Viamatic.Xpose.Settings.Main = function() {
    Viamatic.Xpose.Settings.getComboPref("cmbKeyCode", "shortcutkey");
    Viamatic.Xpose.Settings.getComboPref("cmbModifier", "shortcutmodifier");
    Viamatic.Xpose.Settings.getComboPref("cmbThemes", "theme");
    Viamatic.Xpose.Settings.getComboPref("cmbKeyCode", "shortcutkey");
    Viamatic.Xpose.Settings.getComboPref("cmbSize", "thumbsize");
    
    Viamatic.Xpose.Settings.getCheckboxPref("chkStatusBar", "showicon");
    Viamatic.Xpose.Settings.getCheckboxPref("chkKeyShortcut", "showkeyboardtitle");
    Viamatic.Xpose.Settings.getCheckboxPref("chkShowTab", "showtab");
    Viamatic.Xpose.Settings.getCheckboxPref("chkRefresh", "autorefresh");
    Viamatic.Xpose.Settings.getCheckboxPref("chkAutoSize", "autosize");
    
    if(!document.getElementById("chkAutoSize").checked) {
        document.getElementById("lblSize").disabled = false;
        document.getElementById("cmbSize").disabled = false;
    }
}

Viamatic.Xpose.Settings.Ok_Click = function() {
    Viamatic.Xpose.Settings.setComboPref("cmbKeyCode", "shortcutkey");
    Viamatic.Xpose.Settings.setComboPref("cmbModifier", "shortcutmodifier");
    Viamatic.Xpose.Settings.setComboPref("cmbThemes", "theme");
    Viamatic.Xpose.Settings.setComboPref("cmbKeyCode", "shortcutkey");
    Viamatic.Xpose.Settings.setComboPref("cmbSize", "thumbsize");
    
    Viamatic.Xpose.Settings.setCheckboxPref("chkStatusBar", "showicon");
    Viamatic.Xpose.Settings.setCheckboxPref("chkKeyShortcut", "showkeyboardtitle");
    Viamatic.Xpose.Settings.setCheckboxPref("chkShowTab", "showtab");
    Viamatic.Xpose.Settings.setCheckboxPref("chkRefresh", "autorefresh");
    Viamatic.Xpose.Settings.setCheckboxPref("chkAutoSize", "autosize");
  
    window.close();
    
}

window.addEventListener('load', Viamatic.Xpose.Settings.Main, false); 

function chkAutoSize_Change(chkAutoSize) {
    var lblSize = document.getElementById("lblSize");
    var cmbSize = document.getElementById("cmbSize");
    
    lblSize.disabled = !chkAutoSize.checked;
    cmbSize.disabled = !chkAutoSize.checked;
  
}

function cmbThemes_OnClick(cmbThemes) {
    var grpUserDefined = document.getElementById("grpUserDefined");
    if(cmbThemes.value == "userdefined") {
        grpUserDefined.style.display = "";
    } else {
        grpUserDefined.style.display = "none";
    }
}