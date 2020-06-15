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

    function getJSON(url) {

        var doc = new XMLHttpRequest();

        doc.onreadystatechange = function () {
            if (doc.readyState === XMLHttpRequest.HEADERS_RECEIVED) {
                console.log("Headers -->");
                console.log(doc.getAllResponseHeaders());
                console.log("Last modified -->")
                console.log(doc.getResponseHeader ("Last-Modified"));
            } else if (doc.readyState === XMLHttpRequest.DONE) {
                var jsonObject = JSON.parse(doc.responseText);
                currentTempLabel.text = qsTr(temperatureToString(jsonObject.current.temp))
                locationButton.text = qsTr(jsonObject.timezone)
                descriptionLabel.text = qsTr(jsonObject.current.weather[0].description)
                for (var ii = 0; ii < 7; ii++) {
                    //console.log("|------------------------------------------------|")
                    //console.log("Weather temp --> " + temperatureToString(jsonObject.daily[ii].temp.max))
                    //console.log("|------------------------------------------------|")
                    weatherModel.setProperty(ii, "day", timpestampToDay(jsonObject.daily[ii].dt))
                    weatherModel.setProperty(ii, "max", temperatureToString(jsonObject.daily[ii].temp.max))
                    weatherModel.setProperty(ii, "min", temperatureToString(jsonObject.daily[ii].temp.min))
                    weatherModel.setProperty(ii, "weather", jsonObject.daily[ii].weather[0].description)
                }

                //console.log("|------------------------------------------------|")
                //console.log("JSON Object --> " + jsonObject.current.weather[0].description)
                //console.log("|------------------------------------------------|")
                //weatherModel.setProperty(0, "day", "today")
                //weatherModel.setProperty(0, "weather", jsonObject.main.temp)
                //console.log("|------------------------------------------------|")
                //console.log("Response Text --> " + doc.responseText.toString())
                //console.log("Headers -->");
                //console.log(doc.getAllResponseHeaders());
                //console.log("Last modified -->")
                //console.log(doc.getResponseHeader ("Last-Modified"));
            }
        }

        console.log("|------------------------------------------------|")
        console.log("Query URL: " + url)
        console.log("|------------------------------------------------|")
        doc.open("GET", url);
        doc.setRequestHeader('Accept', 'application/json');
        doc.send();
    }

    function temperatureToString(temp)
    {
        return Math.round(temp) + "°"
    }

    function getWeather(lat, lon) {
        //const url = `${Constants.baseUrl}/data/2.5/weather?units=imperial&lon=${lon}&lat=${lat}&appid=${Constants.appid}`;
        const url = `${Constants.baseUrl}/data/2.5/onecall?exclude=minutely,hourly&units=imperial&lon=${lon}&lat=${lat}&appid=${Constants.appid}`;
        return getJSON(url)
    }

    function timpestampToDay(timestamp)
    {
        let d = new Date(timestamp * 1000)
        return d.toLocaleDateString(Qt.locale(), "dddd")
    }

    // App Page
    Page{
        id: page
        x: 0
        anchors.fill: parent

        Component.onCompleted: {
            positionSource.start()
            console.log("|------------------------------------------------|")
            Networking.isOnline ? console.log("ONLINE") : console.log("OFFLINE")
            console.log("|------------------------------------------------|")
        }

        PositionSource {
            id: positionSource
            updateInterval: 1000
            active: true

            onPositionChanged: {
                stop()
                var coord = positionSource.position.coordinate;
                console.log("|------------------------------------------------|")
                console.log("ON POSITION CHANGED: Coordinate: " + coord)
                console.log("|------------------------------------------------|")
                if (coord.isValid) {
                    getWeather (coord.latitude, coord.longitude)
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
            id: dateText
            y: 5
            width: parent.width
            height: 25
            text: Qt.formatDateTime(new Date(), "dddd, MMMM dd")
            font.bold: true
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: 16
        }

        Label {
            id: currentTempLabel
            x: 122
            y: 25
            text: ""
            anchors.horizontalCenter: parent.horizontalCenter
            font.weight: Font.ExtraBold
            font.pointSize: 100
            font.bold: true
            verticalAlignment: Text.AlignTop
            horizontalAlignment: Text.AlignHCenter
        }

        Label {
            id: descriptionLabel
            x: 91
                y: 175
                anchors.horizontalCenter: parent.horizontalCenter
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                font.pointSize: 24
                font.bold: true
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
            y:240

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
            y: 250
            width: 400
            height: 500
            spacing: 5

            model: weatherModel
            header: headerDelegate
            delegate: weatherDelegate
        }

        header: ToolBar {
            id:header
            contentHeight: 56 * app.scaleFactor
            Material.primary: app.primaryColor

            RowLayout{
                anchors.fill: parent
                spacing:0
                Item{
                    Layout.preferredWidth: 16 * app.scaleFactor
                    Layout.fillHeight: true
                }

                Button {
                    id: locationButton
                    x: 522
                    y: 21
                    focusPolicy: Qt.NoFocus
                    font.bold: true
                    flat: true
                    display: AbstractButton.TextOnly
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.rowSpan: 1
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    onClicked: next()
                }
            }
        }
    }
}
