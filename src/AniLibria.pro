QT += quick multimedia network webview concurrent svg
CONFIG += c++11

windows {
    QT += av
}

unix {
#Setup desktop entry file. https://specifications.freedesktop.org/desktop-entry-spec/latest
    desktop.files += anilibria.desktop
    desktop.path = /usr/share/applications

#Setup icons for following resolutions: 16x16; 32x32; 128x128; 256x256 and 512x512.
#https://specifications.freedesktop.org/icon-theme-spec/icon-theme-spec-latest.html

#16x16
    icon_16.path = /usr/share/icons/hicolor/16x16/apps
    icon_16.commands = mkdir -p icons/16 && cp ../anilibria.iconset/icon_16x16@2x.png icons/16/anilibria.png
    icon_16.files += icons/16/anilibria.png
#32x32
    icon_32.path = /usr/share/icons/hicolor/32x32/apps
    icon_32.commands = mkdir -p icons/32 && cp ../anilibria.iconset/icon_32x32@2x.png icons/32/anilibria.png
    icon_32.files += icons/32/anilibria.png
#48x48 #TODO: create png icon in 48x48 resolution.
    icon_48.path = /usr/share/icons/hicolor/48x48/apps
    icon_48.commands = mkdir -p icons/48 && cp ../anilibria.iconset/icon_32x32@2x.png icons/48/anilibria.png
    icon_48.files += icons/48/anilibria.png
#128x128
    icon_128.path = /usr/share/icons/hicolor/128x128/apps
    icon_128.commands = mkdir -p icons/128 && cp ../anilibria.iconset/icon_128x128.png icons/128/anilibria.png
    icon_128.files += icons/128/anilibria.png
#256x256
    icon_256.path = /usr/share/icons/hicolor/256x256/apps
    icon_256.commands = mkdir -p icons/256 && cp ../anilibria.iconset/icon_256x256.png icons/256/anilibria.png
    icon_256.files += icons/256/anilibria.png
#512x512
    icon_512.path = /usr/share/icons/hicolor/512x512/apps
    icon_512.commands = mkdir -p icons/512 && cp ../anilibria.iconset/icon_512x512.png icons/512/anilibria.png
    icon_512.files += icons/512/anilibria.png

    UNIX_ICONS += icon_16 icon_32 icon_48 icon_128 icon_256 icon_512
}

# The following define makes your compiler emit warnings if you use
# any Qt feature that has been marked deprecated (the exact warnings
# depend on your compiler). Refer to the documentation for the
# deprecated API to know how to port your code away from it.
DEFINES += QT_DEPRECATED_WARNINGS

# If you need not check version remove or comment this line
DEFINES += USE_VERSION_CHECK

# You can also make your code fail to compile if it uses deprecated APIs.
# In order to do so, uncomment the following line.
# You can also select to disable deprecated APIs only up to a certain version of Qt.
#DEFINES += QT_DISABLE_DEPRECATED_BEFORE=0x060000    # disables all the APIs deprecated before Qt 6.0.0

SOURCES += \
    Classes/Models/changesmodel.cpp \
    Classes/Models/externalplaylistvideo.cpp \
    Classes/Models/fullreleasemodel.cpp \
    Classes/Models/historymodel.cpp \
    Classes/Models/onlinevideomodel.cpp \
    Classes/Models/releasemodel.cpp \
    Classes/Models/releasetorrentmodel.cpp \
    Classes/Models/seenmarkmodel.cpp \
    Classes/Models/seenmodel.cpp \
    Classes/Models/usersettingsmodel.cpp \
    Classes/Models/youtubevideomodel.cpp \
    Classes/Services/analyticsservice.cpp \
    Classes/Services/anilibriaapiservice.cpp \
    Classes/Services/applicationsettings.cpp \
    Classes/Services/downloadmanager.cpp \
    Classes/Services/imageloader.cpp \
    Classes/Services/localstorageservice.cpp \
    Classes/Services/offlineimagecacheservice.cpp \
    Classes/Services/synchronizationservice.cpp \
    Classes/Services/versionchecker.cpp \
    Classes/globalconstant.cpp \
    main.cpp

RESOURCES += qml.qrc

RC_ICONS = fullsizesicon.ico

ICON = anilibria.icns

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH =

# Additional import path used to resolve QML modules just for Qt Quick Designer
QML_DESIGNER_IMPORT_PATH =

# Default rules for deployment.
qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin

!isEmpty(target.path) {
    unix: INSTALLS += target desktop $${UNIX_ICONS}
    else:macx: INSTALLS += target
}

HEADERS += \
    Classes/Models/changesmodel.h \
    Classes/Models/externalplaylistvideo.h \
    Classes/Models/fullreleasemodel.h \
    Classes/Models/historymodel.h \
    Classes/Models/onlinevideomodel.h \
    Classes/Models/releasemodel.h \
    Classes/Models/releasetorrentmodel.h \
    Classes/Models/seenmarkmodel.h \
    Classes/Models/seenmodel.h \
    Classes/Models/usersettingsmodel.h \
    Classes/Models/youtubevideomodel.h \
    Classes/Services/analyticsservice.h \
    Classes/Services/anilibriaapiservice.h \
    Classes/Services/applicationsettings.h \
    Classes/Services/downloadmanager.h \
    Classes/Services/imageloader.h \
    Classes/Services/localstorageservice.h \
    Classes/Services/offlineimagecacheservice.h \
    Classes/Services/synchronizationservice.h \
    Classes/Services/versionchecker.h \
    globalconstants.h
