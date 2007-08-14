// ==UserScript==
// @name           Gmail: New in Label
// @namespace      http://sandy.mcarthur.org/gmail/newinlabel
// @description    Show count of new conversations since a label was last viewed.
// @include        http://mail.google.com/*
// @include        https://mail.google.com/*
// ==/UserScript==

/*
 * Gmail: New in Label - version 1.4 - (C) 2006 Sandy McArthur
 *
 * Updates can be found at http://sandy.mcarthur.org/gmail/newinlabel
 * Support: I'm not offering much but you can email me. You should be
 *           able to infer my email from the domain name above.
 * 
 * Notice: Like all Gmail user scripts, it's fragile and very dependent
 * on Gmail's behavior at the time I wrote it, March 2006. The slightest
 * change to the way Gmail communicates updates, label information, or
 * the current thread summary view may break this script.
 *
 * When you view a label, the message count for that label doesn't
 * update immediately. It will update on the next label refresh.
 *
 * Changes:
 *  1.3: Adapt to changes for the way label values may be sent starting
 *      in late April 2006.
 *  1.4: Changed it so the hook in point is discovered intead of being
 *      hard coded. Hopefully this will adapt to future Gmail changes.
 *      Added a non-intrusive version check that adds a footer tip
 *      when a new version of this script has been released.
 */

/*
 * Change this for non-english users. This can be inferred from the
 * browser's title bar when viewing a label. For example, when I view
 * the label "Foo" my title bar is: "Gmail - Label: Foo" . 
 * labelPrefix should be set to whatever is after the "Gmail - "
 * in your language and before the label name.
 */
var labelPrefix = "Label: ";

var debug = false;

var username = false;

var version = 1.4;

function getSavedKey(label) {
    return username + ".count." + label;
}

function getSavedCount(label) {
    var val = GM_getValue(getSavedKey(label), 0);
    if (debug >= 4) GM_log("getSavedCount for: " + label + " val: " + val);
    return val;
}

function updateSavedCount(label, count) {
    var savedKey = getSavedKey(label);
    var savedCount = GM_getValue(savedKey, 0);
    if (count != savedCount) {
        if (debug) GM_log("Updating: " + savedKey + " to: " + count);
        GM_setValue(savedKey, count);
    }
}

function getLastViewedKey(label) {
    return username + ".viewed." + label;
}

function getLastViewedCount(label) {
    var val = GM_getValue(getLastViewedKey(label), 0);
    if (debug >= 4) GM_log("getLastViewedCount for: " + label + " val: " + val);
    return val;
}

function updateLastViewedCount(label) {
    var savedKey = getSavedKey(label);
    var savedCount = GM_getValue(savedKey, 0);
    var lastViewKey = getLastViewedKey(label);
    if (debug) GM_log("Updating: " + lastViewKey + " to: " + savedCount);
    GM_setValue(lastViewKey, savedCount);
}

function calcNewCount(label, count) {
    var newCount = [label, count];
    var newVal = getSavedCount(label) - getLastViewedCount(label);
    if (debug) GM_log("New count for: " + label + " real: " + count + " difference: " + newVal);
    if (newVal < 0) {
        // unread conversation count somehow got lower than
        // what it was when the user last looked at the label.
        newCount[1] = 0;
        updateLastViewedCount(label);
    } else {
        // show difference instead of total
        newCount[1] = newVal;
    }
    return newCount;
}

function processUpdates(b) {
    if (debug >= 3) GM_log("processUpdates(b): " + toJsonString(b));
    var dataType = b[0];
    if (dataType == "ct") {
        // Label summary update
        if (debug == 2) GM_log("processUpdates(b): " + toJsonString(b));
        var newVals = b[1]; // array of arrays: [["Label", #],...]
        if (!newVals.processedByNewInLabel) {
            for (var nvI in newVals) {
                var lVal = newVals[nvI];
                var label = lVal[0];
                var count = lVal[1];
                updateSavedCount(label, count);
                newVals[nvI] = calcNewCount(label, count);
            }
            newVals.processedByNewInLabel = true;
        }
        
    } else if (dataType == "ts") {
        // Conversation (thread) summary update
        if (debug == 2) GM_log("processUpdates(b): " + toJsonString(b));
        var label = b[5];
        if (label.indexOf(labelPrefix) === 0) {
            label = label.substr(labelPrefix.length);
            updateLastViewedCount(label);
        }
        
    } else if (dataType == "ud") {
        if (debug == 2) GM_log("processUpdates(b): " + toJsonString(b));
        username = b[1];
        if (debug) GM_log("Current user: " + username);
        
    } else if (dataType == "ft") {
        if (debug == 2) GM_log("processUpdates(b): " + toJsonString(b));
        var newestVersion = GM_getValue("newestVersion", "" + version);
        newestVersion = parseFloat(newestVersion);
        if (version < newestVersion) {
            b[1] += "<br/><br/>A newer version of the <a href\u003d\"http://sandy.mcarthur.org/gmail/newinlabel/\" target\u003d\"_blank\" style\u003d\"color:#0000CC\">Gmail: New in Label</a> user script is available.";
        }
    }
    return b;
}

// Tie into data flow.

function intercept(proto, name, func) {
    proto[name] = function(a, b, c, d) {
        d = processUpdates(d);
        func(a, b, c, d);
    };
}

function findCases() {
    var debug = false;
    var js = unsafeWindow;
    for (var propName in js) {
        var propValue = js[propName];

        if (typeof(propValue) == "function") {
            for (var protoName in propValue.prototype) {
                var protoValue = propValue.prototype[protoName];

                if (typeof(protoValue) == "function") {
                    var str = "" + protoValue;
                    if (str.indexOf("case \"ct\"") > 0) {
                        if (debug) GM_log("found: " + propName + ".prototype." + protoName);
                        intercept(propValue.prototype, protoName, protoValue);
                    }
                }
            }
        }
    }
}
unsafeWindow.addEventListener('load', findCases, true);


function checkVersion() {
    var lastCheck = GM_getValue("lastCheck", new Date("1/1/1970").toString());
    lastCheck = new Date(lastCheck);
    var now = new Date();
    var milliSinceLastCheck = now.getTime() - lastCheck.getTime();
    var checkInterval = GM_getValue("checkInterval", "" + (24 * 60 * 60 * 1000)); // once a day
    if (milliSinceLastCheck > checkInterval) {
        GM_xmlhttpRequest({
            method:"GET",
            url:"http://sandy.mcarthur.org/gmail/newinlabel/current-version.txt?version=" + version,
            onload:function (details) {
                if (details.readyState == 4 && details.status == 200) {
                    GM_setValue("lastCheck", now.toString());
                    var responseText = details.responseText;
                    if (responseText) {
                        var responses = responseText.split(/\s+/);
                        if (responses[0]) {
                            var newestVersion = parseFloat(responses[0])
                            GM_setValue("newestVersion", "" + newestVersion);
                        }
                        if (responses[1]) {
                            var checkInterval = parseInt(responses[1]);
                            GM_setValue("checkInterval", "" + checkInterval);
                        }
                    }
                }
            }
        });

    }
}
unsafeWindow.addEventListener('load', checkVersion, true);

// From: http://trimpath.com/project/wiki/JsonLibrary
/*
Copyright (c) 2002 JSON.org

Permission is hereby granted, free of charge, to any person obtaining a copy 
of this software and associated documentation files (the "Software"), to deal 
in the Software without restriction, including without limitation the rights 
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
copies of the Software, and to permit persons to whom the Software is 
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all 
copies or substantial portions of the Software.

The Software shall be used for Good, not Evil.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE 
SOFTWARE.
*/
toJsonString = function(arg) {
    return toJsonStringArray(arg).join('');
}

toJsonStringArray = function(arg, out) {
    out = out || new Array();
    var u; // undefined

    switch (typeof arg) {
    case 'object':
        if (arg) {
            if (arg.constructor == Array) {
                out.push('[');
                for (var i = 0; i < arg.length; ++i) {
                    if (i > 0) {
                        //out.push(',\n');
                        out.push(', ');
                    }
                    toJsonStringArray(arg[i], out);
                }
                out.push(']');
                return out;
            } else if (typeof arg.toString != 'undefined') {
                out.push('{');
                var first = true;
                for (var i in arg) {
                    var curr = out.length; // Record position to allow undo when arg[i] is undefined.
                    if (!first) {
                        //out.push(',\n');
                        out.push(', ');
                    }
                    toJsonStringArray(i, out);
                    out.push(':');                    
                    toJsonStringArray(arg[i], out);
                    if (out[out.length - 1] == u)
                        out.splice(curr, out.length - curr);
                    else
                        first = false;
                }
                out.push('}');
                return out;
            }
            return out;
        }
        out.push('null');
        return out;
    case 'unknown':
    case 'undefined':
    case 'function':
        out.push(u);
        return out;
    case 'string':
        out.push('"')
        out.push(arg.replace(/(["\\])/g, '\\$1').replace(/\r/g, '').replace(/\n/g, '\\n'));
        out.push('"');
        return out;
    default:
        out.push(String(arg));
        return out;
    }
}