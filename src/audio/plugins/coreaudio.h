/**
 *  OSM
 *  Copyright (C) 2021  Pavel Smokotnin

 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.

 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.

 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
#ifndef AUDIO_MACOS_H
#define AUDIO_MACOS_H

#include "../plugin.h"
#include <CoreAudio/CoreAudio.h>
#include <set>
#include <mutex>

namespace audio {

bool microphoneAccessAllowed();

class CoreaudioPlugin : public Plugin
{
    Q_OBJECT

public:
    struct PropertyListenerKey {
        AudioObjectID id;
        AudioObjectPropertyAddress address;

        bool operator<(const PropertyListenerKey &other) const {
            if (id != other.id) return id < other.id;
            if (address.mSelector != other.address.mSelector) return address.mSelector < other.address.mSelector;
            if (address.mScope != other.address.mScope) return address.mScope < other.address.mScope;
            return address.mElement < other.address.mElement;
        }
    };

    CoreaudioPlugin();
    ~CoreaudioPlugin();

    QString name() const override;
    DeviceInfo::List getDeviceInfoList() const override;
    DeviceInfo::Id defaultDeviceId(const Direction &mode) const override;

    Format deviceFormat(const DeviceInfo::Id &id, const Direction &mode) const override;
    Stream *open(const DeviceInfo::Id &id, const Direction &mode, const Format &format, QIODevice *endpoint) override;

    size_t registeredListenerCount() const;

signals:
    void stopStreams(QPrivateSignal);

private:
    unsigned int getDeviceDefaultSampleRate(const int &deviceID) const;
    unsigned int getDeviceChannelCount(const int &deviceID, const Direction &direction) const;
    QStringList getDeviceChannelNames(const int &deviceID, const Direction &direction) const;

    void addPropertyListener(AudioObjectID id, const AudioObjectPropertyAddress &address) const;

    mutable std::mutex m_listenerMutex;
    mutable std::set<PropertyListenerKey> m_registeredListeners;
};

} // namespace audio

#endif // AUDIO_MACOS_H
