import QtQuick 2.12

Rectangle {
    width: 351
    height: 20
    color: "transparent"
    x: 0
    y: -3

    Text {
        id: headerDay
        width: parent.width
        height: 20
        x: 10
        y: 0

        text: "Day"
        font.pixelSize: 14
        font.bold: true
        color: "white"
    }

    Text {
        id: headerForcast
        width: parent.width
        height: 20
        x: 125
        y: 0

        text: "Forcast"
        font.pixelSize: 14
        font.bold: true
        color: "white"
    }

    Text {
        id: headerHigh
        width: parent.width
        height: 20
        x: 250
        y: 0

        text: "High"
        font.pixelSize: 14
        font.bold: true
        color: "white"
    }

    Text {
        id: headerLow
        width: parent.width
        height: 20
        x: 300
        y: 0

        text: "Low"
        font.pixelSize: 14
        font.bold: true
        color: "white"
    }
}
