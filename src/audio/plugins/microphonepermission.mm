// Check permission before entering CoreAudio's synchronous input-open path.
#include <AVFoundation/AVFoundation.h>
#include <atomic>
#include "coreaudio.h"

namespace audio {
bool microphoneAccessAllowed()
{
    if (@available(macOS 10.14, *)) {
        const auto status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
        if (status == AVAuthorizationStatusNotDetermined) {
            static std::atomic<bool> requested {false};
            if (!requested.exchange(true)) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL) {}];
                });
            }
        }
        return status == AVAuthorizationStatusAuthorized;
    }
    return true;
}
}
