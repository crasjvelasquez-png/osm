/****************************************************************************
** Generated QML type registration code
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include <QtQml/qqml.h>
#include <QtQml/qqmlmoduleregistration.h>

#include <autosaver.h>
#include <channelmodel.h>
#include <filtersource.h>
#include <metertablemodel.h>
#include <recentfilesmodel.h>
#include <sourcewindowing.h>

void qml_register_types_OpenSoundMeterModule()
{
    qmlRegisterTypesAndRevisions<AutoSaver>("OpenSoundMeterModule", 1);
    qmlRegisterTypesAndRevisions<FilterSource>("OpenSoundMeterModule", 1);
    qmlRegisterTypesAndRevisions<GeneratorChannelModel>("OpenSoundMeterModule", 1);
    qmlRegisterTypesAndRevisions<MeterTableModel>("OpenSoundMeterModule", 1);
    qmlRegisterTypesAndRevisions<RecentFilesModel>("OpenSoundMeterModule", 1);
    qmlRegisterTypesAndRevisions<Windowing>("OpenSoundMeterModule", 1);
    qmlRegisterModule("OpenSoundMeterModule", 1, 0);
}

static const QQmlModuleRegistration registration("OpenSoundMeterModule", 1, qml_register_types_OpenSoundMeterModule);
