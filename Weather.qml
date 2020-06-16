import QtQuick 2.12

Rectangle {
    width: 351
    height: 50
    radius: 10
    opacity: 0.9

    gradient: Gradient {
            GradientStop { position: 0.0; color: "grey" }
            GradientStop { position: 1.0; color: "black" }
    }

    Text{
        id: weatherDay
        x: 10
        y: 12
        color: "white"
        text: day
        font.pixelSize: 14
        font.bold: true
    }

    Text{
        id: weatherDescription
        x: 110
        y: 12
        color: "white"
        text: weather
        font.pixelSize: 14
    }

    Image {
        id: weatherImage
        x: 220
        y: 7
        width: 30
        height: 30

        source: "assets/icons/" + weatherDescription.text + ".png"
    }

    Text{
        id: weatherHigh
        x: 270
        y: 12
        color: "white"
        text: max
        font.pixelSize: 14
    }

    Text{
        id: weatherLow
        x: 315
        y: 12
        color: "white"
        text: min
        font.pixelSize: 14
    }
}
