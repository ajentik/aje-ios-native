/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
Live transcription code.
*/

import Foundation
import Speech
import SwiftUI

@Observable
final class SpokenWordTranscriber {
    private var recognizerTask: Task<(), Error>?
    // ❶ DECLARE PRIVATE VARS

    static let magenta = Color(red: 0.54, green: 0.02, blue: 0.6).opacity(0.8) // #e81cff

    // The format of the audio.
    var analyzerFormat: AVAudioFormat?

    var converter = BufferConverter()
    var downloadProgress: Progress?

    var meetingItem: Binding<RecordingItem>

    @MainActor var volatileTranscript: AttributedString = ""
    @MainActor var finalizedTranscript: AttributedString = ""

    static let locale = Locale(components: .init(languageCode: .english, script: nil, languageRegion: .unitedStates))

    init(meetingItem: Binding<RecordingItem>) {
        self.meetingItem = meetingItem
    }

    // ❶ IMPLEMENT FUNCTION
    func setUpTranscriber() async throws {
        throw TranscriptionError.failedToSetupRecognitionStream
    }

    func updateItemWithNewText(withFinal str: AttributedString) {
        meetingItem.text.wrappedValue.append(str)
    }

    // ❶ IMPLEMENT FUNCTION
    func streamAudioToTranscriber(_ buffer: AVAudioPCMBuffer) async throws {
    }

    // ❶ IMPLEMENT FUNCTION
    public func finishTranscribing() async throws {
        recognizerTask?.cancel()
        recognizerTask = nil
    }
}

public enum TranscriptionError: Error {
    case couldNotDownloadModel
    case failedToSetupRecognitionStream
    case invalidAudioDataType
    case localeNotSupported
    case noInternetForModelDownload
    case audioFilePathNotFound

    var descriptionString: String {
        switch self {

        case .couldNotDownloadModel:
            "Could not download the model."
        case .failedToSetupRecognitionStream:
            "Could not set up the speech recognition stream."
        case .invalidAudioDataType:
            "Unsupported audio format."
        case .localeNotSupported:
            "This locale is not yet supported by SpeechAnalyzer."
        case .noInternetForModelDownload:
            "The model could not be downloaded because the user is not connected to internet."
        case .audioFilePathNotFound:
            "Couldn't write audio to file."
        }
    }
}

public struct AudioData: @unchecked Sendable {
    var buffer: AVAudioPCMBuffer
    var time: AVAudioTime
}

extension SpokenWordTranscriber {
    public func ensureModel(transcriber: SpeechTranscriber, locale: Locale) async throws {
        guard await supported(locale: locale) else {
            throw TranscriptionError.localeNotSupported
        }

        if await installed(locale: locale) {
            return
        } else {
            try await downloadIfNeeded(for: transcriber)
        }
    }

    func supported(locale: Locale) async -> Bool {
        let supported = await SpeechTranscriber.supportedLocales
        return supported.map { $0.language }.contains(locale.language)
    }

    func installed(locale: Locale) async -> Bool {
        let installed = await Set(SpeechTranscriber.installedLocales)
        return installed.map { $0.language }.contains(locale.language)
    }

    func downloadIfNeeded(for module: SpeechTranscriber) async throws {
        if let downloader = try await AssetInventory.assetInstallationRequest(supporting: [module]) {
            downloadProgress = downloader.progress
            try await downloader.downloadAndInstall()
        }
    }

    func releaseLocales() async {
        let reserved = await AssetInventory.reservedLocales
        for locale in reserved {
            await AssetInventory.release(reservedLocale: locale)
        }
    }
}
