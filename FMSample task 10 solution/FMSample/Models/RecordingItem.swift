/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Model class for meeting items that represent recordings and their transcription.
*/

import Foundation
import FoundationModels
import CoreGraphics
import ImagePlayground

@Observable
class RecordingItem: MeetingItem {
    override class var symbolName: String { "waveform" }
    override class var accessibilityLabel: String { "Recording" }

    var image: CGImage?
    var isGeneratingImage = false

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

    @Generable
    struct ImagePrompt {
        @Guide(description: "A simple description of an image, that can be provided to Image Playground as a concept")
        var prompt: String
    }

    func suggestedImage() async throws -> CGImage? {
        guard SystemLanguageModel.default.isAvailable && isComplete else { return nil }
        let session = LanguageModelSession(model: SystemLanguageModel.default, instructions: "You are a helpful assistant that takes meeting notes as input, and from those notes you extract three or four terms that can be used to visualize the key concepts in the notes by using Image Playground. You must output only a string that can be used by Image Playground to generate an image.")

        do {
            let answer = try await session.respond(to: String(text.characters), generating: ImagePrompt.self)

            let concept = ImagePlaygroundConcept.extracted(from: answer.content.prompt)
            let creator = try await ImageCreator()
            let imageSequence = creator.images(for: [concept], style: .sketch, limit: 1)
            for try await image in imageSequence {
                return image.cgImage
            }
            return nil
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
}
