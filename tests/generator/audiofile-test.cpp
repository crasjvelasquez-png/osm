#include <QtTest>
#include <QFile>
#include <QProcess>
#include <QTemporaryDir>
#include "generator/audiofile.h"
#include "generator/generatorthread.h"

// Hardware routing is injected into render(); no audio device is opened by these tests.
QSet<int> GeneratorThread::channels() const { return {}; }
bool GeneratorThread::evenPolarity() const { return false; }

class AudioFileTest : public QObject
{
    Q_OBJECT
    QTemporaryDir fixtures;
    QString wav;
    void load(AudioFile &file) { file.load(QUrl::fromLocalFile(wav)); QVERIFY(file.ready()); }
    QVector<float> render(AudioFile &file, int frames, QList<int> channels = {0, 1}, bool invert = false) {
        QVector<float> result(frames * 2);
        file.render(reinterpret_cast<char *>(result.data()), result.size() * sizeof(float), channels, invert);
        return result;
    }

signals:
    void gainChanged(float gain);

private slots:
    void initTestCase() {
        wav = fixtures.path() + "/fixture.wav";
        // Different, constant L/R samples make routing, gain and resampling observable.
        QStringList args = {"-v", "error", "-f", "lavfi", "-i", "aevalsrc=0.25|-0.5:s=44100:d=0.1", "-c:a", "pcm_f32le", wav};
        QCOMPARE(QProcess::execute("/opt/homebrew/bin/ffmpeg", args), 0);
    }
    void formats_data() {
        QTest::addColumn<QString>("suffix"); QTest::addColumn<QString>("codec");
        QTest::newRow("WAV float") << "wav" << "pcm_f32le";
        QTest::newRow("WAV 24-bit") << "wav" << "pcm_s24le";
        QTest::newRow("AIFF") << "aiff" << "pcm_s24be";
        QTest::newRow("MP3") << "mp3" << "libmp3lame";
        QTest::newRow("AAC M4A") << "m4a" << "aac";
        QTest::newRow("ALAC") << "m4a" << "alac";
        QTest::newRow("AAC ADTS") << "aac" << "aac";
        QTest::newRow("FLAC") << "flac" << "flac";
        QTest::newRow("CAF") << "caf" << "pcm_f32le";
    }
    void formats() {
        QFETCH(QString, suffix); QFETCH(QString, codec);
        const auto target = fixtures.path() + "/" + codec + "." + suffix;
        QCOMPARE(QProcess::execute("/opt/homebrew/bin/ffmpeg", {"-v", "error", "-y", "-i", wav, "-c:a", codec, target}), 0);
        AudioFile file(this); file.load(QUrl::fromLocalFile(target));
        QVERIFY2(file.ready(), qPrintable(file.info()["error"].toString()));
        QCOMPARE(file.info()["channels"].toInt(), 2);
        QVERIFY(file.info()["duration"].toDouble() >= 0.09);
        file.setSamplerate(48000); file.setChanelCount(2);
        const auto output = render(file, 4800);
        QVERIFY(std::any_of(output.begin(), output.end(), [](float v) { return std::abs(v) > 0.01; }));
    }
    void routingGainAndResampling() {
        AudioFile file(this); load(file);
        file.setSamplerate(48000); file.setChanelCount(2); file.setGain(-6.0206f);
        auto output = render(file, 480);
        QVERIFY(std::abs(output[0] - 0.125f) < 0.0001f);
        QVERIFY(std::abs(output[1] + 0.25f) < 0.0001f);
        QVERIFY(std::abs(file.info()["position"].toDouble() - 0.01) < 0.0001);
        file.seekSeconds(0); file.setMode(1); output = render(file, 1);
        QVERIFY(std::abs(output[0] + 0.0625f) < 0.0001f);
        file.setMode(2); output = render(file, 1, {1});
        QCOMPARE(output[0], 0.f); QVERIFY(std::abs(output[1] - 0.125f) < 0.0001f);
        file.setMode(3); output = render(file, 1, {0, 1}, true);
        QVERIFY(std::abs(output[0] + 0.25f) < 0.0001f);
        QVERIFY(std::abs(output[1] - 0.25f) < 0.0001f);
    }
    void regionLoopSeekAndEnd() {
        AudioFile file(this); load(file); file.setSamplerate(44100); file.setChanelCount(2);
        file.setRegion(0.02, 0.04); file.seekSeconds(-1);
        QCOMPARE(file.info()["position"].toDouble(), 0.02);
        file.setLoop(true); render(file, 4410);
        QVERIFY(!file.playbackAtEnd());
        QVERIFY(file.info()["position"].toDouble() >= 0.02);
        QVERIFY(file.info()["position"].toDouble() < 0.04);
        file.setLoop(false); QSignalSpy finished(&file, &AudioFile::playbackFinished);
        render(file, 4410); QVERIFY(file.playbackAtEnd()); QCOMPARE(finished.count(), 1);
        auto silence = render(file, 128); QCOMPARE(finished.count(), 1);
        for (float value : silence) QCOMPARE(value, 0.f);
        file.seekSeconds(0.02); QVERIFY(!file.playbackAtEnd());
        file.setRegion(0.05, 0.01); QCOMPARE(file.info()["start"].toDouble(), 0.02);
    }
    void failedReplacementAndMono() {
        AudioFile file(this); load(file);
        file.load(QUrl::fromLocalFile(fixtures.path() + "/missing.mp3"));
        QVERIFY(file.ready()); QVERIFY(!file.info()["error"].toString().isEmpty());
        const auto mono = fixtures.path() + "/mono.wav";
        QCOMPARE(QProcess::execute("/opt/homebrew/bin/ffmpeg", {"-v", "error", "-i", wav, "-ac", "1", mono}), 0);
        file.load(QUrl::fromLocalFile(mono)); QCOMPARE(file.info()["channels"].toInt(), 1);
        QVERIFY(file.info()["error"].toString().isEmpty());
        file.setSamplerate(48000); file.setChanelCount(2);
        auto output = render(file, 100); QCOMPARE(output[0], output[1]);
    }
};
QTEST_GUILESS_MAIN(AudioFileTest)
#include "audiofile-test.moc"
