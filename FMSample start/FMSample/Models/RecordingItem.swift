/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Model class for meeting items that represent recordings and their transcription.
*/

import Foundation
import CoreGraphics

@Observable
class RecordingItem: MeetingItem {
    override class var symbolName: String { "waveform" }
    override class var accessibilityLabel: String { "Recording" }

    static var emptyRecording: RecordingItem {
        RecordingItem(title: "New Recording", text: "")
    }
}
