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
import QtQuick 2.7
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
    property var unitsAreImperial: true

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
                    //
                    // we have good data, cache it for future use
                    //
                    fileFolder.writeTextFile("cachedWeatherData.json", JSON.stringify(parsedWeather))

                    currentTempLabel.text = qsTr(temperatureToString(parsedWeather.current.temp))
                    var weatherString = getWeatherStringForIcon(parsedWeather.current.weather[0].id)
                    descriptionLabel.text = qsTr(weatherString)
                    weatherPage.conditionIndex = getConditionIndex(weatherString)
                    var nextIndex = (4 * weatherPage.conditionIndex) + getRandomInt(0, 4)
                    //console.log("Image1 is now: " + weatherPage.backgroundImages[nextIndex])
                    image1.source = weatherPage.backgroundImages[nextIndex]
                    image1Timer.restart()
                    weatherDataStatus.source = "assets/live.png"
                    //
                    // because we are online, turn on MouseArea for selectedUnits
                    //
                    selectedUnitsMouseArea.enabled = true
                    for (var ii = 0; ii < 7; ii++) {
                        var dailyWeatherString = getWeatherStringForIcon(parsedWeather.daily[ii].weather[0].id)
                        weatherModel.setProperty(ii, "day", timpestampToDay(parsedWeather.daily[ii].dt))
                        weatherModel.setProperty(ii, "max", temperatureToString(parsedWeather.daily[ii].temp.max))
                        weatherModel.setProperty(ii, "min", temperatureToString(parsedWeather.daily[ii].temp.min))
                        weatherModel.setProperty(ii, "weather", dailyWeatherString)
                    }
                } else {
                    if (parsedWeather && parsedWeather.message) {
                        //
                        // received a response, but the server reported the request was not successful
                        //
                        console.log("|------------------------------------------------|")
                        console.log("UNSUCCESSFUL REQUEST --> " + parsedWeather.message)
                        console.log("|------------------------------------------------|")
                    } else {
                        //
                        // no response
                        //
                        console.log("|------------------------------------------------|")
                        console.log("NETWORK ERROR --> " + doc.status + " / " + doc.text)
                        console.log("|------------------------------------------------|")
                    }

                    //
                    // load cached data
                    //
                    var cachedWeather = JSON.parse(fileFolder.readTextFile("cachedWeatherData.json"))

                    if (cachedWeather) {
                        currentTempLabel.text = qsTr(temperatureToString(cachedWeather.current.temp))
                        var cachedWeatherString = getWeatherStringForIcon(cachedWeather.current.weather[0].id)
                        descriptionLabel.text = qsTr(cachedWeatherString)
                        weatherPage.conditionIndex = getConditionIndex(cachedWeatherString)
                        var cachedNextIndex = (4 * weatherPage.conditionIndex) + getRandomInt(0, 4)
                        image1.source = weatherPage.backgroundImages[cachedNextIndex]
                        image1Timer.restart()
                        weatherDataStatus.source = "assets/notlive.png"
                        //
                        // because we are offline, turn off MouseArea for selectedUnits
                        //
                        selectedUnitsMouseArea.enabled = false
                        for (var jj = 0; jj < 7; jj++) {
                            var dailyCachedWeatherString = getWeatherStringForIcon(cachedWeather.daily[jj].weather[0].id)
                            weatherModel.setProperty(jj, "day", timpestampToDay(cachedWeather.daily[jj].dt))
                            weatherModel.setProperty(jj, "max", temperatureToString(cachedWeather.daily[jj].temp.max))
                            weatherModel.setProperty(jj, "min", temperatureToString(cachedWeather.daily[jj].temp.min))
                            weatherModel.setProperty(jj, "weather", dailyCachedWeatherString)
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
        //return Math.round(temp) + "°"
        return Math.round(temp) + ""
    }

    function getWeather(lat, lon, units) {
        const url = `${Constants.baseUrl}/data/2.5/onecall?exclude=minutely,hourly&units=${units}&lon=${lon}&lat=${lat}&appid=${Constants.appid}`;
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

    function getRandomInt(min, max) {
      min = Math.ceil(min);
      max = Math.floor(max);
      return Math.floor(Math.random() * (max - min)) + min; //The maximum is exclusive and the minimum is inclusive
    }

    function getUnitsString() {
        if (unitsAreImperial)
            return "imperial"
        return "metric"
    }

    function getConditionIndex(condition) {
        switch (condition) {
            case "clear sky":
                return 0;
            case "cloudy":
                return 1;
            case "thunderstorm":
                return 2;
            case "drizzle":
                return 3;
            case "rain":
                return 4;
            case "snow":
                return 5;
            case "mist":
                return 6;
        }
    }

    FileFolder {
        id: fileFolder
        path: app.folder.path
    }

    //
    // App Page
    //
    Page {
        id: weatherPage
        x: 0
        anchors.fill: parent

        property var backgroundImages: [
            "./assets/Backgrounds/ClearSky1.png",
            "./assets/Backgrounds/ClearSky2.png",
            "./assets/Backgrounds/ClearSky3.png",
            "./assets/Backgrounds/ClearSky4.png",
            "./assets/Backgrounds/Cloudy1.png",
            "./assets/Backgrounds/Cloudy2.png",
            "./assets/Backgrounds/Cloudy3.png",
            "./assets/Backgrounds/Cloudy4.png",
            "./assets/Backgrounds/Thunderstorm1.png",
            "./assets/Backgrounds/Thunderstorm2.png",
            "./assets/Backgrounds/Thunderstorm3.png",
            "./assets/Backgrounds/Thunderstorm4.png",
            "./assets/Backgrounds/Drizzle1.png",
            "./assets/Backgrounds/Drizzle2.png",
            "./assets/Backgrounds/Drizzle3.png",
            "./assets/Backgrounds/Drizzle4.png",
            "./assets/Backgrounds/Rain1.png",
            "./assets/Backgrounds/Rain2.png",
            "./assets/Backgrounds/Rain3.png",
            "./assets/Backgrounds/Rain4.png",
            "./assets/Backgrounds/Snow1.png",
            "./assets/Backgrounds/Snow2.png",
            "./assets/Backgrounds/Snow3.png",
            "./assets/Backgrounds/Snow4.png",
            "./assets/Backgrounds/Mist1.png",
            "./assets/Backgrounds/Mist2.png",
            "./assets/Backgrounds/Mist3.png",
            "./assets/Backgrounds/Mist4.png"
        ]

        property var conditionIndex: 0

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
                var unitString = getUnitsString()

                if (coord.isValid) {
                    getWeather (coord.latitude, coord.longitude, unitString)
                    getCity (coord.latitude, coord.longitude)
                    image1Move.start()
                    image1Timer.start()

                }
            }
        }

        Image {
            id: image1
            width: 842
            height: 1500
            opacity: 1
            //source: "./assets/Backgrounds/startBackground.png"
            SequentialAnimation on x {
                id: image1Move
                loops: 1
                running: true
                PropertyAnimation {
                    from: -400
                    to: -200
                    duration: 15000
                }
            }
            NumberAnimation on opacity {
                id: image1FadeIn
                from: 0
                to: 1
                duration: 2000
                running: false
            }
            NumberAnimation on opacity {
                id: image1FadeOut
                from: 1
                to: 0
                duration: 2000
                running: false
            }

            Timer {
                id: image1Timer
                interval: 13000
                running: false
                repeat: false

                onTriggered: {
                    image1FadeOut.start()
                    var randomInt = getRandomInt(0, 4)
                    var nextIndex = (4 * weatherPage.conditionIndex) + randomInt
                    image2.source = weatherPage.backgroundImages[nextIndex]
                    image2FadeIn.start()
                    image2Move.start()
                    image2Timer.start()
                }
            }
        }

        Image {
            id: image2
            width: 842
            height: 1500
            opacity: 0
            //source: "./assets/Backgrounds/startBackground.png"
            SequentialAnimation on x {
                id: image2Move
                loops: 1
                running: false
                PropertyAnimation {
                    from: -200
                    to: -400
                    duration: 15000
                }
            }
            NumberAnimation on opacity {
                id: image2FadeIn
                from: 0
                to: 1
                duration: 2000
                running: false
            }
            NumberAnimation on opacity {
                id: image2FadeOut
                from: 1
                to: 0
                duration: 2000
                running: false
            }
            Timer {
                id: image2Timer
                interval: 13000
                running: false
                repeat: false

                onTriggered: {
                    image2FadeOut.start()
                    var randomInt = getRandomInt(0, 4)
                    var nextIndex = (4 * weatherPage.conditionIndex) + randomInt
                    image1.source = weatherPage.backgroundImages[nextIndex]
                    image1FadeIn.start()
                    image1Move.start()
                    image1Timer.start()
                }
            }
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

            Text {
                id: degreeSymbol
                text: "°"
                anchors.top: parent.top
                anchors.left: parent.right
                font.weight: Font.ExtraBold
                font.pointSize: 50
                font.bold: true
                verticalAlignment: Text.AlignBottom
                horizontalAlignment: Text.AlignHCenter
                style: Text.Outline
                styleColor: "white"
            }
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
            height: 435
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
            interactive: false

            model: weatherModel
            header: headerDelegate
            delegate: weatherDelegate
        }

        Image {
            id: weatherDataStatus
            x: 40
            y: 700
            source: "assets/notlive.png"
        }

        Image {
            id: selectedUnits
            x: 325
            y: 700
            source: "assets/imperial.png"
            MouseArea {
                id: selectedUnitsMouseArea
                anchors.fill: parent
                onClicked: {
                    unitsAreImperial = !unitsAreImperial
                    var unitString = getUnitsString()
                    selectedUnits.source = "assets/" + unitString + ".png"
                    var coord = positionSource.position.coordinate;
                    if (coord.isValid) {
                        getWeather (coord.latitude, coord.longitude, unitString)
                    }
                }
            }
        }
    }
}
