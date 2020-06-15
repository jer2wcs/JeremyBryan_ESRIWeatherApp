.pragma library

function showRequestInfo(text) {
    console.log(text)
}

function getJSON(url) {

    var doc = new XMLHttpRequest();
    doc.onreadystatechange = function () {
        if (doc.readyState === XMLHttpRequest.HEADERS_RECEIVED) {
            showRequestInfo("Headers -->");
            showRequestInfo(doc.getAllResponseHeaders());
            showRequestInfo("Last modified -->")
            showRequestInfo(doc.getResponseHeader ("Last-Modified"));
        } else if (doc.readyState === XMLHttpRequest.DONE) {
            var json = JSON.parse(doc.responseText.toString());
            showRequestInfo("Headers -->");
            showRequestInfo(doc.getAllResponseHeaders());
            showRequestInfo("Last modified -->")
            showRequestInfo(doc.getResponseHeader ("Last-Modified"));
            showRequestInfo("Response Text -->")
            showRequestInfo(doc.responseText.toString());
        }
    }

    console.log("|------------------------------------------------|")
    console.log("Query URL: " + url)
    console.log("|------------------------------------------------|")
    doc.open("GET", url);
    doc.setRequestHeader('Accept', 'application/json');
    doc.send();

//    return new Promise((resolve, reject) => {
//                           const xhr = new XMLHttpRequest();

//                           xhr.onreadystatechange = () => {
//                               if (xhr.readyState === XMLHttpRequest.DONE) {
//                                   const { status, responseText } = xhr
//                                   if(status === 200) {
//                                       resolve(JSON.parse(responseText))
//                                   }
//                                   else {
//                                       reject({ code: status, msg: responseText })
//                                   }
//                               };
//                           }

//                           console.log("|------------------------------------------------|")
//                           console.log("Query URL: " + url)
//                           console.log("|------------------------------------------------|")
//                           xhr.open("GET", url)
//                           xhr.setRequestHeader('Accept', 'application/json');
//                           xhr.send()
//                       })
}

function timpestampToDay(timestamp)
{
    let d = new Date(timestamp * 1000)
    return d.toLocaleDateString(Qt.locale(), "ddd")
}

function temperatureToString(temp)
{
    return Math.round(temp) + "°C"
}
