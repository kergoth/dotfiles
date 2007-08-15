// ==UserScript==
// @name WoWHead Wish List
// @namespace WHWL
// @description	Creates A Wishlist for WoWHead.com
// @include http://*.wowhead.com/?item=*
// ==/UserScript==

document.getElementById("sidebar").parentNode.removeChild(document.getElementById("sidebar"));
document.getElementById("main").style.width = '98.5%';
CreateListDiv("WHWL");
CreateAddItem();

function CreateAddItem() {
	var divs = document.getElementsByTagName("div");
	for (var i = 0; i < divs.length; i++) {
		if (divs[i].id.match(/ic(.+)/, i)) {
			var div2num = i;
			var iconnum = divs[i].id.replace('ic', '');
		}
		if (divs[i].id.match(/tt(.+)/, i)) {
			var divnum = i;
			var itemnum = divs[i].id.replace('tt', '');
		}
	}
	GM_setValue(itemnum + '_tooltip', divs[divnum].innerHTML);
	var item = divs[divnum].getElementsByTagName("b");
	var itemclass = item[0].className;
	var itemname = item[0].innerHTML;
	var span = document.createElement("span");
	span.id = "additem";
	span.innerHTML = ' ';
	if (ItemExists(itemnum)) { span.style.visibility = 'hidden' }
	var a = document.createElement("a");
	a.innerHTML = '->';
	a.href = "javascript:;";
	a.id = itemclass + ':' + itemname + ':' + itemnum;
	a.addEventListener('click', AddItem, false);
	span.appendChild(a);
	item[0].appendChild(span);
}

function CreateListDiv(BoxId)
{
	var div = document.createElement("div");
	div.id = BoxId;
	div.style.borderTop = '1px solid #404040';
	div.style.position = 'relative';

	var table = document.createElement("table");
	table.id = BoxId + '_table';
	table.width = '100%';
	table.colSpacing = '0';
	table.colPadding = '0';
	table.style.margin = '0 0 0 0';
	table.style.padding = '0 0 0 0';

	var tr = document.createElement("tr");
	var th = document.createElement("th");
	th.style.padding = '4px';
	th.width = '100%';

	var a = document.createElement("a");
	a.style.color = 'white !important';
	a.style.textDecoration = 'none';
	a.innerHTML = "Wish List";
	a.href = "javascript:;";
	a.addEventListener("click", ToggleItems, false);

	th.appendChild(a);
	tr.appendChild(th);
	table.appendChild(tr);

	var tr = document.createElement("tr");
	tr.id = BoxId + '_items';
	tr.width = '100%';

	var td = document.createElement("td");
	td.style.margin = '0 0 0 0';
	td.style.padding = '0 0 0 0';
	var table2 = document.createElement("table");
	table2.id = BoxId + '_itemtable';
	table2.style.width = '100%';
	table2.style.margin = '0 0 0 0';
	table2.style.border = '1px';
	var tr2 = document.createElement("tr");
	var td2 = document.createElement("td");
	td2.style.margin = '0 0 0 0';
	td2.style.padding = '0 0 0 0';
	td2.colSpan = '2';
	td2.style.borderTop = '1px solid #404040';
	tr2.appendChild(td2);
	table2.appendChild(tr2);

	PopulateItems(table2);


	td.appendChild(table2);
	tr.appendChild(td);
	table.appendChild(tr);
	div.appendChild(table);

	var lols = document.getElementsByTagName("table");
	for (var i = 0; i < lols.length; i++) {
		lol = lols[i];
		if (lol.className == 'infobox') { 
			var num = i;
		}
	}
	lols[num].appendChild(div);
}

function RemoveItem(evt) {
	var divs = document.getElementsByTagName("div");
	for (var i = 0; i < divs.length; i++) {
		if (divs[i].id.match(/tt(.+)/, i)) {
			var divnum = i;
			var pageid = divs[i].id.replace('tt', '');
		}
	}
	if (pageid == evt['currentTarget'].id){
	var additem = document.getElementById('additem');
	additem.style.visibility = 'visible';
	}
	var itemid = evt['currentTarget'].id;
	var items = GM_getValue("items", '');
	items = items.split(':');
	if (itemid == items[0]) { if (items[1]) { document.getElementById(items[1] + '_up').style.display = 'none'; } }
	if (itemid == items[items.length-1]) { if (items[items.length-2]) { document.getElementById(items[items.length-2] + '_down').style.display = 'none'; } }
	var newitems = '';
	var first = 1;
	for (var i = 0; i < items.length; i++) {
		item = items[i];
		if (item != itemid) {
			if (first == 1) { 
				newitems += item;
				first = 0; 
			}
			else {
				newitems += ':' + item;
			}
		}
	}
	GM_setValue("items", newitems);
	evt['currentTarget'].parentNode.parentNode.parentNode.parentNode.removeChild(evt['currentTarget'].parentNode.parentNode.parentNode);
}

function AddItem(evt) {
	var itemlol = evt['currentTarget'].id.split(":");
	var itemid = itemlol[2];
	var itemclass = itemlol[0];
	var itemname = itemlol[1];
	if (GM_getValue("items", '').split(":")[0]) { document.getElementById(GM_getValue("items", '').split(":")[GM_getValue("items", '').split(":").length-1] + '_down').style.display = ''; }
	GM_setValue(itemid, itemname + ':' + itemclass);
	table = document.getElementById('WHWL_itemtable');
	var itemid = itemid;
	var tr = document.createElement("tr");
	var td = document.createElement("td");
	td.style.padding = '0 0 0 0';
	td.style.borderTop = '0';
	td.style.borderLeft = '1px solid #404040';
	td.style.borderBottom = '1px solid #404040';
	td.style.borderRight = '0';
	var span = document.createElement("span");

			var a = document.createElement("a");
			a.innerHTML = "<- ";
			a.href = "javascript:;";
			a.id = itemid;
			a.name = 'nottransfered';
			a.style.textDecoration = 'none';
			a.addEventListener('click', CompareItem, false);
			span.appendChild(a);

			var a = document.createElement("a");
			var item = GM_getValue(itemid, '').split(":");
			var itemname = item[0];
			var itemclass = item[1];
			a.innerHTML = itemname + ' ';
			a.className = itemclass;
			a.style.textDecoration = 'none';
			a.href = '?item=' + itemid;
			span.appendChild(a);
			td.appendChild(span);
			tr.appendChild(td);

			var td = document.createElement("td");
			td.style.padding = '0 0 0 0';
			td.style.borderTop = '0';
			td.style.borderLeft = '0';
			td.style.borderBottom = '1px solid #404040';
			td.style.borderRight = '1px solid #404040';
			var span = document.createElement("span");
			td.style.textAlign='right';
			var a = document.createElement("a");
			a.innerHTML = "[^]";
			a.href = "javascript:;";
			a.id = itemid + '_up';
			a.style.textDecoration = 'none';
			if (!GM_getValue("items", '').split(":")[0]) { a.style.display = 'none'; }
			a.addEventListener('click', MoveUp, false);
			span.appendChild(a);

			var a = document.createElement("a");
			a.innerHTML = "[v]";
			if (!GM_getValue("items", '').split(":")[0]) { a.style.display = 'none'; }
			a.href = "javascript:;";
			a.id = itemid + '_down';
			a.style.textDecoration = 'none';
			a.addEventListener('click', MoveDown, false);
			a.style.display = 'none';
			span.appendChild(a);


			var a = document.createElement("a");
			a.innerHTML = "[X]";
			a.href = "javascript:;";
			a.id = itemid;
			a.style.textDecoration = 'none';
			a.addEventListener('click', RemoveItem, false);
			span.appendChild(a);

			td.appendChild(span);

	tr.appendChild(td);
	table.appendChild(tr);

	var items = GM_getValue("items", '');
	var itemlist = items.split(":");
	var additem = document.getElementById('additem');
	additem.style.visibility = 'hidden';
	numitems = itemlist.length;
	if (itemlist[0]) {
		items += ':' + itemid;
	} 
	else {
		items = itemid;
	}
	GM_setValue("items", items);
}

function PopulateItems(table) {
	table.cellPadding = '0';
	table.cellSpacing = '0';
	var items = GM_getValue("items", '');
	var itemlist = items.split(":");
	numitems = itemlist.length;
	if (itemlist[0]) {
		for (var i = 0; i < numitems; i++)
		{
			var itemid = itemlist[i];
			var tr = document.createElement("tr");
			var td = document.createElement("td");
			td.style.padding = '0 0 0 0';
			td.style.borderTop = '0';
			td.style.borderLeft = '1px solid #404040';
			td.style.borderBottom = '1px solid #404040';
			td.style.borderRight = '0';
			var span = document.createElement("span");

			var a = document.createElement("a");
			a.innerHTML = "<- ";
			a.href = "javascript:;";
			a.id = itemid;
			a.name = 'nottransfered';
			a.style.textDecoration = 'none';
			a.addEventListener('click', CompareItem, false);
			span.appendChild(a);

			var a = document.createElement("a");
			var item = GM_getValue(itemid, '').split(":");
			var itemname = item[0];
			var itemclass = item[1];
			a.innerHTML = itemname + ' ';
			a.className = itemclass;
			a.style.textDecoration = 'none';
			a.href = '?item=' + itemid;
			span.appendChild(a);
			td.appendChild(span);
			tr.appendChild(td);

			var td = document.createElement("td");
			td.style.padding = '0 0 0 0';
			td.style.borderTop = '0';
			td.style.borderLeft = '0';
			td.style.borderBottom = '1px solid #404040';
			td.style.borderRight = '1px solid #404040';
			var span = document.createElement("span");
			td.style.textAlign='right';
			var a = document.createElement("a");
			a.innerHTML = "[^]";
			a.href = "javascript:;";
			a.id = itemid + '_up';
			a.style.textDecoration = 'none';
			a.addEventListener('click', MoveUp, false);
			span.appendChild(a);
			if (i==0) {
			a.style.display = 'none';
			}
			var a = document.createElement("a");
			a.innerHTML = "[v]";
			a.href = "javascript:;";
			a.id = itemid + '_down';
			a.style.textDecoration = 'none';
			a.addEventListener('click', MoveDown, false);
			if (i==numitems-1) {
			a.style.display = 'none';
			}
			span.appendChild(a);
			var a = document.createElement("a");
			a.innerHTML = "[X]";
			a.href = "javascript:;";
			a.id = itemid;
			a.style.textDecoration = 'none';
			a.addEventListener('click', RemoveItem, false);
			span.appendChild(a);

			td.appendChild(span);

			tr.appendChild(td);
			table.appendChild(tr);
		}
	}
}
function CompareItem(evt) {
		if(document.getElementById('compared')) {
		var div = document.getElementById('compared');
		div.parentNode.removeChild(div);
		}
		var itemnum = evt['currentTarget'].id;
		var divs = document.getElementsByTagName("div");
		for (var i = 0; i < divs.length; i++) {
			if (divs[i].id.match(/tt(.+)/, i)) {
				var divnum = i;
			}
			if (divs[i].id.match(/ic(.+)/, i)) {
				var div2num = i;
			}
		}
		var div = document.createElement("div");
		div.id = 'compared';
		div.className = 'tooltip';
		div.style.width = '700px';
		div.style.float = 'left';
		div.style.paddingTop = '1px';
		div.style.visibility = 'visible';
		div.innerHTML = GM_getValue(itemnum + '_tooltip', 0);
		var container = document.createElement("table");
		container.style.width = '100%';
		var tr = document.createElement("tr");
		var item = document.createElement("td");

		var close = document.createElement("td");
		var itemtitle = div.getElementsByTagName("b");
		var br = div.getElementsByTagName("br");
		br[0].parentNode.removeChild(br[0]);
		var a = document.createElement("a");
		a.innerHTML = "&nbsp;&nbsp;&nbsp;[X]";
		a.href = "javascript:;";
		a.style.color = 'red';
		a.style.textDecoration = 'none';
		a.addEventListener('click', RemoveCompare, false);
		close.appendChild(a);

		close.style.textAlign = 'right';

		itemtitle[0].parentNode.insertBefore(container, itemtitle[0]);
		item.appendChild(itemtitle[0]);
		tr.appendChild(item);
		tr.appendChild(close);
		container.appendChild(tr);
		divs[divnum].parentNode.insertBefore(div, divs[divnum].nextSibling);
}

function RemoveCompare(evt) {
		if(document.getElementById('compared')) {
		var div = document.getElementById('compared');
		div.parentNode.removeChild(div);
		}
}

function ItemExists(itemnum) {
	var items = GM_getValue("items", '');
	items = items.split(':');
	for (var i = 0; i < items.length; i++) {
		item = items[i];
		if (itemnum == item) {
		return true;
		}
	}
		return false;
}

function MoveUp(evt) {
	evt['currentTarget'].nextSibling.style.display = '';
	item = evt['currentTarget'].parentNode.parentNode.parentNode;
	tr = evt['currentTarget'].parentNode.parentNode.parentNode.previousSibling;
	tr.parentNode.insertBefore(item, tr);
	itemnum = evt['currentTarget'].id.split("_")[0];
	items = GM_getValue('items').split(":");
	indexnum = items.indexOf(itemnum);
	var index2 = indexnum - 1;
	var tempitem = items[index2];
	items[index2] = items[indexnum];
	items[indexnum] = tempitem;
	if (index2 == 0) { 
		evt['currentTarget'].style.display = 'none';
		document.getElementById(items[1] + '_up').style.display = '';
	}
	if (indexnum == items.length-1) { 
		document.getElementById(items[indexnum] + '_down').style.display = 'none';
	}
	var newitems = '';
	for (var i = 0; i < items.length; i++) {
	if (newitems) {
		newitems += ':' + items[i];
	} 
	else {
		newitems = items[i];
	}
	}
	GM_setValue('items', newitems);
}

function MoveDown(evt) {
	evt['currentTarget'].previousSibling.style.display = '';
	item = evt['currentTarget'].parentNode.parentNode.parentNode;
	tr = evt['currentTarget'].parentNode.parentNode.parentNode.nextSibling;
	insertAfter(item.parentNode, item, tr);
	itemnum = evt['currentTarget'].id.split("_")[0];
	items = GM_getValue('items').split(":");
	indexnum = items.indexOf(itemnum);
	var index2 = indexnum + 1;
	if (index2 == items.length-1) { 
		evt['currentTarget'].style.display = 'none';
		document.getElementById(items[items.length-1] + '_down').style.display = '';
	}
	if (indexnum == 0) { 
		document.getElementById(items[indexnum+1] + '_up').style.display = 'none';
	}
	var tempitem = items[index2];
	items[index2] = items[indexnum];
	items[indexnum] = tempitem;
	var newitems = '';
	for (var i = 0; i < items.length; i++) {
	if (newitems) {
		newitems += ':' + items[i];
	} 
	else {
		newitems = items[i];
	}
	}
	GM_setValue('items', newitems);
}

function ToggleItems(evt) {
 var div = document.getElementById("WHWL_items");
 if(div.style.display == 'none') {
  div.style.display = '';
 }else{
  div.style.display = 'none';
 }
}

function insertAfter(parent, node, referenceNode) {
	parent.insertBefore(node, referenceNode.nextSibling);
}