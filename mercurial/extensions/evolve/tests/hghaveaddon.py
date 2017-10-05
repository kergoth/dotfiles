import hghave

@hghave.check("docgraph-ext", "Extension to generate graph from repository")
def docgraph():
    try:
        import hgext.docgraph
        hgext.docgraph.cmdtable # trigger import
    except ImportError:
        try:
            import hgext3rd.docgraph
            hgext3rd.docgraph.cmdtable # trigger import
        except ImportError:
            return False
    return True
