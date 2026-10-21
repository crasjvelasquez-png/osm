#ifndef GENERATOR_AUDIOFILE_H
#define GENERATOR_AUDIOFILE_H

#include "outputdevice.h"
#include <QUrl>
#include <QVariantMap>
#include <mutex>
#include <vector>

// Decoding runs on the generator thread. The audio callback reads only decoded PCM.
class AudioFile final : public OutputDevice
{
    Q_OBJECT
public:
    explicit AudioFile(QObject *parent);
    void load(const QUrl &url);
    QVariantMap info() const;
    bool ready() const;
    bool playbackAtEnd() const;
    bool isSequential() const override { return true; }
    bool open(OpenMode mode) override { return QIODevice::open(mode | QIODevice::Unbuffered); }
    void seekSeconds(double seconds);
    void setLoop(bool enabled);
    void setRegion(double start, double end);
    void setMode(int mode);
    qint64 readData(char *data, qint64 maxlen) override;
    qint64 render(char *data, qint64 maxlen, QList<int> selected, bool invert);
    void setSamplerate(int rate) override;
    void setChanelCount(int count) override;
    void setGain(float gain) override;

signals:
    void playbackFinished();

private:
    mutable std::mutex m_mutex;
    std::vector<float> m_pcm;
    QString m_path, m_error;
    double m_rate = 0, m_position = 0, m_start = 0, m_end = 0;
    int m_fileChannels = 0, m_mode = 0;
    bool m_loop = false, m_finished = false;
};
#endif
