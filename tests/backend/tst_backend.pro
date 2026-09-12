QT += core testlib sql
CONFIG += c++17 console testcase
CONFIG -= app_bundle
TEMPLATE = app
TARGET = tst_backend
DESTDIR = $$OUT_PWD

INCLUDEPATH += ../../src

SOURCES += \
    tst_backend.cpp \
    ../../src/database.cpp \
    ../../src/appsettings.cpp \
    ../../src/repository.cpp \
    ../../src/history.cpp \
    ../../src/itemmodel.cpp \
    ../../src/inboxproxymodel.cpp \
    ../../src/dateparser.cpp \
    ../../src/columnproxymodel.cpp \
    ../../src/calendarmodel.cpp \
    ../../src/listproxymodel.cpp \
    ../../src/mapproxymodel.cpp \
    ../../src/nodelayout.cpp \
    ../../src/itemfilter.cpp

HEADERS += \
    ../../src/models.h \
    ../../src/database.h \
    ../../src/appsettings.h \
    ../../src/repository.h \
    ../../src/history.h \
    ../../src/itemmodel.h \
    ../../src/inboxproxymodel.h \
    ../../src/dateparser.h \
    ../../src/columnproxymodel.h \
    ../../src/calendarmodel.h \
    ../../src/listproxymodel.h \
    ../../src/mapproxymodel.h \
    ../../src/nodelayout.h \
    ../../src/itemfilter.h