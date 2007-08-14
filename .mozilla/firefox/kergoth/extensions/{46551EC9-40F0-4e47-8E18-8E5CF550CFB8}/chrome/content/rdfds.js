/* -*- Mode: C++; tab-width: 8; indent-tabs-mode: nil; c-basic-offset: 4 -*-
 * The contents of this file are subject to the Mozilla Public
 * License Version 1.1 (the "License"); you may not use this file
 * except in compliance with the License. You may obtain a copy of
 * the License at http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS
 * IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
 * implied. See the License for the specific language governing
 * rights and limitations under the License.
 *
 * The Original Code is rdfds
 *
 * The Initial Developer of the Original Code is Neil Deakin
 * Portions created by Neil Deakin are Copyright (C) 2002 Neil Deakin.
 * All Rights Reserved.
 *
 * Contributor(s):
 *   Jason Barnabe
 */

/* This is a library for easier access to RDF datasources and resources.
 * It contains four objects, StylishRDFDataSource, StylishRDFNode, StylishRDFLiteral. and
 * StylishRDFEnumerator.
 *
 * An RDF DataSource is a graph of nodes and literals. The constructor
 * for StylishRDFDataSource takes one argument, a URI of an RDF file to use.
 * If the URI exists, the contents of the RDF file are loaded. If it
 * does not exist, resources can be added to it and then written using
 * this save method. If the URL argument is null, a blank datasource
 * is created.
 *
 * This library is designed for convenience not for efficiency.
 *
 * The API is documented at:
 *   http://www.xulplanet.com/tutorials/xultu/rdfds/
 *
 * Example:
 *
 * var ds=new StylishRDFDataSource("file:///main/mozilla/mimtest.rdf");
 * var node=ds.getNode("http://www.example.com/sample");
 * var child=ds.getNode("http://www.example.com/child");
 * child=node.addChild(child);
 * child.addTarget("http://www.xulplanet.com/rdf/xpimaker#appname","Find Files");
 * ds.save();
 *
 */

var RDFService = "@mozilla.org/rdf/rdf-service;1";
RDFService = Components.classes[RDFService].getService();
RDFService = RDFService.QueryInterface(Components.interfaces.nsIRDFService);

var RDFContainerUtilsService = "@mozilla.org/rdf/container-utils;1";
RDFContainerUtilsService = Components.classes[RDFContainerUtilsService].getService();
RDFContainerUtilsService = RDFContainerUtilsService.QueryInterface(Components.interfaces.nsIRDFContainerUtils);

/* RDFLoadObserver
 *   this object is necessary to listen to RDF files being loaded. The Init
 *   function should be called to initialize the callback when the RDF file is
 *   loaded.
 */
function RDFLoadObserver(){}
  
RDFLoadObserver.prototype =
{
  callback: null,
  callbackDataSource: null,

  Init: function(c,cDS){
    this.callback=c;
    this.callbackDataSource=cDS;
  },

  QueryInterface: function(iid){
    if (iid.equals(Components.interfaces.nsIRDFXMLSinkObserver)) return this;
    else throw Components.results.NS_ERROR_NO_INTERFACE;
  },

  onBeginLoad : function(sink){},
  onInterrupt : function(sink){},
  onResume : function(sink){},
  onError : function(sink,status,msg){},
 
  onEndLoad : function(sink){
    if (this.callback!=null) this.callback(this.callbackDataSource);
  }
};  

function StylishRDFDataSource(uri,callbackFn)
{
  if (uri==null) this.datasource=null;
  else this.load(uri,callbackFn);
}

StylishRDFDataSource.prototype.load=
  function(uri,callbackFn)
{
  if (uri.indexOf(":") == -1){
    var docurl=document.location.href;
    if (document.location.pathname == null) uri=docurl+"/"+uri;
    else uri=docurl.substring(0,docurl.lastIndexOf("/")+1)+uri;
  }

  if (callbackFn == null){
    this.datasource=RDFService.GetDataSourceBlocking(uri);
  }
  else {
    this.datasource=RDFService.GetDataSource(uri);
    var ds;
    try {
      ds=this.datasource.QueryInterface(Components.interfaces.nsIRDFRemoteDataSource);
    }
    catch (ex){
      callbackFn(this);
      return;
    }
    if (ds.loaded){
      callbackFn(this);
      return;
    }

    var packObserver=new RDFLoadObserver();
    packObserver.Init(callbackFn,this);

    var rawsource=this.datasource;
    rawsource=rawsource.QueryInterface(Components.interfaces.nsIRDFXMLSink);
    rawsource.addXMLSinkObserver(packObserver);
  }
}

StylishRDFDataSource.prototype.Init=
  function (dsource)
{
  this.datasource=dsource;
}

StylishRDFDataSource.prototype.parseFromString=
  function (str,baseUri)
{
  if (this.datasource==null) this.makeemptyds();
  var ios=Components.classes["@mozilla.org/network/io-service;1"]
                    .getService(Components.interfaces.nsIIOService);
  baseUri=ios.newURI(baseUri,null,null);
  var xmlParser=Components.classes["@mozilla.org/rdf/xml-parser;1"]
                          .createInstance(Components.interfaces.nsIRDFXMLParser);
  xmlParser.parseString(this.datasource,baseUri,str);
}

StylishRDFDataSource.prototype.serializeToString=
  function ()
{
  var outputStream = {
    data: "",
    close : function(){},
    flush : function(){},
    write : function (buffer,count){
      this.data += buffer;
      return count;
    },
    writeFrom : function (stream,count){},
    isNonBlocking: false
  }
  this.serializeToStream(outputStream);
  return outputStream.data;
}

StylishRDFDataSource.prototype.serializeToStream=
  function (outputStream)
{
  var ser=Components.classes["@mozilla.org/rdf/xml-serializer;1"]
                    .createInstance(Components.interfaces.nsIRDFXMLSerializer);
  ser.init(this.datasource);
  ser.QueryInterface(Components.interfaces.nsIRDFXMLSource).Serialize(outputStream);
}

StylishRDFDataSource.prototype.makeemptyds=
  function (uri)
{
  this.datasource=Components.classes["@mozilla.org/rdf/datasource;1?name=in-memory-datasource"]
                            .createInstance(Components.interfaces.nsIRDFDataSource);
}

StylishRDFDataSource.prototype.getAllResources=
  function ()
{
  if (this.datasource==null) return null;
  return new StylishRDFEnumerator(this.datasource.GetAllResources(),this.datasource);
}

StylishRDFDataSource.prototype.getRawDataSource=
  function ()
{
  if (this.datasource==null) this.makeemptyds();
  return this.datasource;
}

StylishRDFDataSource.prototype.getNode=
  function (uri)
{
  if (this.datasource==null) this.makeemptyds();
  var node=new StylishRDFNode(uri,this);
  return node;
}

StylishRDFDataSource.prototype.getAnonymousNode=
  function ()
{
  if (this.datasource==null) this.makeemptyds();

  var anon=RDFService.GetAnonymousResource();
  var node=new StylishRDFNode();
  node.Init(anon,this.datasource);
  return node;
}

StylishRDFDataSource.prototype.getLiteral=
  function (uri)
{
  if (this.datasource==null) this.makeemptyds();

  return new StylishRDFLiteral(uri,this);
}

StylishRDFDataSource.prototype.refresh=
  function (sync)
{
  try {
    var ds=this.datasource.QueryInterface(Components.interfaces.nsIRDFRemoteDataSource);
    ds.Refresh(sync);
    return true;
  }
  catch (ex){
    return false;
  }
}

StylishRDFDataSource.prototype.save=
  function ()
{
  try {
    var ds=this.datasource.QueryInterface(Components.interfaces.nsIRDFRemoteDataSource);
    ds.Flush();
    return true;
  }
  catch (ex){
    return false;
  }
}

StylishRDFDataSource.prototype.copyAllToDataSource=
  function (dsource2)
{
  if (this.datasource==null) this.makeemptyds();
  if (dsource2.datasource==null) dsource2.makeemptyds();

  var dsource1=this.datasource;
  dsource2=dsource2.datasource;

  var sourcelist=dsource1.GetAllResources();
  while(sourcelist.hasMoreElements()){
    var source=sourcelist.getNext();
    var props=dsource1.ArcLabelsOut(source);
    while(props.hasMoreElements()){
      var prop=props.getNext();
      prop=prop.QueryInterface(Components.interfaces.nsIRDFResource);
      var target=dsource1.GetTarget(source,prop,true);
      if (target!=null) dsource2.Assert(source,prop,target,true);
    }
  }
}

StylishRDFDataSource.prototype.deleteRecursive=
  function (val)
{
  var node;
  var dsource=this.datasource;

  if (dsource==null) return;

  if (typeof val == "string") node=RDFService.GetResource(val);
  else node=val.source;

  this.deleteRecursiveH(dsource,node); // remove descendants

  // remove the node itself
  var props=dsource.ArcLabelsIn(node);
  while(props.hasMoreElements()){
    var prop=props.getNext();
    var source=dsource.GetSource(prop,node,true);
    dsource.Unassert(source,prop,node);
  }
}

StylishRDFDataSource.prototype.deleteRecursiveH=
  function (dsource,node)
{
  var props=dsource.ArcLabelsOut(node);
  while(props.hasMoreElements()){
    var prop=props.getNext();
    var targets=dsource.GetTargets(node,prop,true);
    while(targets.hasMoreElements()) {
			var target = targets.getNext();
      try {
        target=target.QueryInterface(Components.interfaces.nsIRDFResource);
        this.deleteRecursiveH(dsource,target);
      }
      catch (e){}
      dsource.Unassert(node,prop,target)
    }
/*    var target=dsource.GetTarget(node,prop,true);
    try {
      target=target.QueryInterface(Components.interfaces.nsIRDFResource);
      this.deleteRecursiveH(dsource,target);
    }
    catch (e){}
    dsource.Unassert(node,prop,target)*/
  }
}

function StylishRDFNode(uri,dsource)
{
  if (uri==null) this.source=null;
  else this.source=RDFService.GetResource(uri);

  if (dsource==null) this.datasource=null;
  else this.datasource=dsource.datasource;

  this.container=null;
}

StylishRDFNode.prototype.Init=
  function (source,dsource)
{
  this.source=source;
  this.datasource=dsource;
  this.container=null;
}

StylishRDFNode.prototype.getValue=
  function ()
{
  return this.source.Value;
}

StylishRDFNode.prototype.rlify=
  function (val)
{
  var res=null;

  if (val!=null){
    try {
      val=val.QueryInterface(Components.interfaces.nsIRDFResource);
      res=new StylishRDFNode();
      res.Init(val,this.datasource);
    }
    catch (ex){
      try {
        val=val.QueryInterface(Components.interfaces.nsIRDFLiteral);
        res=new StylishRDFLiteral();
        res.Init(val,this.datasource);
      }
      catch (ex2){
      }
    }
  }
  return res;
}

StylishRDFNode.prototype.makeres=
  function (val)
{
  if (typeof val == "string") return RDFService.GetResource(val);
  else return val.source;
}

StylishRDFNode.prototype.makelit=
  function (val)
{
  if (typeof val == "string") return RDFService.GetLiteral(val);
  else return val.source;
}

StylishRDFNode.prototype.makecontain=
  function ()
{
  if (this.container!=null) return true;

  var RDFContainer = '@mozilla.org/rdf/container;1';
  RDFContainer = Components.classes[RDFContainer].createInstance();
  RDFContainer = RDFContainer.QueryInterface(Components.interfaces.nsIRDFContainer);

  try {
    RDFContainer.Init(this.datasource,this.source);
    this.container=RDFContainer;
    return true;
  }
  catch (ex){
    return false;
  }
}

StylishRDFNode.prototype.addTarget=
  function (prop,target)
{
  prop=this.makeres(prop);
  target=this.makelit(target);
  this.datasource.Assert(this.source,prop,target,true);
}

StylishRDFNode.prototype.addTargetOnce=
  function (prop,target)
{
  prop=this.makeres(prop);
  target=this.makelit(target);

  var oldtarget=this.datasource.GetTarget(this.source,prop,true);
  if (oldtarget!=null){
    this.datasource.Change(this.source,prop,oldtarget,target);
  }
  else {
    this.datasource.Assert(this.source,prop,target,true);
  }
}

StylishRDFNode.prototype.modifyTarget=
  function (prop,oldtarget,newtarget)
{
  prop=this.makeres(prop);
  oldtarget=this.makelit(oldtarget);
  newtarget=this.makelit(newtarget);
  this.datasource.Change(this.source,prop,oldtarget,newtarget);
}

StylishRDFNode.prototype.modifySource=
  function (prop,oldsource,newsource)
{
  prop=this.makeres(prop);
  oldsource=this.makeres(oldsource);
  newsource=this.makeres(newsource);
  this.datasource.Move(oldsource,newsource,prop,this.source);
}

StylishRDFNode.prototype.targetExists=
  function (prop,target)
{
  prop=this.makeres(prop);
  target=this.makelit(target);
  return this.datasource.HasAssertion(this.source,prop,target,true);
}

StylishRDFNode.prototype.removeTarget=
  function (prop,target)
{
  prop=this.makeres(prop);
  target=this.makelit(target);
  this.datasource.Unassert(this.source,prop,target);
}

StylishRDFNode.prototype.getProperties=
  function ()
{
  return new StylishRDFEnumerator(this.datasource.ArcLabelsOut(this.source),this.datasource);
}

StylishRDFNode.prototype.getInProperties=
  function ()
{
  return new StylishRDFEnumerator(this.datasource.ArcLabelsIn(this.source),this.datasource);
}

StylishRDFNode.prototype.propertyExists=
  function (prop)
{
  prop=this.makeres(prop);
  return this.datasource.hasArcOut(this.source,prop);
}

StylishRDFNode.prototype.inPropertyExists=
  function (prop)
{
  prop=this.makeres(prop);
  return this.datasource.hasArcIn(this.source,prop);
}

StylishRDFNode.prototype.getTarget=
  function (prop)
{
  prop=this.makeres(prop);
  return this.rlify(this.datasource.GetTarget(this.source,prop,true));
}

StylishRDFNode.prototype.getSource=
  function (prop)
{
  prop=this.makeres(prop);
  var src=this.datasource.GetSource(prop,this.source,true);
  if (src==null) return null;
  var res=new StylishRDFNode();
  res.Init(src,this.datasource);
  return res;
}

StylishRDFNode.prototype.getTargets=
  function (prop)
{
  prop=this.makeres(prop);
  return new StylishRDFEnumerator(
    this.datasource.GetTargets(this.source,prop,true),this.datasource);
}

StylishRDFNode.prototype.getSources=
  function (prop)
{
  prop=this.makeres(prop);
  return new StylishRDFEnumerator(
    this.datasource.GetSources(prop,this.source,true),this.datasource);
}

StylishRDFNode.prototype.makeBag=
  function ()
{
  this.container=RDFContainerUtilsService.MakeBag(this.datasource,this.source);
}

StylishRDFNode.prototype.makeSeq=
  function ()
{
  this.container=RDFContainerUtilsService.MakeSeq(this.datasource,this.source);
}

StylishRDFNode.prototype.makeAlt=
  function ()
{
  this.container=RDFContainerUtilsService.MakeAlt(this.datasource,this.source);
}

StylishRDFNode.prototype.isBag=
  function ()
{
  return RDFContainerUtilsService.IsBag(this.datasource,this.source);
}

StylishRDFNode.prototype.isSeq=
  function ()
{
  return RDFContainerUtilsService.IsSeq(this.datasource,this.source);
}

StylishRDFNode.prototype.isAlt=
  function ()
{
  return RDFContainerUtilsService.IsAlt(this.datasource,this.source);
}

StylishRDFNode.prototype.isContainer=
  function ()
{
  return RDFContainerUtilsService.IsContainer(this.datasource,this.source);
}

StylishRDFNode.prototype.getChildCount=
  function ()
{
  if (this.makecontain()){
    return this.container.GetCount();
  }
  return -1;
}

StylishRDFNode.prototype.getChildren=
  function ()
{
  if (this.makecontain()){
    return new StylishRDFEnumerator(this.container.GetElements(),this.datasource);
  }
  else return null;
}

StylishRDFNode.prototype.addChild=
  function (child,exists)
{
  if (this.makecontain()){
    var childres=null;
    if (typeof child == "string"){
      childres=RDFService.GetResource(child);
      child=new StylishRDFNode();
      child.Init(childres,this.datasource);
    }
    else childres=child.source;

    if (!exists && this.container.IndexOf(childres)>=0) return child;

    this.container.AppendElement(childres);
    return child;
  }
  else return null;
}

StylishRDFNode.prototype.addChildAt=
  function (child,idx)
{
  if (this.makecontain()){
    var childres=null;
    if (typeof child == "string"){
      childres=RDFService.GetResource(child);
      child=new StylishRDFNode();
      child.Init(childres,this.datasource);
    }
    else childres=child.source;
    this.container.InsertElementAt(childres,idx,true);
    return child;
  }
  else return null;
}

StylishRDFNode.prototype.removeChild=
  function (child)
{
  if (this.makecontain()){
    var childres=null;
    if (typeof child == "string"){
      childres=RDFService.GetResource(child);
      child=new StylishRDFNode();
      child.Init(childres,this.datasource);
    }
    else childres=child.source;
    this.container.RemoveElement(childres,true);
    return child;
  }
  else return null;
}

StylishRDFNode.prototype.removeChildAt=
  function (idx)
{
  if (this.makecontain()){
    var childres=this.container.RemoveElementAt(idx,true);
    return this.rlify(childres);
  }
  else return null;
}

StylishRDFNode.prototype.getChildIndex=
  function (child)
{
  if (this.makecontain()){
    return this.container.IndexOf(child.source);
  }
  else return -1;
}

StylishRDFNode.prototype.type="Node";


function StylishRDFLiteral(val,dsource)
{
  if (val==null) this.source=null;
  else this.source=RDFService.GetLiteral(val);

  if (dsource==null) this.datasource=null;
  else this.datasource=dsource.datasource;
}

StylishRDFLiteral.prototype.Init=
  function (source,dsource)
{
  this.source=source;
  this.datasource=dsource;
}

StylishRDFLiteral.prototype.getValue=
  function ()
{
  return this.source.Value;
}

StylishRDFLiteral.prototype.makeres=
  function (val)
{
  if (typeof val == "string") return RDFService.GetResource(val);
  else return val.source;
}

StylishRDFLiteral.prototype.makelit=
  function (val)
{
  if (typeof val == "string") return RDFService.GetLiteral(val);
  else return val.source;
}

StylishRDFLiteral.prototype.modifySource=
  function (prop,oldsource,newsource)
{
  prop=this.makeres(prop);
  oldsource=this.makeres(oldsource);
  newsource=this.makeres(newsource);
  this.datasource.Move(oldsource,newsource,prop,this.source);
}

StylishRDFLiteral.prototype.getInProperties=
  function (prop)
{
  return new StylishRDFEnumerator(this.datasource.ArcLabelsIn(this.source),this.datasource);
}

StylishRDFLiteral.prototype.inPropertyExists=
  function (prop)
{
  prop=this.makeres(prop);
  return this.datasource.hasArcIn(this.source,prop);
}

StylishRDFLiteral.prototype.getSource=
  function (prop)
{
  prop=this.makeres(prop);
  var src=this.datasource.GetSource(prop,this.source,true);
  if (src==null) return null;
  var res=new StylishRDFNode();
  res.Init(src,this.datasource);
  return res;
}

StylishRDFLiteral.prototype.getSources=
  function (prop)
{
  prop=this.makeres(prop);
  return new StylishRDFEnumerator(
    this.datasource.GetSources(prop,this.source,true),this.datasource);
}

StylishRDFLiteral.prototype.type="Literal";


function StylishRDFEnumerator(enumeration,dsource)
{
  this.enumeration=enumeration;
  this.datasource=dsource;
}

StylishRDFEnumerator.prototype.hasMoreElements=
  function ()
{
  return this.enumeration.hasMoreElements();
}

StylishRDFEnumerator.prototype.getNext=
  function ()
{
  var res=null;
  var val=this.enumeration.getNext();

  if (val!=null){
    try {
      val=val.QueryInterface(Components.interfaces.nsIRDFResource);
      res=new StylishRDFNode();
      res.Init(val,this.datasource);
    }
    catch (ex){
      try {
        val=val.QueryInterface(Components.interfaces.nsIRDFLiteral);
        res=new StylishRDFLiteral();
        res.Init(val,this.datasource);
      }
      catch (ex2){
      }
    }
  }
  return res;
}
