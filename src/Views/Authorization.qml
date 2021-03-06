import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.0
import "../Controls"

Page {
    id: authorizePage
    anchors.fill: parent
    background: Rectangle {
        color: "#D3D3D3"
    }

    property alias email: emailTextBox.text
    property alias password: passwordTextBox.text
    property alias fa2code: fa2codeTextBox.text

    signal navigateFrom()
    signal navigateTo()
    signal authentificateFailed(string message)

    onNavigateFrom: {
        emailTextBox.text = "";
        passwordTextBox.text = "";
        fa2codeTextBox.text = "";
    }

    onAuthentificateFailed: {
        errorMessage.text = message;
    }

    RowLayout {
        id: panelContainer
        anchors.fill: parent
        spacing: 0
        Rectangle {
            color: "#9e2323"
            width: 40
            Layout.fillHeight: true
            Column {
                IconButton {
                    height: 45
                    width: 40
                    iconColor: "white"
                    iconPath: "../Assets/Icons/menu.svg"
                    iconWidth: 29
                    iconHeight: 29
                    onButtonPressed: {
                        drawer.open();
                    }
                }
            }
        }
        Rectangle {
            color: "#D3D3D3"
            Layout.fillHeight: true
            Layout.fillWidth: true

            Rectangle {
                id: fieldsContainer
                radius: 8
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                width: 400
                height: 280

                ColumnLayout {
                    id: authForm
                    anchors.fill: parent
                    anchors.margins: 8
                    TextField {
                        id: emailTextBox
                        Layout.fillWidth: true
                        placeholderText: "Логин"
                    }
                    TextField {
                        id: passwordTextBox
                        Layout.fillWidth: true
                        echoMode: "PasswordEchoOnEdit"
                        placeholderText: "Пароль"
                    }
                    TextField {
                        id: fa2codeTextBox
                        Layout.fillWidth: true
                        placeholderText: "2fa код (оставить пустым если не настроено)"
                    }
                    Item {
                        Layout.fillWidth: true
                        height: 40
                        Text {
                            id: errorMessage
                            text: ""
                            font.pointSize: 10 + windowSettings.dpiSeparation
                            anchors.left: parent.left
                            anchors.leftMargin: 10                            
                            anchors.verticalCenter: parent.verticalCenter
                            color: "#a32727"
                            wrapMode: Text.WordWrap
                        }

                        RoundedActionButton {
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            text: qsTr("Войти")
                            onClicked: {
                                errorMessage.text = "";

                                if (emailTextBox.text === "") {
                                    errorMessage.text = "Поле Логин обязательное";
                                    return;
                                }
                                if (passwordTextBox.text === "") {
                                    errorMessage.text = "Поле Пароль обязательное";
                                    return;
                                }

                                synchronizationService.authorize(encodeURIComponent(authorizePage.email), encodeURIComponent(authorizePage.password), encodeURIComponent(authorizePage.fa2code));
                            }
                        }

                    }

                }
            }

            Text {
                anchors.top: fieldsContainer.bottom
                anchors.right: fieldsContainer.right
                linkColor: "#b32121"
                font.pointSize: 10 + windowSettings.dpiSeparation
                text: "<a href='https://www.anilibria.tv/pages/login.php'>Регистрация</a>"
                onLinkActivated: {
                    Qt.openUrlExternally(link);
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                }

            }
        }
    }

}
