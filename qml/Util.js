
.pragma library

function getDurationString(d) {
    if(typeof d === 'string' || d instanceof String) {
        // probably: hh:mm:ss.xxx
        var a = d.split(':');
        if(a.length !== 3)
            return d;
        if(parseInt(a[0])>0)
            return a[0]+":"+a[1]+":"+secondsString(Math.round(parseInt(a[2])));
        else
            return a[1]+":"+secondsString(Math.round(parseInt(a[2])));
    } else {
      // assume ms
      d /= 1000;
      var minutes = Math.floor(d / 60);
      var seconds = "0" + (d - minutes * 60);
      return minutes + ":" + seconds.substr(-2);
    }
}

function createItemsString(items, noneString) {
    if(items.length === 0)
        return noneString
    var i
    var str = ""
    for(i=0;i<items.length;i++) {
        if(i>0)
            str += ", "
        if(items[i].name)
            str += items[i].name
        else
            str += items[i]
    }
    return str
}
