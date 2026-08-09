QT += quick sql quickcontrols2

# C++17 (PRD.md §7)
CONFIG += c++17 qtquickcompiler

# Built against Qt 5.15 (PRD.md §7) — refuse anything older
lessThan(QT_VERSION, 5.15): error("This project requires Qt 5.15 or newer (PRD.md §7).")

TEMPLATE = app
TARGET = ToDoList-Integrated

# Version — sumber tunggal untuk tag rilis (semver; lihat README "Release process")
VERSION = 1.1.0
DEFINES += APP_VERSION=\\\"$$VERSION\\\"

# You can make your code fail to compile if it uses deprecated APIs.
# In order to do so, uncomment the following line.
#DEFINES += QT_DISABLE_DEPRECATED_BEFORE=0x050f00    # disables all the APIs deprecated before Qt 5.15.0

INCLUDEPATH += src

SOURCES += \
        src/main.cpp \
        src/database.cpp \
        src/appsettings.cpp \
        src/repository.cpp \
        src/history.cpp \
        src/itemmodel.cpp \
        src/inboxproxymodel.cpp \
        src/dateparser.cpp \
        src/columnproxymodel.cpp \
        src/calendarmodel.cpp \
        src/listproxymodel.cpp \
        src/mapproxymodel.cpp \
        src/nodelayout.cpp

HEADERS += \
        src/models.h \
        src/database.h \
        src/appsettings.h \
        src/repository.h \
        src/history.h \
        src/itemmodel.h \
        src/inboxproxymodel.h \
        src/dateparser.h \
        src/columnproxymodel.h \
        src/calendarmodel.h \
        src/listproxymodel.h \
        src/mapproxymodel.h \
        src/nodelayout.h

RESOURCES += qml/qml.qrc

TRANSLATIONS += \
    ToDoList-Integrated_id_ID.ts \
    ToDoList-Integrated_en.ts

# lrelease sistem tidak ada (qttools5-dev-tools tak terinstal; /usr/bin/lrelease pun dangling).
# Pakai lrelease qmake Qt 5.15.2 (toolchain pinned, konsisten dengan AGENTS.md). qtPrepareTool()
# hanya menghormati QT_TOOL.<tool>.binary, bukan QMAKE_LRELEASE.
QT_TOOL.lrelease.binary = /home/banghbr/Qt515/5.15.2/gcc_64/bin/lrelease
CONFIG += lrelease
CONFIG += embed_translations

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH =


# Keep intermediate build artifacts out of the source tree
OBJECTS_DIR = $$OUT_PWD/.obj
MOC_DIR = $$OUT_PWD/.moc
RCC_DIR = $$OUT_PWD/.rcc
UI_DIR = $$OUT_PWD/.ui

# Windows: no console window for release builds
win32:CONFIG(release, debug|release): CONFIG -= console

# Default rules for deployment.
qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target
