/**
 *  OSM
 *  Copyright (C) 2020  Pavel Smokotnin

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
#include "spectrogramplot.h"
#include <algorithm>
#include <cmath>

using namespace Chart;

SpectrogramPlot::SpectrogramPlot(Settings *settings, QQuickItem *parent): FrequencyBasedPlot(settings, parent),
    m_min(-57), m_mid(-44), m_max(-38), m_active(true)
{
    // Keep the heat map within the audible range, including restored views and gestures.
    m_x.configure(AxisType::Logarithmic, 12.f, 20'000.f);
    m_x.setReset(20.f, 20'000.f);
    m_x.reset();
    m_y.configure(AxisType::Linear, 0.f,    4.f,  4);
    setPointsPerOctave(24);
    setFlag(QQuickItem::ItemHasContents);
    m_y.setCentralLabel(m_y.min() - 1.f);
    m_y.setUnit("s");
    connect(this, SIGNAL(pointsPerOctaveChanged(unsigned int)), this, SLOT(update()));
    connect(this, &FrequencyBasedPlot::pointsPerOctaveChanged, this, [this]() {
        m_history.clear();
        ++m_historyRevision;
        emit historyChanged();
    });
    connect(this, &Plot::selectedChanged, this, [this]() {
        m_history.clear();
        ++m_historyRevision;
        emit historyChanged();
    });
}

void SpectrogramPlot::setSettings(Settings *settings) noexcept
{
    if (settings && (settings->value("type") == "Spectrogram")) {
        FrequencyBasedPlot::setSettings(settings);
    }

    setMin(m_settings->reactValue<SpectrogramPlot, int>("dBMin", this, &SpectrogramPlot::minChanged,
                                                        m_min).toInt());
    setMid(m_settings->reactValue<SpectrogramPlot, int>("dBMid", this, &SpectrogramPlot::midChanged,
                                                        m_mid).toInt());
    setMax(m_settings->reactValue<SpectrogramPlot, int>("dBMax", this, &SpectrogramPlot::maxChanged,
                                                        m_max).toInt());
}

void SpectrogramPlot::storeSettings() noexcept
{
    if (!m_settings)
        return;

    FrequencyBasedPlot::storeSettings();
    m_settings->setValue("type", "Spectrogram");
    m_settings->setValue("dBMin", m_min);
    m_settings->setValue("dBMid", m_mid);
    m_settings->setValue("dBMax", m_max);
}

int SpectrogramPlot::max() const
{
    return m_max;
}

void SpectrogramPlot::setMax(int max)
{
    if (m_max != max) {
        m_max = max;
        emit maxChanged(m_max);
    }
}

bool SpectrogramPlot::active() const
{
    return m_active;
}

void SpectrogramPlot::setActive(bool active)
{
    if (m_active != active) {
        m_active = active;
        emit activeChanged(m_active);
    }
}

int SpectrogramPlot::mid() const
{
    return m_mid;
}

void SpectrogramPlot::setMid(int mid)
{
    if (m_mid != mid) {
        m_mid = mid;
        emit midChanged(m_mid);
    }
}

int SpectrogramPlot::min() const
{
    return m_min;
}

void SpectrogramPlot::setMin(int min)
{
    if (m_min != min) {
        m_min = min;
        emit minChanged(m_min);
    }
}

int SpectrogramPlot::historyRevision() const noexcept
{
    return m_historyRevision;
}

void SpectrogramPlot::trackSource(const Shared::Source &source)
{
    if (!source) {
        return;
    }
    const QUuid uuid = source->uuid();
    for (const auto &existing : m_trackedSources) {
        if (existing && existing->uuid() == uuid) {
            return;
        }
    }
    m_trackedSources.push_back(source);
    connect(source.get(), &Abstract::Source::readyRead, this, [this, uuid]() {
        recordHistoryForSource(uuid);
    });
    connect(source.get(), &Abstract::Source::beforeDestroy, this, [this, uuid](auto) {
        for (int i = m_trackedSources.size() - 1; i >= 0; --i) {
            if (!m_trackedSources[i] || m_trackedSources[i]->uuid() == uuid) {
                m_trackedSources.removeAt(i);
            }
        }
    });
}

std::vector<SpectrogramPlot::BandMetric> SpectrogramPlot::collectBandsForSource(const Shared::Source &source) const
{
    std::vector<BandMetric> bands;
    if (!source || source->frequencyDomainSize() < 2) {
        return bands;
    }

    const unsigned int ppo = pointsPerOctave();
    bands.reserve(ppo > 0 ? ppo * 11 : source->frequencyDomainSize());

    constexpr float floorDb = -140.f;
    constexpr float startFrequency = 24000.f / 2048.f;
    const float frequencyFactor = ppo > 0 ? std::pow(2.f, 1.f / ppo) : 1.f;
    float bandStart = startFrequency;
    float bandEnd = bandStart * frequencyFactor;
    float lastBandEnd = bandStart;
    unsigned int count = 0;
    float powerSum = 0.f;

    auto pushBand = [&](float start, float end) {
        float db = 10.f * std::log10(powerSum);
        if (!std::isnormal(db) || db < floorDb) {
            db = floorDb;
        }
        bands.push_back(BandMetric{(start + end) * 0.5f, start, end, db});
        powerSum = 0.f;
    };

    source->lock();
    const unsigned int size = source->frequencyDomainSize();
    for (unsigned int i = 1; i < size; ++i) {
        const float freq = source->frequency(i);
        if (freq < bandStart) {
            continue;
        }
        if (ppo > 0) {
            while (freq > bandEnd) {
                if (count > 0) {
                    pushBand(lastBandEnd, bandEnd);
                    count = 0;
                    lastBandEnd = bandEnd;
                }
                bandStart = bandEnd;
                bandEnd *= frequencyFactor;
            }
        } else {
            if (count > 0) {
                const float delta = (freq - lastBandEnd) * 0.5f;
                pushBand(freq - delta, freq + delta);
            }
            lastBandEnd = freq;
            count = 0;
        }
        ++count;
        const float mod = source->module(i);
        powerSum += mod * mod;
    }
    if (count > 0) {
        pushBand(lastBandEnd, bandEnd);
    }
    source->unlock();

    return bands;
}

void SpectrogramPlot::recordHistoryForSource(const QUuid &uuid)
{
    if (!m_active || !isSelected(uuid)) {
        return;
    }

    Shared::Source activeSource;
    for (const auto &candidate : m_trackedSources) {
        if (candidate && candidate->uuid() == uuid) {
            activeSource = candidate;
            break;
        }
    }
    if (!activeSource || !activeSource->active() || activeSource->frequencyDomainSize() < 2) {
        return;
    }

    auto bands = collectBandsForSource(activeSource);
    if (bands.empty()) {
        return;
    }

    MetricRow row;
    row.timeMs = m_historyTimer.isValid() ? static_cast<int>(m_historyTimer.restart()) : 20;
    if (!m_historyTimer.isValid()) {
        m_historyTimer.start();
    }
    row.bands = std::move(bands);

    m_history.push_back(std::move(row));
    while (m_history.size() > MAX_HISTORY) {
        m_history.pop_front();
    }
    ++m_historyRevision;
    emit historyChanged();
}

QVariantMap SpectrogramPlot::hoverAdvice(qreal mouseX, qreal mouseY) const noexcept
{
    QVariantMap result;
    result.insert("available", false);

    const qreal cursorFreq = x2v(mouseX);
    const qreal cursorTimeSec = y2v(mouseY);
    if (!std::isfinite(cursorFreq) || cursorFreq <= 0.0) {
        return result;
    }

    const std::vector<BandMetric> *bandsPtr = nullptr;
    std::vector<BandMetric> fallbackBands;

    if (!m_history.empty()) {
        const float targetTime = static_cast<float>(std::max<qreal>(0.0, cursorTimeSec));
        float accumulatedSec = 0.f;
        float bestDiff = 1e9f;
        for (auto it = m_history.crbegin(); it != m_history.crend(); ++it) {
            const float diff = std::abs(accumulatedSec - targetTime);
            if (diff < bestDiff && !it->bands.empty()) {
                bestDiff = diff;
                bandsPtr = &it->bands;
            }
            accumulatedSec += static_cast<float>(it->timeMs) / 1000.f;
        }
    }

    if (!bandsPtr) {
        for (const auto &candidate : m_trackedSources) {
            if (candidate && isSelected(candidate->uuid()) && candidate->frequencyDomainSize() >= 2) {
                fallbackBands = collectBandsForSource(candidate);
                if (!fallbackBands.empty()) {
                    bandsPtr = &fallbackBands;
                    break;
                }
            }
        }
    }

    if (!bandsPtr || bandsPtr->size() < 3) {
        return result;
    }

    const auto &bands = *bandsPtr;
    const int n = static_cast<int>(bands.size());

    int closestIdx = 0;
    float bestLogDist = 1e9f;
    for (int i = 0; i < n; ++i) {
        if (bands[i].freq <= 0.f) {
            continue;
        }
        const float d = std::abs(std::log(bands[i].freq / static_cast<float>(cursorFreq)));
        if (d < bestLogDist) {
            bestLogDist = d;
            closestIdx = i;
        }
    }

    // Snap within ±1 band so hovering the edge of a narrow feedback line locks onto the peak.
    int peakIdx = closestIdx;
    for (int i = std::max(0, closestIdx - 1); i <= std::min(n - 1, closestIdx + 1); ++i) {
        if (bands[i].db > bands[peakIdx].db) {
            peakIdx = i;
        }
    }

    const float peakDb = bands[peakIdx].db;
    const float peakFreq = bands[peakIdx].freq;
    if (peakDb <= -135.f || peakFreq <= 0.f) {
        return result;
    }

    const unsigned int ppo = std::max(1u, pointsPerOctave());
    const int halfWin = std::max(4, static_cast<int>(std::round(static_cast<float>(ppo) * 0.5f)));

    auto flankBaseline = [&](int startIdx, int endIdx, bool &ok) -> float {
        std::vector<float> vals;
        for (int i = startIdx; i <= endIdx; ++i) {
            if (i >= 0 && i < n && bands[i].db > -135.f) {
                vals.push_back(bands[i].db);
            }
        }
        if (vals.empty()) {
            ok = false;
            return peakDb;
        }
        std::sort(vals.begin(), vals.end());
        ok = true;
        return vals[(vals.size() - 1) / 4];
    };

    bool leftOk = false, rightOk = false;
    const float leftBase = flankBaseline(std::max(0, peakIdx - halfWin), peakIdx - 1, leftOk);
    const float rightBase = flankBaseline(peakIdx + 1, std::min(n - 1, peakIdx + halfWin), rightOk);
    if (!leftOk && !rightOk) {
        return result;
    }
    const float baselineDb = (leftOk && rightOk) ? 0.5f * (leftBase + rightBase)
                           : (leftOk ? leftBase : rightBase);

    const float prominenceDb = std::max(0.f, peakDb - baselineDb);
    const float cutDb = -std::min(18.f, prominenceDb);

    result.insert("available", true);
    result.insert("frequency", peakFreq);
    result.insert("prominenceDb", prominenceDb);
    result.insert("cutDb", cutDb);

    if (prominenceDb < 0.2f) {
        result.insert("hasQ", false);
        result.insert("q", 0.0);
        return result;
    }

    const float dropDb = std::min(3.0f, 0.5f * prominenceDb);
    const float targetDb = peakDb - dropDb;

    float fLow = bands[peakIdx].start;
    for (int i = peakIdx - 1; i >= std::max(0, peakIdx - halfWin); --i) {
        if (bands[i].db <= targetDb) {
            const float hiDb = bands[i + 1].db;
            const float loDb = bands[i].db;
            const float t = std::clamp((hiDb - targetDb) / std::max(0.01f, hiDb - loDb), 0.f, 1.f);
            const float logF = std::log(bands[i + 1].freq) - t * (std::log(bands[i + 1].freq) - std::log(bands[i].freq));
            fLow = std::exp(logF);
            break;
        }
        fLow = bands[i].start;
    }

    float fHigh = bands[peakIdx].end;
    for (int i = peakIdx + 1; i <= std::min(n - 1, peakIdx + halfWin); ++i) {
        if (bands[i].db <= targetDb) {
            const float hiDb = bands[i - 1].db;
            const float loDb = bands[i].db;
            const float t = std::clamp((hiDb - targetDb) / std::max(0.01f, hiDb - loDb), 0.f, 1.f);
            const float logF = std::log(bands[i - 1].freq) + t * (std::log(bands[i].freq) - std::log(bands[i - 1].freq));
            fHigh = std::exp(logF);
            break;
        }
        fHigh = bands[i].end;
    }

    const float minBandWidth = std::max(0.5f, bands[peakIdx].end - bands[peakIdx].start);
    const float bandwidth = std::max(minBandWidth, fHigh - fLow);
    const float q = std::clamp(peakFreq / bandwidth, 0.7f, 16.0f);

    result.insert("hasQ", true);
    result.insert("q", q);
    return result;
}

QString SpectrogramPlot::hoverMetricsText(qreal mouseX, qreal mouseY) const noexcept
{
    const QVariantMap advice = hoverAdvice(mouseX, mouseY);
    if (!advice.value("available").toBool()) {
        return QString();
    }
    const double cutDb = advice.value("cutDb").toDouble();
    if (!advice.value("hasQ").toBool()) {
        return QStringLiteral("0.0 dB · Q —");
    }
    const double q = advice.value("q").toDouble();
    return QString::asprintf("%.1f dB · Q %.1f", cutDb, q);
}
