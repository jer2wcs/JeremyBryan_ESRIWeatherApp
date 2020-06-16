/* Copyright 2020 Esri
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */
import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12
import QtPositioning 5.12
import QtLocation 5.12
import QtGraphicalEffects 1.0

import Esri.ArcGISRuntime 100.7
import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Networking 1.0

import "MyConstants.js" as Constants

Item {
    signal next();
    signal back();

    width: 421
    height: 750

    property var weatherModel: WeatherModel {}

    function getCityJSON(url) {
        var doc = new XMLHttpRequest();

        doc.onreadystatechange = function () {
            if (doc.readyState === XMLHttpRequest.DONE) {

                var parsedAddress = doc.responseText ? JSON.parse(doc.responseText) : null

                if (parsedAddress && doc.status === 200) {
                    locationButton.text = qsTr(parsedAddress.results[0].locations[0].adminArea5)
                }
            }

        }

        //console.log("|------------------------------------------------|")
        //console.log("Query URL: " + url)
        //console.log("|------------------------------------------------|")
        doc.open("GET", url);
        doc.setRequestHeader('Accept', 'application/json');
        doc.send();
    }

    function getWeatherJSON(url) {

        var doc = new XMLHttpRequest();

        doc.onreadystatechange = function () {
            if (doc.readyState === XMLHttpRequest.DONE) {

                var parsedWeather = doc.responseText ? JSON.parse(doc.responseText) : null

                if (parsedWeather && doc.status === 200) {
                    // cache this weather data
                    fileFolder.writeTextFile("cachedWeatherData.json", JSON.stringify(parsedWeather))
                    currentTempLabel.text = qsTr(temperatureToString(parsedWeather.current.temp))
                    var weatherString = getWeatherStringForIcon(parsedWeather.current.weather[0].id)
                    descriptionLabel.text = qsTr(weatherString)

                    weatherDataStatus.text = "LIVE"
                    for (var ii = 0; ii < 7; ii++) {
                        weatherModel.setProperty(ii, "day", timpestampToDay(parsedWeather.daily[ii].dt))
                        weatherModel.setProperty(ii, "max", temperatureToString(parsedWeather.daily[ii].temp.max))
                        weatherModel.setProperty(ii, "min", temperatureToString(parsedWeather.daily[ii].temp.min))
                        weatherModel.setProperty(ii, "weather", weatherString)
                    }
                } else {
                    if (parsedWeather && parsedWeather.message) {
                        // received a response, but the server reported the request was not successful
                        console.log("|------------------------------------------------|")
                        console.log("UNSUCCESSFUL REQUEST --> " + parsedWeather.message)
                        console.log("|------------------------------------------------|")
                    } else {
                        // no response
                        console.log("|------------------------------------------------|")
                        console.log("NETWORK ERROR --> " + doc.status + " / " + doc.text)
                        console.log("|------------------------------------------------|")
                    }

                    // load cached data
                    var cachedWeather = JSON.parse(fileFolder.readTextFile("cachedWeatherData.json"))

                    if (cachedWeather) {
                        currentTempLabel.text = qsTr(temperatureToString(cachedWeather.current.temp))
                        locationButton.text = qsTr(cachedWeather.timezone)
                        var cachedWeatherString = getWeatherStringForIcon(cachedWeather.current.weather[0].id)
                        descriptionLabel.text = qsTr(cachedWeatherString)
                        weatherDataStatus.text = "CACHED"
                        for (var jj = 0; jj < 7; jj++) {
                            weatherModel.setProperty(jj, "day", timpestampToDay(cachedWeather.daily[jj].dt))
                            weatherModel.setProperty(jj, "max", temperatureToString(cachedWeather.daily[jj].temp.max))
                            weatherModel.setProperty(jj, "min", temperatureToString(cachedWeather.daily[jj].temp.min))
                            weatherModel.setProperty(jj, "weather", cachedWeatherString)
                        }
                    }
                }

            }
        }

        //console.log("|------------------------------------------------|")
        //console.log("Query URL: " + url)
        //console.log("|------------------------------------------------|")
        doc.open("GET", url);
        doc.setRequestHeader('Accept', 'application/json');
        doc.send();
    }

    function getWeatherStringForIcon(weatherId) {
        if (weatherId >= 200 && weatherId < 300)
            return "thunderstorm"
        if (weatherId >= 300 && weatherId < 400)
            return "drizzle"
        if (weatherId >= 500 && weatherId < 600)
            return "rain"
        if (weatherId >= 600 && weatherId < 700)
            return "snow"
        if (weatherId >= 700 && weatherId < 800)
            return "mist"
        if (weatherId === 800)
            return "clear sky"
        if (weatherId >= 801 && weatherId < 900)
            return "cloudy"
    }

    function temperatureToString(temp)
    {
        return Math.round(temp) + "°"
    }

    function getWeather(lat, lon) {
        //const url = `${Constants.baseUrl}/data/2.5/weather?units=imperial&lon=${lon}&lat=${lat}&appid=${Constants.appid}`;
        const url = `${Constants.baseUrl}/data/2.5/onecall?exclude=minutely,hourly&units=imperial&lon=${lon}&lat=${lat}&appid=${Constants.appid}`;
        return getWeatherJSON(url)
    }

    function timpestampToDay(timestamp)
    {
        let d = new Date(timestamp * 1000)
        return d.toLocaleDateString(Qt.locale(), "dddd")
    }

    function getCity(lat, lon) {
        const url = `${Constants.mapquestUrl}/geocoding/v1/reverse?key=${Constants.mapquestAppid}&location=${lat},${lon}`;
        return getCityJSON(url)
    }

    FileFolder {
        id: fileFolder
        path: app.folder.path
    }

    // App Page
    Page{
        id: page
        x: 0
        anchors.fill: parent

        Component.onCompleted: {
            positionSource.start()
        }

        PositionSource {
            id: positionSource
            updateInterval: 1000
            active: true

            onPositionChanged: {
                stop()
                var coord = positionSource.position.coordinate;
                //console.log("|------------------------------------------------|")
                //console.log("ON POSITION CHANGED: Coordinate: " + coord)
                //console.log("|------------------------------------------------|")
                if (coord.isValid) {
                    getWeather (coord.latitude, coord.longitude)
                    getCity (coord.latitude, coord.longitude)
                }
            }
        }

        background: BorderImage {
            id: backgroundImage
            source: "./assets/ClearSkyBackground.png"
            width: 421
            height: 750
            //border {left: 5; top: 5; right: 5; bottom: 5}
        }

        Text {
            id: locationButton
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            y: 21
            font.bold: true
            font.pixelSize: 32
            color: "white"
            style: Text.Outline
            styleColor: "black"

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                onClicked: {
                    next()
                }
            }
        }

        Text {
            id: dateText
            y: 35
            width: parent.width
            height: 25
            color: "white"
            text: Qt.formatDateTime(new Date(), "dddd, MMMM dd")
            font.bold: true
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: 20
            style: Text.Outline
            styleColor: "black"
        }

        Text {
            id: currentTempLabel
            x: 122
            y: 60
            text: ""
            anchors.horizontalCenter: parent.horizontalCenter
            font.weight: Font.ExtraBold
            font.pointSize: 100
            font.bold: true
            verticalAlignment: Text.AlignTop
            horizontalAlignment: Text.AlignHCenter
            style: Text.Outline
            styleColor: "white"
        }

        Text {
            id: descriptionLabel
            x: 91
            y: 210
            anchors.horizontalCenter: parent.horizontalCenter
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            color: "white"
            font.pointSize: 32
            font.bold: true
            style: Text.Outline
            styleColor: "black"
        }

        DropShadow {
            anchors.fill: currentTempLabel
            horizontalOffset: 5
            verticalOffset: 5
            radius: 6
            samples: 17
            color: "#80000000"
            source: currentTempLabel
        }

        Glow {
            anchors.fill: currentTempLabel
            radius: 10
            samples: 17
            color: "steelBlue"
            source: currentTempLabel
        }

        Rectangle {
            id: listViewBackground
            width: 371
            height: 425
            x: 25
            y:290

            color: "black"
            opacity: 0.6
            radius: 20
        }

        Component {
            id: headerDelegate

            Loader {
                source: "WeatherHeader.qml"
            }
        }

        Component {
            id: weatherDelegate

            Loader {
                source: "Weather.qml"
            }
        }

        ListView {
            id: weatherListView
            x: 35
            y: 300
            width: 400
            height: 500
            spacing: 5

            model: weatherModel
            header: headerDelegate
            delegate: weatherDelegate
        }

        Text {
            id: weatherDataStatus
            x: 40
            y: 700

            text: "Communicating with server..."
            font.pixelSize: 10
            color: "white"
        }
    }
}
