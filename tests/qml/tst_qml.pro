QT += quick quickcontrols2 sql qmltest testlib
CONFIG += c++17 console testcase qmltestcase
CONFIG -= app_bundle
TEMPLATE = app
TARGET = tst_qml
DESTDIR = $$OUT_PWD

# Sinkronkan manual dengan VERSION di ToDoList-Integrated.pro
VERSION = 1.1.0
DEFINES += APP_VERSION=\\\"$$VERSION\\\"

QUICK_TEST_SOURCE_DIR = $$PWD

INCLUDEPATH += ../../src

SOURCES += \
    tst_qml.cpp \
    ../../src/database.cpp \
    ../../src/appsettings.cpp \
    ../../src/repository.cpp \
    ../../src/itemmodel.cpp \
    ../../src/inboxproxymodel.cpp \
    ../../src/dateparser.cpp \
    ../../src/columnproxymodel.cpp \
    ../../src/calendarmodel.cpp \
    ../../src/listproxymodel.cpp \
    ../../src/mapproxymodel.cpp \
    ../../src/nodelayout.cpp

HEADERS += \
    ../../src/models.h \
    ../../src/database.h \
    ../../src/appsettings.h \
    ../../src/repository.h \
    ../../src/itemmodel.h \
    ../../src/inboxproxymodel.h \
    ../../src/dateparser.h \
    ../../src/columnproxymodel.h \
    ../../src/calendarmodel.h \
    ../../src/listproxymodel.h \
    ../../src/mapproxymodel.h \
    ../../src/nodelayout.h
