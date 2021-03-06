import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.3
import QtWebView 1.1
import QtQuick.Controls.Styles 1.4
import QtQuick.Dialogs 1.2
import QtGraphicalEffects 1.0
import Anilibria.Services 1.0
import "../Controls"

Page {
    id: page
    property bool selectMode
    property var selectedReleases: []
    property var displayedReleases: []
    property var favoriteReleases: []
    property var scheduledReleases: ({})
    property int pageIndex: 1
    property bool isBusy: false
    property var openedRelease: null
    property bool runRefreshFavorties: false
    property bool synchronizeEnabled: false
    property int selectedSection: 0
    property var seenMarks: ({})
    property var sections: [
        "Все релизы",
        "Избранное",
        "Новые релизы",
        "Релизы с новыми сериями",
        "Релизы с новыми торрентами",
        "Расписание",
        "Релизы с обновленными торрентами",
        "История",
        "История просмотра",
        "Просмотренные",
        "Просматриваемые",
        "Не просмотренные"
    ]
    property var sectionSortings: {
        0: { field: 0, direction: 1 },
        1: { field: 0, direction: 1 },
        2: { field: 0, direction: 1 },
        3: { field: 0, direction: 1 },
        4: { field: 0, direction: 1 },
        5: { field: 1, direction: 0 },
        6: { field: 0, direction: 1 },
        7: { field: 7, direction: 1 },
        8: { field: 8, direction: 1 },
        9: { field: 0, direction: 1 },
        10: { field: 0, direction: 1 },
        11: { field: 0, direction: 1 }
    }
    property var changesCounts: []

    signal navigateFrom()
    signal watchRelease(int releaseId, string videos, int startSeria)
    signal refreshReleases()
    signal refreshFavorites()
    signal refreshReleaseSchedules()
    signal requestSynchronizeReleases()
    signal navigateTo()

    onWidthChanged: {
        const columnCount = parseInt(page.width / 520);
        itemGrid.columns = columnCount < 1 ? 1 : columnCount;
    }

    onRefreshReleases: {
        refreshAllReleases(false);
    }

    onRefreshReleaseSchedules: {
        refreshSchedule();
    }

    onRefreshFavorites: {
        page.favoriteReleases = localStorage.getFavorites().map(a => a);
    }

    onNavigateTo: {
        refreshSeenMarks();
        refreshAllReleases(true);
    }

    background: Rectangle {
        color: "#D3D3D3"
    }

    anchors.fill: parent

    ListModel {
        id: releasesModel
    }

    ListModel {
        id: torrentsModel
    }

    Rectangle {
        id: mask
        width: 180
        height: 260
        radius: 10
        visible: false
    }

    Rectangle {
        id: cardMask
        width: 180
        height: 260
        radius: 6
        visible: false
    }

    RowLayout {
        id: panelContainer
        anchors.fill: parent
        spacing: 0
        enabled: !page.openedRelease
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
                IconButton {
                    height: 45
                    width: 40
                    iconColor: "white"
                    iconPath: "../Assets/Icons/refresh.svg"
                    iconWidth: 34
                    iconHeight: 34
                    onButtonPressed: {
                        if (page.synchronizeEnabled) return;

                        page.requestSynchronizeReleases();
                    }
                }
                IconButton {
                    id: favoriteMenuButton
                    height: 45
                    width: 40
                    iconColor: "white"
                    iconPath: "../Assets/Icons/favorite.svg"
                    iconWidth: 29
                    iconHeight: 29
                    onButtonPressed: {
                        if (!page.selectedReleases.length) {
                            favoritePopupHeader.text = "Избранное не доступно";
                            favoritePopupMessage.text = "Выберите релизы в списке путем изменения переключателя выше списка на множественный режим и нажатием ЛКМ на интересующих релизах в списке. Выбранные релизы подсвечиваются красной рамкой.";
                            messagePopup.open();
                            return;
                        }

                        if (!window.userModel.login) {
                            favoritePopupHeader.text = "Избранное не доступно";
                            favoritePopupMessage.text = "Чтобы добавлять в избранное нужно вначале авторизоваться. Для этого перейдите на страницу Войти в меню и войдите под данными своего аккаунта. Если вы не зарегистрированы то необходимо сделать это на сайте, ссылка на сайт будет на странице Войти.";
                            messagePopup.open();
                            return;
                        }

                        favoriteMenu.open();
                    }

                    Menu {
                        id: favoriteMenu
                        y: favoriteMenuButton.height
                        width: 350

                        CommonMenuItem {
                            text: "Добавить в избранное"
                            onPressed: {
                                synchronizationService.addUserFavorites(applicationSettings.userToken, page.selectedReleases.join(','));
                                page.selectedReleases = [];
                            }
                        }
                        CommonMenuItem {
                            text: "Удалить из избранного"
                            onPressed: {
                                synchronizationService.removeUserFavorites(applicationSettings.userToken, page.selectedReleases.join(','));
                                page.selectedReleases = [];
                            }
                        }
                    }

                    Popup {
                        id: messagePopup
                        x: window.width / 2 - 225
                        y: window.height / 2 - 100
                        width: 450
                        height: 150
                        modal: true
                        focus: true
                        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

                        Column {
                            width: parent.width
                            spacing: 10
                            Text {
                                id: favoritePopupHeader
                                width: messagePopup.width - 20
                                font.pointSize: 12 + windowSettings.dpiSeparation
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            Rectangle {
                                width: messagePopup.width - 20
                                height: messagePopup.height - 50
                                Text {
                                    id: favoritePopupMessage
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width
                                    font.pointSize: 10 + windowSettings.dpiSeparation
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }
                    }
                }
                IconButton {
                    id: seenMarkMenuPanelButton
                    height: 45
                    width: 40
                    iconColor: "white"
                    iconPath: "../Assets/Icons/seenmarkpanel.svg"
                    iconWidth: 29
                    iconHeight: 29
                    onButtonPressed: {
                        seenMarkMenuPanel.open();
                    }

                    Menu {
                        id: seenMarkMenuPanel
                        y: seenMarkMenuPanelButton.height
                        width: 300

                        CommonMenuItem {
                            text: "Отметить как просмотренное"
                            enabled: page.selectedReleases.length
                            onPressed: {
                                setSeenStateForRelease(true, page.selectedReleases);
                            }
                        }
                        CommonMenuItem {
                            text: "Отметить как не просмотренное"
                            enabled: page.selectedReleases.length
                            onPressed: {
                                setSeenStateForRelease(false, page.selectedReleases);
                            }
                        }
                        CommonMenuItem {
                            text: "Удалить все отметки о просмотре"
                            onPressed: {
                                seenMarkMenuPanel.close();
                                removeAllSeenMark.open();
                            }
                        }
                    }

                    MessageModal {
                        id: removeAllSeenMark
                        header: "Удаление признаков просмотра"
                        message: "Вы уверены что хотите удалить все признаки просмотра у всех релизов?"
                        content: Row {
                            spacing: 6
                            anchors.right: parent.right

                            RoundedActionButton {
                                text: "Ок"
                                width: 100
                                onClicked: {
                                    localStorage.removeAllSeenMark();
                                    refreshSeenMarks();
                                    refreshAllReleases(true);
                                    removeAllSeenMark.close();
                                }
                            }
                            RoundedActionButton {
                                text: "Отмена"
                                width: 100
                                onClicked: {
                                    removeAllSeenMark.close();
                                }
                            }
                        }
                    }
                }
                IconButton {
                    id: searchPopupButton
                    height: 45
                    width: 40
                    iconColor: "white"
                    iconPath: "../Assets/Icons/search.svg"
                    iconWidth: 29
                    iconHeight: 29
                    onButtonPressed: {
                        filtersPopup.open();
                    }

                    Rectangle {
                        visible: descriptionSearchField.text || typeSearchField.text || genresSearchField.text || voicesSearchField.text || yearsSearchField.text || seasonesSearchField.text || statusesSearchField.text
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.rightMargin: 6
                        anchors.topMargin: 10
                        color: "#4ca2c2"
                        width: 16
                        height: 16
                        radius: 12
                    }

                    Popup {
                        id: filtersPopup
                        x: 40
                        y: searchPopupButton.height - 45
                        width: 450
                        height: 380
                        modal: true
                        focus: true
                        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

                        Rectangle {
                            width: parent.width
                            RoundedActionButton {
                                id: startFilterButton
                                anchors.left: parent.left
                                text: "Фильтровать"
                                onClicked: {
                                    page.refreshAllReleases(false);
                                }
                            }
                            RoundedActionButton {
                                id: clearFiltersButton
                                anchors.right: parent.right
                                text: "Очистить фильтры"
                                onClicked: {
                                    descriptionSearchField.text = "";
                                    typeSearchField.text = "";
                                    genresSearchField.text = "";
                                    orAndGenresSearchField.checked = false;
                                    voicesSearchField.text = "";
                                    orAndVoicesSearchField.checked = false;
                                    yearsSearchField.text = "";
                                    seasonesSearchField.text = "";
                                    statusesSearchField.text = "";

                                    page.refreshAllReleases(false);
                                }
                            }
                            Text {
                                id: labelDescriptionSearchField
                                anchors.top: clearFiltersButton.bottom
                                font.pointSize: 11 + windowSettings.dpiSeparation
                                text: qsTr("Описание")
                            }
                            Text {
                                id: labelTypeSearchField
                                anchors.top: clearFiltersButton.bottom
                                anchors.left: typeSearchField.left
                                font.pointSize: 11 + windowSettings.dpiSeparation
                                text: qsTr("Тип")
                            }
                            TextField {
                                id: descriptionSearchField
                                width: parent.width / 2 - 5
                                anchors.top: labelDescriptionSearchField.bottom
                                anchors.rightMargin: 10
                                placeholderText: "Описание"
                            }
                            TextField {
                                id: typeSearchField
                                width: parent.width / 2 - 5
                                anchors.top: labelTypeSearchField.bottom
                                anchors.right: parent.right
                                placeholderText: "Тип"
                            }

                            Text {
                                id: labelGenresSearchField
                                anchors.top: descriptionSearchField.bottom
                                anchors.rightMargin: 10
                                font.pointSize: 11 + windowSettings.dpiSeparation
                                text: qsTr("Жанры")
                            }
                            TextField {
                                id: genresSearchField
                                width: parent.width * 0.7
                                anchors.top: labelGenresSearchField.bottom
                                placeholderText: "Вводите жанры через запятую"
                            }
                            Text {
                                id: labelOrAndGenresSearchField
                                anchors.top: labelGenresSearchField.bottom
                                anchors.left: genresSearchField.right
                                topPadding: 16
                                leftPadding: 4
                                font.pointSize: 11 + windowSettings.dpiSeparation
                                text: qsTr("ИЛИ/И")
                            }
                            Switch {
                                id: orAndGenresSearchField
                                anchors.top: labelGenresSearchField.bottom
                                anchors.left: labelOrAndGenresSearchField.right
                            }

                            Text {
                                id: labelVoicesSearchField
                                anchors.top: genresSearchField.bottom
                                anchors.rightMargin: 10
                                font.pointSize: 11 + windowSettings.dpiSeparation
                                text: qsTr("Озвучка")
                            }
                            TextField {
                                id: voicesSearchField
                                width: parent.width * 0.7
                                anchors.top: labelVoicesSearchField.bottom
                                placeholderText: "Вводите войсеров через запятую"
                            }
                            Text {
                                id: labelOrAndVoicesSearchField
                                anchors.top: labelVoicesSearchField.bottom
                                anchors.left: voicesSearchField.right
                                topPadding: 16
                                leftPadding: 4
                                font.pointSize: 11 + windowSettings.dpiSeparation
                                text: qsTr("ИЛИ/И")
                            }
                            Switch {
                                id: orAndVoicesSearchField
                                anchors.top: labelVoicesSearchField.bottom
                                anchors.left: labelOrAndVoicesSearchField.right
                            }

                            Text {
                                id: labelYearsSearchField
                                anchors.top: voicesSearchField.bottom
                                font.pointSize: 11 + windowSettings.dpiSeparation
                                text: qsTr("Года")
                            }
                            Text {
                                id: labelSeasonsSearchField
                                anchors.top: voicesSearchField.bottom
                                anchors.left: typeSearchField.left
                                font.pointSize: 11 + windowSettings.dpiSeparation
                                text: qsTr("Сезоны")
                            }
                            TextField {
                                id: yearsSearchField
                                width: parent.width / 2 - 5
                                anchors.top: labelYearsSearchField.bottom
                                anchors.rightMargin: 10
                                placeholderText: "Вводите через запятую"
                            }
                            TextField {
                                id: seasonesSearchField
                                width: parent.width / 2 - 5
                                anchors.top: labelSeasonsSearchField.bottom
                                anchors.right: parent.right
                                placeholderText: "Вводите через запятую"
                            }
                            Text {
                                id: labelStatusesSearchField
                                anchors.top: yearsSearchField.bottom
                                anchors.rightMargin: 10
                                font.pointSize: 11 + windowSettings.dpiSeparation
                                text: qsTr("Статусы")
                            }
                            TextField {
                                id: statusesSearchField
                                anchors.top: labelStatusesSearchField.bottom
                                anchors.right: parent.right
                                anchors.left: parent.left
                                placeholderText: "Вводите статусы через запятую"
                            }

                        }
                    }
                }
                IconButton {
                    id: sortingPopupButton
                    height: 45
                    width: 40
                    iconColor: "white"
                    iconPath: "../Assets/Icons/sort.svg"
                    iconWidth: 29
                    iconHeight: 29
                    onButtonPressed: {
                        sortingPopup.open();
                    }

                    Popup {
                        id: sortingPopup
                        x: 40
                        y: sortingPopupButton.height - 100
                        width: 450
                        height: 200
                        modal: true
                        focus: true
                        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

                        Rectangle {
                            width: parent.width
                            RoundedActionButton {
                                id: startSortingButton
                                anchors.right: parent.right
                                text: "Сортировать"
                                onClicked: {
                                    page.refreshAllReleases(false);
                                }
                            }

                            Text {
                                id: labelSortingField
                                anchors.top: startSortingButton.bottom
                                font.pointSize: 11 + windowSettings.dpiSeparation
                                text: qsTr("Сортировать по")
                            }
                            ComboBox {
                                id: sortingComboBox
                                anchors.top: labelSortingField.bottom
                                anchors.right: parent.right
                                anchors.left: parent.left
                                model: ListModel {
                                    ListElement {
                                        text: "Дате последнего обновления"
                                    }
                                    ListElement {
                                        text: "Дню в расписании"
                                    }
                                    ListElement {
                                        text: "Имени"
                                    }
                                    ListElement {
                                        text: "Году"
                                    }
                                    ListElement {
                                        text: "Рейтингу"
                                    }
                                    ListElement {
                                        text: "Статусу"
                                    }
                                    ListElement {
                                        text: "Оригинальному имени"
                                    }
                                    ListElement {
                                        text: "История"
                                    }
                                    ListElement {
                                        text: "История просмотра"
                                    }
                                    ListElement {
                                        text: "Сезону"
                                    }
                                }
                            }

                            Text {
                                id: labelSortingDirection
                                anchors.top: sortingComboBox.bottom
                                font.pointSize: 11 + windowSettings.dpiSeparation
                                text: qsTr("В порядке")
                            }
                            ComboBox {
                                id: sortingDirectionComboBox
                                anchors.top: labelSortingDirection.bottom
                                anchors.right: parent.right
                                anchors.left: parent.left
                                currentIndex: 1
                                model: ListModel {
                                    ListElement { text: "Восходящем" }
                                    ListElement { text: "Нисходящем" }
                                }
                            }
                        }
                    }
                }
                IconButton {
                    id: notificationPopupButton
                    height: 45
                    width: 40
                    iconColor: "white"
                    iconPath: "../Assets/Icons/notification.svg"
                    iconWidth: 29
                    iconHeight: 29
                    onButtonPressed: {
                        page.changesCounts = localStorage.getChangesCounts();
                        notificationPopup.open();
                    }

                    Rectangle {
                        visible: localStorage.isChangesExists
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.rightMargin: 6
                        anchors.topMargin: 10
                        color: "#4ca2c2"
                        width: 16
                        height: 16
                        radius: 12
                    }

                    Popup {
                        id: notificationPopup
                        x: 40
                        y: sortingPopupButton.height - 100
                        width: 370
                        height: 250
                        modal: true
                        focus: true
                        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

                        Rectangle {
                            visible: !localStorage.isChangesExists
                            width: parent.width
                            height: parent.height
                            Text {
                                anchors.centerIn: parent
                                text: "У Вас нет новых уведомлений"
                                font.pointSize: 16 + windowSettings.dpiSeparation
                            }
                        }

                        Rectangle {
                            visible: localStorage.isChangesExists
                            width: parent.width
                            RoundedActionButton {
                                id: resetNotificationButton
                                anchors.right: parent.right
                                text: "Отметить все как прочитанное"
                                onClicked: {
                                    localStorage.resetAllChanges();
                                    page.changesCounts = [0, 0, 0, 0];
                                }
                            }
                            Column {
                                spacing: 4
                                anchors.top: resetNotificationButton.bottom
                                Rectangle {
                                    visible: page.changesCounts[0] > 0
                                    border.width: 3
                                    border.color: "red"
                                    width: 340
                                    height: 40
                                    Text {
                                        anchors.centerIn: parent
                                        font.pointSize: 11 + windowSettings.dpiSeparation
                                        text: "Новых релизов: " + page.changesCounts[0]
                                    }
                                }
                                Rectangle {
                                    visible: page.changesCounts[1] > 0
                                    border.width: 3
                                    border.color: "red"
                                    width: 340
                                    height: 40
                                    Text {
                                        anchors.centerIn: parent
                                        font.pointSize: 11 + windowSettings.dpiSeparation
                                        text: "Релизов с новыми сериями: " + page.changesCounts[1]
                                    }
                                }
                                Rectangle {
                                    visible: page.changesCounts[2] > 0
                                    border.width: 3
                                    border.color: "red"
                                    width: 340
                                    height: 40
                                    Text {
                                        anchors.centerIn: parent
                                        font.pointSize: 11 + windowSettings.dpiSeparation
                                        text: "Новые торренты: " + page.changesCounts[2]
                                    }
                                }
                                Rectangle {
                                    visible: page.changesCounts[3] > 0
                                    border.width: 3
                                    border.color: "red"
                                    width: 340
                                    height: 40
                                    Text {
                                        anchors.centerIn: parent
                                        font.pointSize: 11 + windowSettings.dpiSeparation
                                        text: "Релизы с обновленными торрентами: " + page.changesCounts[3]
                                    }
                                }
                            }
                        }
                    }
                }
                IconButton {
                    height: 45
                    width: 40
                    iconColor: "white"
                    iconPath: "../Assets/Icons/dice.svg"
                    iconWidth: 29
                    iconHeight: 29
                    onButtonPressed: {
                        const randomRelease = JSON.parse(localStorage.getRandomRelease());
                        showReleaseCard(randomRelease);
                    }
                }
                IconButton {
                    height: 45
                    width: 40
                    iconColor: "white"
                    iconPath: "../Assets/Icons/options.svg"
                    iconWidth: 29
                    iconHeight: 29
                    onButtonPressed: {
                        releaseSettingsPopup.open();
                    }

                    Popup {
                        id: releaseSettingsPopup
                        x: 40
                        y: sortingPopupButton.height - 100
                        width: 370
                        height: 160
                        modal: true
                        focus: true
                        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

                        Text {
                            id: downloadTorrentModeLabel
                            font.pointSize: 11 + windowSettings.dpiSeparation
                            text: "Торрент"
                        }
                        ComboBox {
                            id: downloadTorrentMode
                            currentIndex: 0
                            anchors.top: downloadTorrentModeLabel.bottom
                            width: 350
                            model: ["Открыть в торрент клиенте", "Сохранить файл"]
                            onCurrentIndexChanged: {
                                localStorage.setTorrentDownloadMode(downloadTorrentMode.currentIndex);
                            }
                        }

                        Text {
                            id: notificationForFavoritesLabel
                            anchors.top: downloadTorrentMode.bottom
                            anchors.topMargin: 4
                            font.pointSize: 11 + windowSettings.dpiSeparation
                            text: "Уведомления по избранным"
                        }

                        Switch {
                            id: notificationForFavorites
                            anchors.top: notificationForFavoritesLabel.bottom
                            onCheckedChanged: {
                                localStorage.setNotificationForFavorites(checked);
                            }
                        }

                    }
                }

                IconButton {
                    height: 45
                    width: 40
                    iconColor: "white"
                    iconPath: "../Assets/Icons/information.svg"
                    iconWidth: 29
                    iconHeight: 29
                    onButtonPressed: {
                        informationPopup.open();
                    }

                    Popup {
                        id: informationPopup
                        x: 40
                        y: sortingPopupButton.height - 100
                        width: 320
                        height: 96
                        modal: true
                        focus: true
                        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

                        Column {
                            Text {
                                font.pointSize: 11 + windowSettings.dpiSeparation
                                linkColor: "#b32121"
                                text: "<a href='http://anilibriadesktop.reformal.ru/'>Написать идею, ошибку, вопрос?</a>"
                                onLinkActivated: {
                                    Qt.openUrlExternally(link);
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.NoButton
                                    cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                                }
                            }
                            Text {
                                font.pointSize: 11 + windowSettings.dpiSeparation
                                linkColor: "#b32121"
                                text: "<a href='https://t.me/Libria911Bot'>Техподдержка Анилибрии</a>"
                                onLinkActivated: {
                                    Qt.openUrlExternally(link);
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.NoButton
                                    cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                                }
                            }
                            Text {
                                font.pointSize: 11 + windowSettings.dpiSeparation
                                linkColor: "#b32121"
                                text: "<a href='https://www.anilibria.tv'>Сайт анилибрии</a>"
                                onLinkActivated: {
                                    Qt.openUrlExternally(link);
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.NoButton
                                    cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                                }
                            }
                            Text {
                                font.pointSize: 11 + windowSettings.dpiSeparation
                                linkColor: "#b32121"
                                text: "<a href='https://t.me/desktopclientanilibria'>Канал о приложении</a>"
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

            }
        }

        ColumnLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            spacing: 2

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 45
                height: 45
                color: "#a6a6a6"
                Row {
                    Switch {
                        id: multupleMode
                        onCheckedChanged: {
                            page.selectMode = checked;
                            if (!checked) {
                                page.selectedReleases = [];
                            } else {
                                page.openedRelease = null;
                            }
                        }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: page.synchronizeEnabled
                        font.pointSize: 12 + windowSettings.dpiSeparation
                        text: "Выполняется синхронизация..."
                    }
                }
                Text {
                    text: page.sections[page.selectedSection]
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    font.pointSize: 12 + windowSettings.dpiSeparation
                }
            }

            Rectangle {
                id: filtersContainer
                Layout.preferredWidth: 380
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredHeight: 36
                color: "transparent"

                Row {
                    width: filtersContainer.width
                    spacing: 8
                    RoundedTextBox {
                        id: filterByTitle
                        width: 200
                        height: 30
                        fontSize: 10
                        placeholder: "Введите название релиза"
                        onCompleteEditing: {
                            refreshAllReleases(false);
                        }
                    }
                    IconButton {
                        height: 30
                        width: 30
                        iconColor: "black"
                        hoverColor: "white"
                        iconPath: "../Assets/Icons/allreleases.svg"
                        iconWidth: 24
                        iconHeight: 24
                        onButtonPressed: {
                            changeSection(0);
                        }
                    }
                    IconButton {
                        height: 30
                        width: 30
                        iconColor: "black"
                        hoverColor: "white"
                        iconPath: "../Assets/Icons/favorite.svg"
                        iconWidth: 24
                        iconHeight: 24
                        onButtonPressed: {
                            changeSection(1);
                        }
                    }
                    IconButton {
                        id: notificationMenuButton
                        height: 30
                        width: 30
                        iconColor: "black"
                        hoverColor: "white"
                        iconPath: "../Assets/Icons/notification.svg"
                        iconWidth: 24
                        iconHeight: 24
                        onButtonPressed: {
                            notificationsMenuSections.open();
                        }

                        Menu {
                            id: notificationsMenuSections
                            width: 350
                            y: notificationMenuButton.height

                            CommonMenuItem {
                                text: page.sections[2]
                                onPressed: {
                                    page.changeSection(2);
                                }
                            }
                            CommonMenuItem {
                                text: page.sections[3]
                                onPressed: {
                                    page.changeSection(3);
                                }
                            }
                            CommonMenuItem {
                                text: page.sections[4]
                                onPressed: {
                                    page.changeSection(4);
                                }
                            }
                            CommonMenuItem {
                                text: page.sections[6]
                                onPressed: {
                                    page.changeSection(6);
                                }
                            }
                        }
                    }
                    IconButton {
                        height: 30
                        width: 30
                        iconColor: "black"
                        hoverColor: "white"
                        iconPath: "../Assets/Icons/calendar.svg"
                        iconWidth: 24
                        iconHeight: 24
                        onButtonPressed: {
                            changeSection(5);
                        }
                    }

                    IconButton {
                        id: historyMenuButton
                        height: 30
                        width: 30
                        iconColor: "black"
                        hoverColor: "white"
                        iconPath: "../Assets/Icons/history.svg"
                        iconWidth: 24
                        iconHeight: 24
                        onButtonPressed: {
                            historyMenuSections.open();
                        }

                        Menu {
                            id: historyMenuSections
                            width: 300
                            y: historyMenuButton.height

                            CommonMenuItem {
                                text: page.sections[7]
                                onPressed: {
                                    page.changeSection(7);
                                }
                            }
                            CommonMenuItem {
                                text: page.sections[8]
                                onPressed: {
                                    page.changeSection(8);
                                }
                            }
                        }
                    }
                    IconButton {
                        id: seenMenuButton
                        height: 30
                        width: 30
                        iconColor: "black"
                        hoverColor: "white"
                        iconPath: "../Assets/Icons/seenmark.svg"
                        iconWidth: 24
                        iconHeight: 24
                        onButtonPressed: {
                            seenMenuSections.open();
                        }

                        Menu {
                            id: seenMenuSections
                            width: 300
                            y: seenMenuButton.height

                            CommonMenuItem {
                                text: page.sections[9]
                                onPressed: {
                                    page.changeSection(9);
                                }
                            }
                            CommonMenuItem {
                                text: page.sections[10]
                                onPressed: {
                                    page.changeSection(10);
                                }
                            }
                            CommonMenuItem {
                                text: page.sections[11]
                                onPressed: {
                                    page.changeSection(11);
                                }
                            }
                        }
                    }
                }
            }

            Flickable {
                id: scrollview
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignJustify
                clip: true
                contentWidth: parent.width
                contentHeight: itemGrid.height
                onContentYChanged: {
                    if (scrollview.atYEnd && !page.isBusy) {
                        page.isBusy = true;
                        fillNextReleases();
                        page.isBusy = false;
                    }
                }
                ScrollBar.vertical: ScrollBar {
                    active: true
                }

                ColumnLayout {
                    width: page.width
                    height: page.height
                    Grid {
                        id: itemGrid
                        Layout.alignment: Qt.AlignHCenter
                        columns: 2
                        spacing: 4
                        Repeater {
                            model: releasesModel
                            Rectangle {
                                width: 480
                                height: 280
                                radius: 10
                                border.color: "red"
                                border.width: page.selectedReleases.filter(a => a === modelData.id).length ? 3 : 0
                                color: "#f2f2f2"
                                layer.enabled: true
                                layer.effect: DropShadow {
                                    transparentBorder: true
                                    horizontalOffset: 2
                                    verticalOffset: 2
                                    radius: 1
                                    samples: 3
                                    color: "gray"
                                }
                                MouseArea {
                                    width: 480
                                    height: 280
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    onClicked: {
                                        if(mouse.button & Qt.RightButton) {
                                            multupleMode.checked = !multupleMode.checked;
                                            return;
                                        }

                                        if (page.openedRelease) return;

                                        page.selectItem(modelData);
                                    }                                    
                                }
                                Grid {
                                    columnSpacing: 3
                                    columns: 2
                                    bottomPadding: 4
                                    leftPadding: 4
                                    topPadding: 4
                                    rightPadding: 4
                                    Rectangle {
                                        width: 182
                                        height: 272
                                        border.color: "#adadad"
                                        border.width: 1
                                        radius: 12
                                        Image {
                                            anchors.centerIn: parent
                                            source: localStorage.getReleasePosterPath(modelData.id, modelData.poster)
                                            fillMode: Image.PreserveAspectCrop
                                            width: 180
                                            height: 270
                                            layer.enabled: true
                                            layer.effect: OpacityMask {
                                                maskSource: mask
                                            }
                                        }
                                    }
                                    Grid {
                                        height: 280
                                        Layout.row: 1
                                        Layout.column: 1
                                        rows: 2
                                        columns: 1
                                        Column {
                                            id: gridItemtextContainer
                                            Text {
                                                textFormat: Text.RichText
                                                color: "#a32727"
                                                font.pointSize: 12 + windowSettings.dpiSeparation
                                                width: 280
                                                leftPadding: 8
                                                topPadding: 6
                                                wrapMode: Text.WordWrap
                                                maximumLineCount: 3
                                                text: qsTr(modelData.title)
                                            }
                                            Text {
                                                textFormat: Text.RichText
                                                font.pointSize: 10 + windowSettings.dpiSeparation
                                                leftPadding: 8
                                                topPadding: 4
                                                text: qsTr("<b>Статус:</b> ") + qsTr(modelData.status)
                                            }
                                            Text {
                                                font.pointSize: 10 + windowSettings.dpiSeparation
                                                leftPadding: 8
                                                topPadding: 4
                                                text: qsTr("<b>" + modelData.season + " " + modelData.year + "</b>")
                                            }
                                            Text {
                                                textFormat: Text.RichText
                                                font.pointSize: 10 + windowSettings.dpiSeparation
                                                leftPadding: 8
                                                topPadding: 4
                                                width: 280
                                                wrapMode: Text.WordWrap
                                                maximumLineCount: 2
                                                text: qsTr("<b>Тип:</b> ") + qsTr(modelData.type)
                                            }
                                            Text {
                                                font.pointSize: 10 + windowSettings.dpiSeparation
                                                leftPadding: 8
                                                topPadding: 4
                                                width: 280
                                                wrapMode: Text.WordWrap
                                                maximumLineCount: 2
                                                text: qsTr("<b>Жанры:</b> ") + qsTr(modelData.genres)
                                            }
                                            Text {
                                                font.pointSize: 10 + windowSettings.dpiSeparation
                                                leftPadding: 8
                                                topPadding: 4
                                                width: 280
                                                wrapMode: Text.WordWrap
                                                maximumLineCount: 2
                                                text: qsTr("<b>Озвучка:</b> ") + qsTr(modelData.voices)
                                            }
                                            Row {
                                                leftPadding: 8
                                                topPadding: 4
                                                Image {
                                                    mipmap: true
                                                    source: '../Assets/Icons/online.svg'
                                                    width: 22
                                                    height: 22
                                                }
                                                Text {
                                                    leftPadding: 4
                                                    rightPadding: 8
                                                    font.pointSize: 12 + windowSettings.dpiSeparation
                                                    text: '' + modelData.countVideos + (modelData.countSeensSeries > 0 ? " <font color=\"green\">(" + modelData.countSeensSeries + ")</font>  " : "")
                                                }
                                                Image {
                                                    mipmap: true
                                                    source: '../Assets/Icons/utorrent.svg'
                                                    width: 22
                                                    height: 22
                                                }
                                                Text {
                                                    leftPadding: 4
                                                    rightPadding: 4
                                                    font.pointSize: 12 + windowSettings.dpiSeparation
                                                    text: '' + modelData.countTorrents
                                                }
                                            }
                                        }
                                        Rectangle {
                                            color: "transparent"
                                            height: 272 - gridItemtextContainer.height
                                            width: 280
                                            RoundedActionButton {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                anchors.bottom: parent.bottom
                                                anchors.bottomMargin: 20
                                                text: "Быстрые действия"
                                                onPressed: {
                                                    quickActions.open();
                                                }
                                                Menu {
                                                    id: quickActions
                                                    width: 320
                                                    modal: true
                                                    focus: true
                                                    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

                                                    CommonMenuItem {
                                                        enabled: applicationSettings.userToken && !page.favoriteReleases.filter(a => a === modelData.id).length
                                                        text: "Добавить в избранное"
                                                        onPressed: {
                                                            synchronizationService.addUserFavorites(applicationSettings.userToken, modelData.id.toString());
                                                            page.selectedReleases = [];
                                                        }
                                                    }
                                                    CommonMenuItem {
                                                        enabled: applicationSettings.userToken && page.favoriteReleases.filter(a => a === modelData.id).length
                                                        text: "Удалить из избранного"
                                                        onPressed: {
                                                            synchronizationService.removeUserFavorites(applicationSettings.userToken, modelData.id.toString());
                                                            page.selectedReleases = [];
                                                        }
                                                    }
                                                    CommonMenuItem {
                                                        text: "Смотреть"
                                                        onPressed: {
                                                            watchRelease(modelData.id, modelData.videos, -1);
                                                            quickActions.close();
                                                        }
                                                    }
                                                }
                                            }
                                            Row {
                                                anchors.bottom: parent.bottom
                                                leftPadding: 8
                                                topPadding: 8
                                                Image {
                                                    mipmap: true
                                                    source: '../Assets/Icons/rating.svg'
                                                    width: 20
                                                    height: 20
                                                }
                                                Text {
                                                    leftPadding: 4
                                                    rightPadding: 4
                                                    font.pointSize: 12 + windowSettings.dpiSeparation
                                                    text: modelData.rating
                                                }
                                                ColoredIcon {
                                                    visible: page.favoriteReleases.filter(a => a === modelData.id).length
                                                    iconSource: '../Assets/Icons/star.svg'
                                                    iconWidth: 20
                                                    iconHeight: 20
                                                    iconColor: "#a32727"
                                                }
                                                Text {
                                                    visible: page.favoriteReleases.filter(a => a === modelData.id).length
                                                    leftPadding: 4
                                                    color: "#a32727"
                                                    font.pointSize: 12 + windowSettings.dpiSeparation
                                                    text: "В избранном"
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Component.onCompleted: {
                    scrollview.maximumFlickVelocity = scrollview.maximumFlickVelocity - 1000;
                }
            }
        }
    }

    ColumnLayout {
        id: cardContainer
        visible: page.openedRelease ? true : false
        anchors.fill: parent
        spacing: 0
        Rectangle {
            color: "#D3D3D3"
            Layout.fillWidth: true
            Layout.fillHeight: true
            Column {
                Grid {
                    id: releaseInfo
                    columnSpacing: 3
                    columns: 3
                    bottomPadding: 4
                    leftPadding: 4
                    topPadding: 4
                    rightPadding: 4
                    Image {
                        id: cardPoster
                        source: page.openedRelease ? localStorage.getReleasePosterPath(page.openedRelease.id, page.openedRelease.poster) : '../Assets/Icons/donate.jpg'
                        fillMode: Image.PreserveAspectCrop
                        width: 280
                        height: 390
                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: cardMask
                        }
                    }
                    Column {
                        width: page.width - cardButtons.width - cardPoster.width
                        enabled: !!page.openedRelease
                        Text {
                            textFormat: Text.RichText
                            color: "#a32727"
                            font.pointSize: 12 + windowSettings.dpiSeparation
                            width: parent.width
                            leftPadding: 8
                            topPadding: 6
                            wrapMode: Text.WordWrap
                            maximumLineCount: 3
                            text: qsTr(page.openedRelease ? page.openedRelease.title : '')
                        }
                        Text {
                            textFormat: Text.RichText
                            font.pointSize: 10 + windowSettings.dpiSeparation
                            leftPadding: 8
                            topPadding: 4
                            wrapMode: Text.WordWrap
                            width: parent.width
                            maximumLineCount: 2
                            text: qsTr(page.openedRelease ? page.openedRelease.originalName : '')
                        }
                        Text {
                            font.pointSize: 10 + windowSettings.dpiSeparation
                            leftPadding: 8
                            topPadding: 4
                            text: qsTr("<b>Статус:</b> ") + qsTr(page.openedRelease ? `<a href="http://years">${page.openedRelease.status}</a>` : '')
                            linkColor: "#b32121"
                            onLinkActivated: {
                                statusesSearchField.text = page.openedRelease.status;
                                page.openedRelease = null;
                                page.refreshAllReleases(false);
                            }
                        }
                        Text {
                            font.pointSize: 10 + windowSettings.dpiSeparation
                            leftPadding: 8
                            topPadding: 4
                            text: qsTr("<b>Год:</b> ") + qsTr(page.openedRelease ?  `<a href="http://years">${page.openedRelease.year}</a>` : '')
                            linkColor: "#b32121"
                            onLinkActivated: {
                                yearsSearchField.text = page.openedRelease.year;
                                page.openedRelease = null;
                                page.refreshAllReleases(false);
                            }
                        }
                        Text {
                            visible: page.openedRelease && page.openedRelease.id && !!page.scheduledReleases[page.openedRelease.id]
                            font.pointSize: 10 + windowSettings.dpiSeparation
                            leftPadding: 8
                            topPadding: 4
                            text: qsTr("<b>В расписании:</b> ") + (page.openedRelease && page.scheduledReleases[page.openedRelease.id] ? getScheduleDay(page.scheduledReleases[page.openedRelease.id]) : '')
                        }

                        Text {
                            font.pointSize: 10 + windowSettings.dpiSeparation
                            leftPadding: 8
                            topPadding: 4
                            text: qsTr("<b>Сезон:</b> ") + qsTr(page.openedRelease ? `<a href="http://seasons">${page.openedRelease.season}</a>` : '')
                            linkColor: "#b32121"
                            onLinkActivated: {
                                seasonesSearchField.text = page.openedRelease.season;
                                page.openedRelease = null;
                                page.refreshAllReleases(false);
                            }
                        }
                        Text {
                            textFormat: Text.RichText
                            font.pointSize: 10 + windowSettings.dpiSeparation
                            leftPadding: 8
                            topPadding: 4
                            width: parent.width
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            text: qsTr("<b>Тип:</b> ") + qsTr(page.openedRelease ? page.openedRelease.type : '')
                        }
                        Text {
                            font.pointSize: 10 + windowSettings.dpiSeparation
                            leftPadding: 8
                            topPadding: 4
                            width: parent.width
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            text: qsTr("<b>Жанры:</b> ") + qsTr(page.openedRelease ? getMultipleLinks(page.openedRelease.genres) : '')
                            linkColor: "#b32121"
                            onLinkActivated: {
                                if (genresSearchField.text.length) {
                                    genresSearchField.text += ", " + link;
                                } else {
                                    genresSearchField.text = link;
                                }
                                page.openedRelease = null;
                                page.refreshAllReleases(false);
                            }
                        }
                        Text {
                            font.pointSize: 10 + windowSettings.dpiSeparation
                            leftPadding: 8
                            topPadding: 4
                            width: parent.width
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            text: qsTr("<b>Озвучка:</b> ") + qsTr(page.openedRelease ? getMultipleLinks(page.openedRelease.voices) : '')
                            linkColor: "#b32121"
                            onLinkActivated: {
                                if (voicesSearchField.text.length) {
                                    voicesSearchField.text += ", " + link;
                                } else {
                                    voicesSearchField.text = link;
                                }
                                page.openedRelease = null;
                                page.refreshAllReleases(false);
                            }
                        }
                        Text {
                            font.pointSize: 10 + windowSettings.dpiSeparation
                            leftPadding: 8
                            topPadding: 4
                            visible: page.openedRelease ? page.openedRelease.countSeensSeries === page.openedRelease.countVideos : false
                            width: parent.width
                            text: qsTr("<b>Все серии просмотрены</b>")
                        }
                        Text {
                            textFormat: Text.RichText
                            font.pointSize: 10 + windowSettings.dpiSeparation
                            leftPadding: 8
                            topPadding: 4
                            width: parent.width
                            wrapMode: Text.WordWrap
                            text: qsTr("<b>Описание:</b> ") + qsTr(page.openedRelease ? page.openedRelease.description : '')
                            linkColor: "#b32121"
                            onLinkActivated: {
                                if (link.indexOf("https://www.anilibria.tv/release/") === 0 || link.indexOf("http://www.anilibria.tv/release/") === 0) {
                                    let code = link.replace("https://www.anilibria.tv/release/", "").replace("http://www.anilibria.tv/release/", "").replace(".html", "")
                                    if (code.indexOf(`?`) > -1) code = code.substring( 0, code.indexOf(`?`));
                                    const release = JSON.parse(localStorage.getReleaseByCode(code));
                                    showReleaseCard(release);
                                } else {
                                    Qt.openUrlExternally(link);
                                }
                            }
                        }
                    }
                    Column {
                        id: cardButtons
                        width: 62
                        IconButton {
                            height: 40
                            width: 40
                            iconColor: "black"
                            iconPath: "../Assets/Icons/close.svg"
                            iconWidth: 28
                            iconHeight: 28
                            onButtonPressed: {
                                page.openedRelease = null;
                            }
                        }
                        IconButton {
                            height: 40
                            width: 40
                            iconColor: "black"
                            iconPath: "../Assets/Icons/copy.svg"
                            iconWidth: 26
                            iconHeight: 26
                            onButtonPressed: {
                                cardCopyMenu.open();
                            }

                            TextEdit {
                                id: hiddenTextField
                                visible: false
                            }

                            Menu {
                                id: cardCopyMenu
                                width: 350

                                CommonMenuItem {
                                    text: "Копировать название"
                                    onPressed: {
                                        copyToClipboard(page.openedRelease.title);
                                    }
                                }
                                CommonMenuItem {
                                    text: "Копировать оригинальное название"
                                    onPressed: {
                                        copyToClipboard(page.openedRelease.originalName);
                                    }
                                }
                                CommonMenuItem {
                                    text: "Копировать оба названия"
                                    onPressed: {
                                        copyToClipboard(page.openedRelease.title + ", " + page.openedRelease.originalName);
                                    }
                                }
                                CommonMenuItem {
                                    text: "Копировать описание"
                                    onPressed: {
                                        copyToClipboard(page.openedRelease.description);
                                    }
                                }
                            }
                        }
                        IconButton {
                            height: 40
                            width: 40
                            iconColor: "black"
                            iconPath: "../Assets/Icons/vk.svg"
                            iconWidth: 26
                            iconHeight: 26
                            onButtonPressed: {
                                vkontakteMenu.open();
                            }
                            Menu {
                                id: vkontakteMenu
                                width: 350

                                CommonMenuItem {
                                    text: "Авторизоваться для комментариев"
                                    onPressed: {
                                        webView.url = "https://oauth.vk.com/authorize?client_id=-1&display=widget&widget=4&redirect_uri=https://vk.com/";
                                    }
                                }
                                CommonMenuItem {
                                    text: "Переоткрыть комментарии"
                                    onPressed: {
                                        webView.url = getVkontakteCommentPage();
                                    }
                                }
                            }
                        }
                        IconButton {
                            height: 40
                            width: 40
                            iconColor: "black"
                            iconPath: "../Assets/Icons/seenmark.svg"
                            iconWidth: 26
                            iconHeight: 26
                            onButtonPressed: {
                                seenMarkMenu.open();
                            }
                            Menu {
                                id: seenMarkMenu
                                width: 350

                                CommonMenuItem {
                                    text: "Отметить как просмотренное"
                                    onPressed: {
                                        setSeenStateForOpenedRelease(true);
                                    }
                                }
                                CommonMenuItem {
                                    text: "Отметить как не просмотренное"
                                    onPressed: {
                                        setSeenStateForOpenedRelease(false);
                                    }
                                }
                            }
                        }
                        IconButton {
                            height: 40
                            width: 40
                            iconColor: page.openedRelease && page.favoriteReleases.filter(a => a === page.openedRelease.id).length ? "red" : "black"
                            iconPath: "../Assets/Icons/favorite.svg"
                            iconWidth: 26
                            iconHeight: 26
                            onButtonPressed: {
                                if (!window.userModel.login) {
                                    favoritePopupHeader.text = "Избранное не доступно";
                                    favoritePopupMessage.text = "Чтобы добавлять в избранное нужно вначале авторизоваться. Для этого перейдите на страницу Войти в меню и войдите под данными своего аккаунта. Если вы не зарегистрированы то необходимо сделать это на сайте, ссылка на сайт будет на странице Войти.";
                                    messagePopup.open();
                                    return;
                                }

                                cardFavoritesMenu.open();
                            }

                            Menu {
                                id: cardFavoritesMenu
                                width: 350
                                modal: true
                                focus: true
                                closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

                                CommonMenuItem {
                                    enabled: page.openedRelease && !page.favoriteReleases.filter(a => a === page.openedRelease.id).length
                                    text: "Добавить в избранное"
                                    onPressed: {
                                        synchronizationService.addUserFavorites(applicationSettings.userToken, page.openedRelease.id.toString());
                                        page.selectedReleases = [];
                                    }
                                }
                                CommonMenuItem {
                                    enabled: page.openedRelease && page.favoriteReleases.filter(a => a === page.openedRelease.id).length
                                    text: "Удалить из избранного"
                                    onPressed: {
                                        synchronizationService.removeUserFavorites(applicationSettings.userToken, page.openedRelease.id.toString());
                                        page.selectedReleases = [];
                                    }
                                }
                            }
                        }
                        IconButton {
                            height: 40
                            width: 40
                            iconColor: "black"
                            iconPath: "../Assets/Icons/external.svg"
                            iconWidth: 26
                            iconHeight: 26
                            onButtonPressed: {
                                externalPlayerMenu.open();
                            }

                            Menu {
                                id: externalPlayerMenu
                                width: 380
                                modal: true
                                focus: true
                                closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

                                CommonMenuItem {
                                    text: "Открыть во внешнем плеере в HD качестве"
                                    onPressed: {
                                        openInExternalPlayer(localStorage.packAsM3UAndOpen(page.openedRelease.id, "hd"))
                                    }
                                }
                                CommonMenuItem {
                                    text: "Открыть во внешнем плеере в SD качестве"
                                    onPressed: {
                                        openInExternalPlayer(localStorage.packAsM3UAndOpen(page.openedRelease.id, "sd"))
                                    }
                                }
                                CommonMenuItem {
                                    text: "Открыть во внешнем плеере в FullHD качестве"
                                    onPressed: {
                                        openInExternalPlayer(localStorage.packAsM3UAndOpen(page.openedRelease.id, "fullhd"))
                                    }
                                }

                                CommonMenuItem {
                                    notVisible: Qt.platform.os !== "windows"
                                    text: "Открыть в плеере MPC в HD качестве"
                                    onPressed: {
                                        openInExternalPlayer(localStorage.packAsMPCPLAndOpen(page.openedRelease.id, "hd"))
                                    }                                    
                                }
                                CommonMenuItem {
                                    notVisible: Qt.platform.os !== "windows"
                                    text: "Открыть в плеере MPC в SD качестве"
                                    onPressed: {
                                        openInExternalPlayer(localStorage.packAsMPCPLAndOpen(page.openedRelease.id, "sd"))
                                    }
                                }
                                CommonMenuItem {
                                    notVisible: Qt.platform.os !== "windows"
                                    text: "Открыть в плеере MPC в FullHD качестве"
                                    onPressed: {
                                        openInExternalPlayer(localStorage.packAsMPCPLAndOpen(page.openedRelease.id, "fullhd"))
                                    }
                                }
                            }
                        }

                        IconButton {
                            height: 40
                            width: 40
                            iconColor: "black"
                            iconPath: "../Assets/Icons/online.svg"
                            iconWidth: 26
                            iconHeight: 26
                            onButtonPressed: {
                                if (Qt.platform.os !== "windows") webView.visible = false;
                                setSeriesMenu.open();
                            }

                            Menu {
                                id: setSeriesMenu
                                width: 330
                                modal: true
                                focus: true
                                closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent
                                onClosed: {
                                    if (Qt.platform.os !== "windows") webView.visible = true;
                                }

                                Repeater {
                                    model: page.openedRelease ? page.openedRelease.countVideos : 0

                                    CommonMenuItem {
                                        text: "Серия " + (index + 1)
                                        onPressed: {
                                            watchRelease(page.openedRelease.id, page.openedRelease.videos, index);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                Rectangle {
                    color: "transparent"
                    width: cardContainer.width
                    height: 60

                    RoundedActionButton {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 10
                        anchors.left: parent.left
                        text: qsTr("Скачать")
                        onClicked: {
                            dowloadTorrent.open();
                        }

                        Menu {
                            id: dowloadTorrent
                            y: parent.height - parent.height - (torrentsModel.count * 40)
                            width: 320

                            Repeater {
                                model: torrentsModel
                                CommonMenuItem {
                                    text: "Скачать " + modelData.quality + " [" + modelData.series + "]"
                                    onPressed: {
                                        const torrentUri = synchronizationService.combineWithWebSiteUrl(modelData.url);
                                        synchronizationService.downloadTorrent(torrentUri);
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 100
                        font.pointSize: 11 + windowSettings.dpiSeparation
                        text: "Доступно "+ (page.openedRelease ? page.openedRelease.countTorrents : "0" ) + " торрентов"
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: watchButton.left
                        anchors.rightMargin: 10
                        font.pointSize: 11 + windowSettings.dpiSeparation
                        text: "Доступно "+ (page.openedRelease ? page.openedRelease.countVideos : "0" ) + " серий онлайн"
                    }

                    RoundedActionButton {
                        id: watchButton
                        text: qsTr("Смотреть")
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        onClicked: {
                            watchRelease(page.openedRelease.id, page.openedRelease.videos, -1);

                            page.openedRelease = null;
                        }
                    }

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                    }

                }
                WebView {
                    id: webView
                    visible: page.openedRelease ? true : false
                    width: cardContainer.width
                    height: cardContainer.height - releaseInfo.height - 60
                    url: page.openedRelease ? getVkontakteCommentPage() : "https://vk.com/";
                    onLoadingChanged: {
                        //if (loadRequest.errorString) console.error(loadRequest.errorString);
                    }
                }
            }
        }

    }

    function setSeenStateForOpenedRelease(newState) {
        localStorage.setSeenMarkAllSeries(page.openedRelease.id, page.openedRelease.countVideos, newState);
        page.openedRelease.countSeensSeries = newState ? page.openedRelease.countVideos : 0;
        const oldRelease = page.openedRelease;
        page.openedRelease = null;
        page.openedRelease = oldRelease;
        refreshSeenMarks();
        refreshAllReleases(true);
    }

    function setSeenStateForRelease(newState, releases) {
        localStorage.setMultipleSeenMarkAllSeries(releases, newState);
        page.selectedReleases = [];
        refreshSeenMarks();
        refreshAllReleases(true);
    }

    function getVkontakteCommentPage() {
        return "https://vk.com/widget_comments.php?app=5315207&width=100%&_ver=1&limit=8&norealtime=0&url=https://www.anilibria.tv/release/" + page.openedRelease.code + ".html";
    }

    function selectItem(item) {
        if (page.selectMode) {
            if (page.openedRelease) page.openedRelease = null;
            if (page.selectedReleases.find(a => a === item.id)) {
                page.selectedReleases = page.selectedReleases.filter(a => a !== item.id);
            } else {
                page.selectedReleases.push(item.id);
            }

            //WORKAROUND: fix refresh list
            const oldSelectedReleases = page.selectedReleases;
            page.selectedReleases = [];
            page.selectedReleases = oldSelectedReleases;
        } else {
            showReleaseCard(item);
        }
    }

    function getReleasesByFilter() {
        return JSON.parse(
            localStorage.getReleasesByFilter(
                page.pageIndex,
                filterByTitle.textContent,
                page.selectedSection,
                descriptionSearchField.text,
                typeSearchField.text,
                genresSearchField.text,
                orAndGenresSearchField.checked,
                voicesSearchField.text,
                orAndVoicesSearchField.checked,
                yearsSearchField.text,
                seasonesSearchField.text,
                statusesSearchField.text,
                sortingComboBox.currentIndex,
                sortingDirectionComboBox.currentIndex == 1 ? true : false
            )
        );
    }

    function refreshSeenMarks() {
        page.seenMarks = JSON.parse(localStorage.getSeenMarks());
    }

    function setSeensCounts(releases) {
        for (const release of releases) {
            release.countSeensSeries = 0;
            if (release.id in page.seenMarks) {
                release.countSeensSeries = page.seenMarks[release.id];
            }
        }
    }

    function fillNextReleases() {
        page.pageIndex += 1;
        const nextPageReleases = getReleasesByFilter();
        setSeensCounts(nextPageReleases);
        for (const displayRelease of nextPageReleases) releasesModel.append({ model: displayRelease });
    }

    function refreshAllReleases(notResetScroll) {
        if (Object.keys(page.seenMarks).length === 0) refreshSeenMarks();
        page.pageIndex = 1;
        releasesModel.clear();
        const displayReleases = getReleasesByFilter();
        setSeensCounts(displayReleases);
        for (const displayRelease of displayReleases) releasesModel.append({ model: displayRelease });
        if (!notResetScroll) scrollview.contentY = 0;
    }

    function changeSection(section) {
        page.selectedSection = section;
        if (section in page.sectionSortings) {
            const defaultSorting = page.sectionSortings[section];
            sortingComboBox.currentIndex = defaultSorting.field;
            sortingDirectionComboBox.currentIndex = defaultSorting.direction;
        }

        refreshAllReleases(false);
    }

    function refreshSchedule() {
        const schedule = localStorage.getSchedule();
        if (schedule) page.scheduledReleases = JSON.parse(schedule);
    }

    function getScheduleDay(dayNumber) {
        const day = parseInt(dayNumber);
        switch (day){
            case 1: return "понедельник";
            case 2: return "вторник";
            case 3: return "среда";
            case 4: return "четверг";
            case 5: return "пятница";
            case 6: return "суббота";
            case 7: return "воскресенье";
        }
        return "---";
    }

    function showReleaseCard(release) {
        torrentsModel.clear();

        const torrents = JSON.parse(release.torrents);

        for (const torrent of torrents) {
            torrentsModel.append({ model: torrent });
        }

        page.openedRelease = release;
        localStorage.setToReleaseHistory(release.id, 0);
        analyticsService.sendView("releasecard", "show", "%2Freleases");

        localStorage.resetReleaseChanges(release.id);        
        page.changesCounts = localStorage.getChangesCounts();
    }

    function copyToClipboard(text) {
        hiddenTextField.text = text;
        hiddenTextField.selectAll();
        hiddenTextField.copy();
    }

    function openInExternalPlayer(url) {
        if (!url) return;

        Qt.openUrlExternally(url);
    }

    function getMultipleLinks(text) {
        if (!text) return "";
        let result = "";

        const parts = text.split(",");
        let isFirst = true;
        for (const part of parts) {
            const partData = part.trim();
            result += (!isFirst ? ", " : "") + `<a href="${partData}">${partData}</a>`;
            isFirst = false;
        }

        return result;
    }

    Component.onCompleted: {
        refreshAllReleases(false);
        refreshSchedule();

        const userSettings = JSON.parse(localStorage.getUserSettings());
        downloadTorrentMode.currentIndex = userSettings.torrentDownloadMode;
        notificationForFavorites.checked = userSettings.notificationForFavorites;
    }
}
