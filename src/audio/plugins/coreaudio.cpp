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
#include "coreaudio.h"
#include <cstdlib>
#include <AudioToolbox/AudioToolbox.h>
#include <QtCore>

template <typename T> struct malloc_guard {
    malloc_guard()
    {
    }

    malloc_guard(const size_t &size)
    {
        setSize(size);
    }

    ~malloc_guard()
    {
        std::free(data);
    }

    void setSize(const size_t &size)
    {
        data = reinterpret_cast<T *>(std::malloc(size));
    }

    T *operator->()
    {
        return data;
    }

    T *data = nullptr;
};

namespace audio {

bool checkStatus(OSStatus status, QString message = "", std::list<OSStatus> goodStatuses = {noErr});

# define checkCall(foo, returnval, message) \
    if (!checkStatus(foo, message)) {\
    return returnval;\
};

static OSStatus audioObjectListener(AudioObjectID, UInt32, const AudioObjectPropertyAddress *, void *inClientData)
{
    auto plugin = reinterpret_cast<CoreaudioPlugin *>(inClientData);
    emit plugin->deviceListChanged();
    return noErr;
};

void CoreaudioPlugin::addPropertyListener(AudioObjectID id, const AudioObjectPropertyAddress &address) const
{
    std::lock_guard<std::mutex> guard(m_listenerMutex);
    PropertyListenerKey key{id, address};
    if (m_registeredListeners.find(key) == m_registeredListeners.end()) {
        OSStatus status = AudioObjectAddPropertyListener(id, &address, &audioObjectListener, const_cast<CoreaudioPlugin *>(this));
        if (status == noErr) {
            m_registeredListeners.insert(key);
        }
    }
}

size_t CoreaudioPlugin::registeredListenerCount() const
{
    std::lock_guard<std::mutex> guard(m_listenerMutex);
    return m_registeredListeners.size();
}

CoreaudioPlugin::CoreaudioPlugin() : Plugin()
{
    AudioObjectPropertyAddress propertyAddress = {
        kAudioHardwarePropertyDevices,
        kAudioObjectPropertyScopeGlobal,
        kAudioObjectPropertyElementMaster
    };
    addPropertyListener(kAudioObjectSystemObject, propertyAddress);
}

CoreaudioPlugin::~CoreaudioPlugin()
{
    emit stopStreams({});
    std::lock_guard<std::mutex> guard(m_listenerMutex);
    for (const auto &key : m_registeredListeners) {
        AudioObjectRemovePropertyListener(key.id, &key.address, &audioObjectListener, this);
    }
    m_registeredListeners.clear();
}

QString CoreaudioPlugin::name() const
{
    return "CoreAudio";
}

DeviceInfo::List CoreaudioPlugin::getDeviceInfoList() const
{
    DeviceInfo::List list;
    UInt32 propertyDataSize = 0;

    AudioObjectPropertyAddress propertyAddress = {
        kAudioHardwarePropertyDevices,
        kAudioObjectPropertyScopeGlobal,
        kAudioObjectPropertyElementMaster
    };

    checkCall(
        AudioObjectGetPropertyDataSize(kAudioObjectSystemObject, &propertyAddress, 0, NULL, &propertyDataSize),
        list,
        "kAudioHardwarePropertyDevices Size"
    );

    std::vector<AudioObjectID> deviceIDs;
    deviceIDs.resize(propertyDataSize / sizeof(AudioObjectID));
    checkCall(
        AudioObjectGetPropertyData(kAudioObjectSystemObject, &propertyAddress, 0, NULL, &propertyDataSize, deviceIDs.data()),
        list,
        "kAudioHardwarePropertyDevices Data"
    );

    propertyAddress.mSelector = kAudioDevicePropertyDeviceNameCFString;
    CFStringRef deviceNameRef;
    propertyDataSize = sizeof(deviceNameRef);
    list.reserve(deviceIDs.size());
    for (auto &deviceID : deviceIDs) {
        checkCall(
            AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, NULL, &propertyDataSize, &deviceNameRef),
            list,
            "kAudioDevicePropertyDeviceNameCFString"
        );

        DeviceInfo device(QString::number(deviceID), name());
        device.setName(QString::fromCFString(deviceNameRef));
        device.setDefaultSampleRate(getDeviceDefaultSampleRate(deviceID));
        device.setInputChannels(getDeviceChannelNames(deviceID, Input));
        device.setOutputChannels(getDeviceChannelNames(deviceID, Output));
        list.push_back(device);
        CFRelease(deviceNameRef);
    }
    return list;
}

DeviceInfo::Id CoreaudioPlugin::defaultDeviceId(const Plugin::Direction &mode) const
{
    AudioObjectID deviceId = 0;
    UInt32 propertyDataSize = sizeof(deviceId);

    AudioObjectPropertyAddress propertyAddress = {
        (mode == Input ? kAudioHardwarePropertyDefaultInputDevice : kAudioHardwarePropertyDefaultOutputDevice),
        kAudioObjectPropertyScopeGlobal,
        kAudioObjectPropertyElementMaster
    };

    checkCall(
        AudioObjectGetPropertyData(kAudioObjectSystemObject, &propertyAddress, 0, NULL, &propertyDataSize, &deviceId),
        0,
        "Default device data"
    );
    return QString::number(deviceId);
}

Format CoreaudioPlugin::deviceFormat(const DeviceInfo::Id &id, const Plugin::Direction &mode) const
{
    return {
        getDeviceDefaultSampleRate(id.toInt()),
        getDeviceChannelCount(id.toInt(), mode)
    };
}

unsigned int CoreaudioPlugin::getDeviceDefaultSampleRate(const int &deviceID) const
{
    AudioObjectPropertyAddress propertyAddress = {
        kAudioDevicePropertyNominalSampleRate,
        kAudioObjectPropertyScopeGlobal,
        kAudioObjectPropertyElementMaster
    };
    UInt32 propertyDataSize = sizeof (Float64);
    Float64 sampleRate;
    checkCall(AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, NULL, &propertyDataSize, &sampleRate),
              48000,
              "getDEviceDefaultSampleRate");

    return sampleRate;
}

unsigned int CoreaudioPlugin::getDeviceChannelCount(const int &deviceID, const Direction &direction) const
{
    AudioObjectPropertyAddress propertyAddress = {
        kAudioDevicePropertyStreamConfiguration,
        (direction == Input ? kAudioObjectPropertyScopeInput : kAudioObjectPropertyScopeOutput),
        kAudioObjectPropertyElementMaster
    };
    UInt32 propertyDataSize;
    malloc_guard<AudioBufferList> audioBuffers;

    checkCall(
        AudioObjectGetPropertyDataSize(deviceID, &propertyAddress, 0, NULL, &propertyDataSize),
        0,
        "kAudioDevicePropertyStreamConfiguration Size"
    );

    audioBuffers.setSize(propertyDataSize);
    checkCall(
        AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, NULL, &propertyDataSize, audioBuffers.data),
        0,
        "kAudioDevicePropertyStreamConfiguration Data"
    );

    unsigned int number = 0;
    for (unsigned int i = 0; i < audioBuffers->mNumberBuffers; ++i) {
        number += audioBuffers->mBuffers[i].mNumberChannels;
    }
    addPropertyListener(deviceID, propertyAddress);

    return number;
}

QStringList CoreaudioPlugin::getDeviceChannelNames(const int &deviceID, const Direction &direction) const
{
    QStringList list = {};
    auto channels = getDeviceChannelCount(deviceID, direction);
    list.reserve(channels);
    for (UInt32 channelNumber = 1; channelNumber <= channels; ++channelNumber) {
        CFStringRef channelNameRef;
        UInt32 channelNameSize = sizeof (channelNameRef);
        channelNameSize = sizeof (channelNameRef);
        AudioObjectPropertyAddress propertyAddress = {
            kAudioDevicePropertyChannelNameCFString,
            (direction == Input ? kAudioDevicePropertyScopeInput : kAudioDevicePropertyScopeOutput),
            kAudioObjectPropertyElementMaster
        };
        propertyAddress.mElement = channelNumber;
        checkCall(
            AudioObjectGetPropertyData(deviceID, &propertyAddress,
                                       0, NULL,
                                       &channelNameSize, &channelNameRef),
            list,
            "kAudioDevicePropertyChannelNameCFString"
        );
        auto name = QString::fromCFString(channelNameRef);
        list.push_back(name.isEmpty() ? QString::number(channelNumber) : name);
        addPropertyListener(deviceID, propertyAddress);
    }
    return list;
}

Stream *CoreaudioPlugin::open(const DeviceInfo::Id &id, const Plugin::Direction &mode, const Format &format,
                              QIODevice *endpoint)
{
    if (mode == Direction::Input && !microphoneAccessAllowed()) return nullptr;

    AudioStreamBasicDescription streamFormat;
    streamFormat.mSampleRate          = format.sampleRate;
    streamFormat.mFormatID            = kAudioFormatLinearPCM;
    streamFormat.mFormatFlags         = kAudioFormatFlagIsFloat;
    streamFormat.mChannelsPerFrame    = format.channelCount;
    streamFormat.mBitsPerChannel      = 32;
    streamFormat.mReserved            = 0;
    streamFormat.mBytesPerFrame       = streamFormat.mChannelsPerFrame * streamFormat.mBitsPerChannel / 8;
    streamFormat.mFramesPerPacket     = 1;
    streamFormat.mBytesPerPacket      = streamFormat.mBytesPerFrame;
    const int requestedOutputFrames = endpoint->property("outputBufferFrames").toInt();
    const int outputFrames = requestedOutputFrames > 0 ? std::clamp(requestedOutputFrames, 128, 8192) : 8192;
    auto bufferSize = streamFormat.mChannelsPerFrame * (mode == Input ? 1024 : outputFrames) * sizeof(float);

    AudioQueueRef queue;
    AudioQueueBufferRef buffers[3];

    struct StreamContext {
        QIODevice *endpoint{nullptr};
        std::atomic<bool> stopped{false};
    };
    auto context = new StreamContext{endpoint, false};

    auto outputCallback = [](void *inUserData, AudioQueueRef queue, AudioQueueBufferRef inBuffer) -> void {
        auto ctx = reinterpret_cast<StreamContext *>(inUserData);
        if (!ctx || ctx->stopped.load(std::memory_order_acquire)) return;
        auto endpoint = ctx->endpoint;
        if (endpoint && endpoint->isReadable())
        {
            endpoint->read(reinterpret_cast<char *>(inBuffer->mAudioData), inBuffer->mAudioDataByteSize);
            checkStatus(AudioQueueEnqueueBuffer(queue, inBuffer, 0, NULL), "AudioQueueEnqueueBuffer", {noErr, kAudioQueueErr_EnqueueDuringReset});
        }
    };

    auto inputCallback = [](void *inUserData, AudioQueueRef queue, AudioQueueBufferRef inBuffer,
    const AudioTimeStamp *, UInt32, const AudioStreamPacketDescription *) -> void {
        auto ctx = reinterpret_cast<StreamContext *>(inUserData);
        if (!ctx || ctx->stopped.load(std::memory_order_acquire)) return;
        auto endpoint = ctx->endpoint;
        if (endpoint && endpoint->isWritable())
        {
            endpoint->write(reinterpret_cast<char *>(inBuffer->mAudioData), inBuffer->mAudioDataByteSize);
            checkStatus(AudioQueueEnqueueBuffer(queue, inBuffer, 0, NULL), "AudioQueueEnqueueBuffer", {noErr, kAudioQueueErr_EnqueueDuringReset});
        }
    };

    switch (mode) {
    case Output: {
        if (endpoint->openMode() == QIODevice::NotOpen) {
            endpoint->open(QIODevice::ReadOnly);
        }
        if (!checkStatus(AudioQueueNewOutput(&streamFormat, outputCallback, context, NULL, NULL, 0, &queue), "AudioQueueNewOutput")) {
            delete context;
            return nullptr;
        }
        break;
    }
    case Input:
        if (endpoint->openMode() == QIODevice::NotOpen) {
            endpoint->open(QIODevice::WriteOnly);
        }
        if (!checkStatus(AudioQueueNewInput(&streamFormat, inputCallback, context, NULL, NULL, 0, &queue), "AudioQueueNewInput")) {
            delete context;
            return nullptr;
        }
        break;
    }

    CFStringRef deviceUID;
    UInt32 propertyDataSize = sizeof(deviceUID);
    AudioObjectPropertyAddress propertyAddress = {
        kAudioDevicePropertyDeviceUID,
        kAudioObjectPropertyScopeGlobal,
        kAudioObjectPropertyElementMaster
    };

    if (!checkStatus(
                AudioObjectGetPropertyData(id.toInt(), &propertyAddress, 0, NULL, &propertyDataSize, &deviceUID),
                "kAudioDevicePropertyDeviceUID"
            )) {
        AudioQueueDispose(queue, true);
        delete context;
        return nullptr;
    }

    AudioQueueSetProperty(queue, kAudioQueueProperty_CurrentDevice, &deviceUID, sizeof(deviceUID));
    CFRelease(deviceUID);

    for (int i = 0; i < 3; i++) {
        if (!checkStatus(AudioQueueAllocateBuffer(queue, bufferSize, &buffers[i]), "AudioQueueAllocateBuffer")) {
            AudioQueueDispose(queue, true);
            delete context;
            return nullptr;
        }
        buffers[i]->mAudioDataByteSize = bufferSize;
        switch (mode) {

        case Output:
            outputCallback(context, queue, buffers[i]);
            break;
        case Input:
            inputCallback(context, queue, buffers[i], nullptr, 0, nullptr);
            break;
        }
    }
    auto res = AudioQueueStart(queue, NULL);
    if (!checkStatus(res, "start output")) {
        AudioQueueDispose(queue, true);
        delete context;
        return nullptr;
    }

    auto stream = new Stream(format);
    stream->setDepth(std::size(buffers));
    connect(stream, &Stream::closeMe, this, [queue, stream, endpoint, context]() {
        context->stopped.store(true, std::memory_order_release);
        AudioQueueStop(queue, true);
        AudioQueueDispose(queue, true);
        if (endpoint) {
            endpoint->close();
        }
        delete context;
        delete stream;
    }, Qt::DirectConnection);
    connect(this, &CoreaudioPlugin::stopStreams, stream, [stream]() {
        stream->close();
    }, Qt::DirectConnection);
    return stream;
}

bool checkStatus(OSStatus status, QString message, std::list<OSStatus> goodStatuses)
{
    if (std::find(goodStatuses.begin(), goodStatuses.end(), status) != goodStatuses.end()) {
        return true;
    }
    union {
        char name[5];
        uint32_t code;
    } error;

    error.code = CFSwapInt32HostToBig(status);
    if (isprint(error.name[0]) && isprint(error.name[1]) && isprint(error.name[2]) && isprint(error.name[3])) {
        error.name[4] = '\0';
        qCritical() << "coreaudio error: '" << error.name << "' " << message;
    } else {
        qCritical() << "coreaudio error: " << status << message;
    }
    return false;
}
} // namespace audio
