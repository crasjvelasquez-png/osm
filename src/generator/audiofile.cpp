#include "audiofile.h"
#include "generatorthread.h"
#include <QFileInfo>
#include <algorithm>
#include <cmath>
#include <cstring>
#include <memory>
#ifdef Q_OS_MACOS
#include <AudioToolbox/AudioToolbox.h>
#endif

AudioFile::AudioFile(QObject *parent) : OutputDevice(parent)
{
    m_name = "Audio file";
    setProperty("outputBufferFrames", 512);
}

void AudioFile::load(const QUrl &url)
{
    std::vector<float> pcm;
    QString error;
    double rate = 0;
    int channels = 0;
#ifdef Q_OS_MACOS
    const auto encoded = url.toEncoded();
    auto fileUrl = CFURLCreateWithBytes(nullptr, reinterpret_cast<const UInt8 *>(encoded.constData()),
                                      encoded.size(), kCFStringEncodingUTF8, nullptr);
    ExtAudioFileRef file = nullptr;
    OSStatus result = fileUrl ? ExtAudioFileOpenURL(fileUrl, &file) : -1;
    if (fileUrl) CFRelease(fileUrl);
    if (result == noErr) {
        AudioStreamBasicDescription source {};
        UInt32 size = sizeof(source);
        result = ExtAudioFileGetProperty(file, kExtAudioFileProperty_FileDataFormat, &size, &source);
        rate = source.mSampleRate;
        channels = source.mChannelsPerFrame;
        if (result == noErr && rate > 0 && (channels == 1 || channels == 2)) {
            AudioStreamBasicDescription target {};
            target.mSampleRate = rate;
            target.mFormatID = kAudioFormatLinearPCM;
            target.mFormatFlags = kAudioFormatFlagsNativeFloatPacked;
            target.mBytesPerPacket = target.mBytesPerFrame = channels * sizeof(float);
            target.mFramesPerPacket = 1;
            target.mChannelsPerFrame = channels;
            target.mBitsPerChannel = 32;
            result = ExtAudioFileSetProperty(file, kExtAudioFileProperty_ClientDataFormat, sizeof(target), &target);
            constexpr size_t maxSamples = 512 * 1024 * 1024 / sizeof(float);
            float block[8192];
            while (result == noErr) {
                UInt32 frames = 8192 / channels;
                AudioBufferList buffers {};
                buffers.mNumberBuffers = 1;
                buffers.mBuffers[0] = {static_cast<UInt32>(channels), sizeof(block), block};
                result = ExtAudioFileRead(file, &frames, &buffers);
                if (result != noErr || !frames) break;
                if (pcm.size() + frames * channels > maxSamples) {
                    error = tr("File is too long (512 MB decoded limit). Choose a shorter audio file.");
                    break;
                }
                pcm.insert(pcm.end(), block, block + frames * channels);
            }
        } else {
            error = tr("Choose a mono or stereo audio file.");
        }
        ExtAudioFileDispose(file);
    }
    if (result != noErr && error.isEmpty())
        error = tr("Could not decode this file. Choose a valid, unprotected WAV, AIFF, MP3, M4A, AAC, FLAC or CAF file.");
#else
    Q_UNUSED(url)
    error = tr("Audio-file decoding is currently available in the macOS build.");
#endif
    if (pcm.empty() && error.isEmpty()) error = tr("This audio file is empty.");
    // Reject non-finite decoded samples before they reach an output or measurement.
    if (error.isEmpty() && !std::all_of(pcm.begin(), pcm.end(), [](float v) { return std::isfinite(v); }))
        error = tr("This file contains invalid audio samples. Choose another file.");
    std::lock_guard<std::mutex> lock(m_mutex);
    m_error = error;
    if (!error.isEmpty()) return; // A failed replacement preserves the previous file, paused.
    m_pcm = std::move(pcm);
    m_path = url.toLocalFile();
    m_rate = rate;
    m_fileChannels = channels;
    m_start = m_position = 0;
    m_end = double(m_pcm.size() / channels);
    m_finished = false;
}

QVariantMap AudioFile::info() const
{
    std::lock_guard<std::mutex> lock(m_mutex);
    return {{"name", QFileInfo(m_path).fileName()}, {"path", m_path}, {"error", m_error},
            {"ready", !m_pcm.empty()}, {"duration", m_rate ? m_pcm.size() / m_fileChannels / m_rate : 0},
            {"position", m_rate ? m_position / m_rate : 0}, {"sampleRate", m_rate},
            {"channels", m_fileChannels}, {"loop", m_loop}, {"mode", m_mode},
            {"start", m_rate ? m_start / m_rate : 0}, {"end", m_rate ? m_end / m_rate : 0}};
}

bool AudioFile::ready() const { std::lock_guard<std::mutex> lock(m_mutex); return !m_pcm.empty(); }
bool AudioFile::playbackAtEnd() const { std::lock_guard<std::mutex> lock(m_mutex); return m_finished; }
void AudioFile::seekSeconds(double seconds)
{
    if (!std::isfinite(seconds)) return;
    std::lock_guard<std::mutex> lock(m_mutex);
    m_position = std::clamp(seconds * m_rate, m_start, m_end);
    m_finished = false;
}
void AudioFile::setLoop(bool enabled) { std::lock_guard<std::mutex> lock(m_mutex); m_loop = enabled; }
void AudioFile::setMode(int mode) { std::lock_guard<std::mutex> lock(m_mutex); m_mode = std::clamp(mode, 0, 3); }
void AudioFile::setRegion(double start, double end)
{
    if (!std::isfinite(start) || !std::isfinite(end)) return;
    std::lock_guard<std::mutex> lock(m_mutex);
    const double frames = m_fileChannels ? m_pcm.size() / m_fileChannels : 0;
    if (start < 0 || end * m_rate > frames + 0.5 || (end - start) * m_rate < 1) return;
    m_start = start * m_rate;
    m_end = std::min(end * m_rate, frames);
    m_position = std::clamp(m_position, m_start, m_end);
    m_finished = false;
}
void AudioFile::setSamplerate(int rate) { std::lock_guard<std::mutex> lock(m_mutex); OutputDevice::setSamplerate(rate); }
void AudioFile::setChanelCount(int count) { std::lock_guard<std::mutex> lock(m_mutex); OutputDevice::setChanelCount(count); }
void AudioFile::setGain(float gain) { std::lock_guard<std::mutex> lock(m_mutex); OutputDevice::setGain(gain); }

qint64 AudioFile::readData(char *data, qint64 maxlen)
{
    auto generator = static_cast<GeneratorThread *>(parent());
    return render(data, maxlen, generator->channels().values(), generator->evenPolarity());
}

qint64 AudioFile::render(char *data, qint64 maxlen, QList<int> selected, bool invert)
{
    std::sort(selected.begin(), selected.end());
    bool finished = false;
    {
        std::lock_guard<std::mutex> lock(m_mutex);
        std::memset(data, 0, maxlen);
        if (m_pcm.empty() || m_sampleRate <= 0 || m_chanelCount <= 0) return maxlen;
        const auto frames = maxlen / (sizeof(float) * m_chanelCount);
        const auto totalFrames = m_pcm.size() / m_fileChannels;
        for (size_t frame = 0; frame < frames; ++frame) {
            if (m_position >= m_end) {
                if (m_loop) m_position = m_start + std::fmod(m_position - m_start, m_end - m_start);
                else {
                    if (!m_finished) finished = true;
                    m_finished = true;
                    break;
                }
            }
            const size_t index = size_t(m_position);
            const size_t next = std::min(index + 1, totalFrames - 1);
            const float fraction = m_position - index;
            const auto channelSample = [&](int ch) {
                ch = std::min(ch, m_fileChannels - 1);
                return m_pcm[index * m_fileChannels + ch] * (1 - fraction)
                       + m_pcm[next * m_fileChannels + ch] * fraction;
            };
            const float left = channelSample(0), right = channelSample(1);
            const float mono = (left + right) * 0.5f;
            float reference = 0;
            int ordinal = 0;
            for (const int channel : selected) {
                if (channel < 0 || channel >= m_chanelCount) continue;
                float sample = m_mode == 1 ? mono : m_mode == 2 ? left : m_mode == 3 ? right
                               : (ordinal % 2 ? right : left);
                sample *= m_gain;
                if (channel % 2 && invert) sample = -sample;
                if (!ordinal) reference = sample;
                std::memcpy(data + (frame * m_chanelCount + channel) * sizeof(float), &sample, sizeof(float));
                ++ordinal;
            }
            // The internal reference follows the first selected output, including gain/polarity.
            emit sampleOut(reference);
            m_position = std::min(m_position + m_rate / m_sampleRate, m_end);
            if (m_loop && m_position >= m_end)
                m_position = m_start + std::fmod(m_position - m_start, m_end - m_start);
        }
    }
    if (finished) emit playbackFinished();
    return maxlen;
}
