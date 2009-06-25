var origDomain = document.domain
var pieces = location.href.split("#")
var full = pieces[0]
var hash = pieces[1]
pieces = full.split('?')
var base = pieces[0]
//var newUrl = pieces[0] +  "&x=y" + "#" + pieces[1]
function decodeQS(qs) {
    if (qs.indexOf('=') == -1) return {}
    var result = {}
    var chunks = qs.split('&')
    for (var i = 0; i < chunks.length; ++i) {
        var cur = chunks[i]
        pieces = cur.split('=')
        result[pieces[0]] = pieces[1]
    }
    return result
}
var origForm = decodeQS(pieces[1])
id = parseInt(origForm['frameID']);
function doClose() {
    try {
        parent.Orbited.singleton.HTMLFile.instances[id].streamClosed();
        return
    }
    catch(e) {
    // TODO: test out cross-domain stuff... :-(
        var topDomain = null;
        var parts = document.domain.split('.')
        if (parts.length == 1) {
            try {
                document.domain = document.domain
                parent.Orbited.singleton.HTMLFile.instances[id].streamClosed()
                return
            }
            catch(e) {
            }
        }
        else {
            for (var i = 0; i < parts.length-1; ++i) {
                document.domain = parts.slice(i).join(".")
                try {
                parent.Orbited.singleton.HTMLFile.instances[id].streamClosed()
                return
                }
                catch(e) {
        //            alert(e.name + ': ' + e.message)
                }
            }
        }
        if (topDomain == null) {
            throw new Error("Invalid document.domain for cross-frame communication")
        }
    }
}    
doClose();