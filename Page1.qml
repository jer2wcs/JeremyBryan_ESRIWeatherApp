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
import QtQuick 2.13
import QtQuick.Layouts 1.13
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.13
import QtGraphicalEffects 1.0
import QtPositioning 5.12
import QtSensors 5.12

import ArcGIS.AppFramework 1.0
import Esri.ArcGISRuntime 100.2

Item {
    id: mapPage

    signal next();
    signal back();

    function units(value) {
        return AppFramework.displayScaleFactor * value
    }

    property real scaleFactor: AppFramework.displayScaleFactor
    property int baseFontSize : app.info.propertyValue("baseFontSize", 15 * scaleFactor) + (isSmallScreen ? 0 : 3)
    property bool isSmallScreen: (width || height) < units(400)
    property string compassMode: "Compass"
    property string navigationMode: "Navigation"
    property string recenterMode: "Re-Center"
    property string onMode: "On"
    property string stopMode: "Stop"
    property string closeMode: "Close"
    property string currentModeText: stopMode
    property string currentModeImage:"assets/Stop.png"
    width: 421
    height: 750

    // App Page
    Page{
        width: 421
        height: 750
        font.weight: Font.Normal
        font.capitalization: Font.MixedCase
        anchors.fill: parent

        // Adding App Page Header Section
        header: ToolBar{
            id:header

            contentHeight: 56 * app.scaleFactor
            Material.primary: app.primaryColor
            RowLayout{
                anchors.fill: parent
                spacing:0
                Item{
                    Layout.preferredWidth: 4*app.scaleFactor
                    Layout.fillHeight: true
                }
                ToolButton {
                    indicator: Image{
                        width: parent.width*0.5
                        height: parent.height*0.5
                        anchors.centerIn: parent
                        source: "./assets/back.png"
                        fillMode: Image.PreserveAspectFit
                        mipmap: true
                    }
                    onClicked:{
                        // Go back previous page
                        back();
                    }
                }
                Item{
                    Layout.preferredWidth: 20*app.scaleFactor
                    Layout.fillHeight: true
                }
                Label {
                    Layout.fillWidth: true
                    text: qsTr("Current Location")
                    elide: Label.ElideRight
                    horizontalAlignment: Qt.AlignLeft
                    verticalAlignment: Qt.AlignVCenter
                    font.pixelSize: app.titleFontSize
                    color: app.headerTextColor
                }
            }
        }

        contentItem: Rectangle{
            anchors.top:header.bottom

            Component.onCompleted: {
                mapView.locationDisplay.autoPanMode = Enums.LocationDisplayAutoPanModeRecenter;
                mapView.locationDisplay.start();
            }

            // Create MapView that contains a Map
            MapView {
                id: mapView
                anchors.fill: parent

                Map {
                    BasemapImagery {}

                    // start the location display
                    onLoadStatusChanged: {
                        if (loadStatus === Enums.LoadStatusLoaded) {
                            // populate list model with modes
                            autoPanListModel.append({name: compassMode, image:"assets/Compass.png"});
                            autoPanListModel.append({name: navigationMode, image:"assets/Navigation.png"});
                            autoPanListModel.append({name: recenterMode, image:"assets/Re-Center.png"});
                            autoPanListModel.append({name: onMode, image:"assets/Stop.png"});
                            autoPanListModel.append({name: stopMode, image:"assets/Stop.png"});
                            autoPanListModel.append({name: closeMode, image:"assets/Close.png"});
                        }
                    }
                }

                //set the location display's position source
                locationDisplay {
                    positionSource: PositionSource {}
                    compass: Compass {}
                }
            }
        }

        Rectangle {
            id: rect
            width: 414
            height: 696
            anchors.fill: parent
            visible: autoPanListView.visible
            color: "black"
            opacity: 0.75
        }

        ListView {
            id: autoPanListView
            anchors {
                right: parent.right
                bottom: parent.bottom
                margins: 10 * scaleFactor
            }
            visible: false
            width: parent.width
            height: 300 * scaleFactor
            spacing: 10 * scaleFactor
            model: ListModel {
                id: autoPanListModel
            }

            delegate: Row {
                id: autopanRow
                anchors.right: parent.right
                spacing: 10

                Text {
                    text: name
                    font.pixelSize: 25 * scaleFactor
                    color: "white"
                    MouseArea {
                        anchors.fill: parent
                        // When an item in the list view is clicked
                        onClicked: {
                            autopanRow.updateAutoPanMode();
                        }
                    }
                }

                Image {
                    source: image
                    width: 40 * scaleFactor
                    height: width
                    MouseArea {
                        anchors.fill: parent
                        // When an item in the list view is clicked
                        onClicked: {
                            autopanRow.updateAutoPanMode();
                        }
                    }
                }

                // set the appropriate auto pan mode
                function updateAutoPanMode() {
                    switch (name) {
                    case compassMode:
                        mapView.locationDisplay.autoPanMode = Enums.LocationDisplayAutoPanModeCompassNavigation;
                        mapView.locationDisplay.start();
                        break;
                    case navigationMode:
                        mapView.locationDisplay.autoPanMode = Enums.LocationDisplayAutoPanModeNavigation;
                        mapView.locationDisplay.start();
                        break;
                    case recenterMode:
                        mapView.locationDisplay.autoPanMode = Enums.LocationDisplayAutoPanModeRecenter;
                        mapView.locationDisplay.start();
                        break;
                    case onMode:
                        mapView.locationDisplay.autoPanMode = Enums.LocationDisplayAutoPanModeOff;
                        mapView.locationDisplay.start();
                        break;
                    case stopMode:
                        mapView.locationDisplay.stop();
                        break;
                    }

                    if (name !== closeMode) {
                        currentModeText = name;
                        currentModeImage = image;
                    }

                    // hide the list view
                    currentAction.visible = true;
                    autoPanListView.visible = false;
                }
            }
        }

        Row {
            id: currentAction
            anchors {right: parent.right; bottom: parent.bottom; margins: 25 * scaleFactor}
            spacing: 10

            Text {
                text: currentModeText
                font.pixelSize: 25 * scaleFactor
                color: "white"
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        currentAction.visible = false;
                        autoPanListView.visible = false;
                    }
                }
            }

            Image {
                source: currentModeImage
                width: 40 * scaleFactor
                height: width
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        currentAction.visible = false;
                        autoPanListView.visible = true;
                    }
                }
            }
        }
    }
}
