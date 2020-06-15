.import "sdk.js" as SDK

// fill in openweather appid
const appid = 'a9ecff1cd70b31de1ed37a0e50e771c3'
const baseUrl = 'http://api.openweathermap.org'
const city = 'Ontario'
const state = 'CA'

if (!appid)  {
    throw new Error("missing proper weather api configuration")
}

function getIconUrl(id)
{
    return `http://openweathermap.org/img/w/${id}.png`;
}

//function getForecast(lat, lon){
function getForecast() {
    const url = `${baseUrl}/data/2.5/weather?units=imperial&q=${city},${state}&appid=${appid}`;
    return SDK.getJSON(url)
}
