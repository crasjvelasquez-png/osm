QT += core testlib network widgets
CONFIG += console testcase c++17 sdk_no_version_check
CONFIG -= app_bundle
TEMPLATE = app
TARGET = dante-test

INCLUDEPATH += ../../src ../../src/dante ../../src/common

SOURCES += \
    tst_dante.cpp \
    ../../src/dante/monitor.cpp \
    ../../src/common/settings.cpp \
    ../../src/common/workingfolder.cpp

HEADERS += \
    ../../src/dante/monitor.h \
    ../../src/common/settings.h \
    ../../src/common/workingfolder.h

macx: LIBS += -framework CoreFoundation
