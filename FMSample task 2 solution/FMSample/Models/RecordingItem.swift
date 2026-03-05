/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Model class for meeting items that represent recordings and their transcription.
*/

import Foundation
import FoundationModels
import CoreGraphics

@Observable
class RecordingItem: MeetingItem {
    override class var symbolName: String { "waveform" }
    override class var accessibilityLabel: String { "Recording" }
    
    // ❸ DECLARE image var
    
    static var emptyRecording: RecordingItem {
        RecordingItem(title: "New Recording", text: "")
    }
    
    @Generable
    struct RecordingTitle {
        var title: String
    }
    
    func suggestedTitle() async throws -> String? {
        guard SystemLanguageModel.default.isAvailable && isComplete else { return nil }
        let session = LanguageModelSession(model: SystemLanguageModel.default, instructions: "You are an expert headline writer who takes meeting transcripts as input: from those notes you MUST generate your best suggested title, with no other text.")
        
        do {
            let answer = try await session.respond(to: String(text.characters), generating: RecordingTitle.self)
            return answer.content.title.trimmingCharacters(in: .punctuationCharacters)
        } catch let error as LanguageModelSession.GenerationError {
            switch error {
            case .guardrailViolation:
                print("Generation was blocked due to safety guardrails: \(error)")
                throw error
            default:
                print("Generation error: \(error)")
                throw error
            }
        }
    }
    
    // ❸ IMPLEMENT suggestedIimage()
}
