/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Thumbs up/down controls for providing feedback.
*/

import SwiftUI
import FoundationModels

enum FeedbackState {
    case none
    case thumbsUp
    case thumbsDown
}

struct FeedbackButtons: View {
    @Binding var feedbackState: FeedbackState
    let session: LanguageModelSession

    @State private var showingFeedbackDialog = false

    init(
        feedbackState: Binding<FeedbackState>,
        session: LanguageModelSession
    ) {
        self._feedbackState = feedbackState
        self.session = session
    }

    var body: some View {
        HStack(spacing: 8) {
            // Thumbs up button
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    feedbackState = feedbackState == .thumbsUp ? .none : .thumbsUp
                }
                handleFeedback(feedback: feedbackState)
            } label: {
                Image(systemName: feedbackState == .thumbsUp ? "hand.thumbsup.fill" : "hand.thumbsup")
                    .foregroundStyle(feedbackState == .thumbsUp ? .green : .secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Thumbs up")
            .accessibilityHint("Mark this output as helpful")

            // Thumbs down button
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    feedbackState = feedbackState == .thumbsDown ? .none : .thumbsDown
                }
                handleFeedback(feedback: feedbackState)
            } label: {
                Image(systemName: feedbackState == .thumbsDown ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                    .foregroundStyle(feedbackState == .thumbsDown ? .red : .secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Thumbs down")
            .accessibilityHint("Mark this output as not helpful")
        }
        .sheet(isPresented: $showingFeedbackDialog) {
            FeedbackDialogView() { category, explanation in
                submitFeedback(
                    sentiment: .negative,
                    issue: .init(category: category, explanation: explanation)
                )
            }
        }
    }

    private func handleFeedback(feedback: FeedbackState) {
        switch feedback {
            case .thumbsDown:
                // Request more details before submitting feedback
                showingFeedbackDialog = true

            case .thumbsUp:
                // Submit positive feedback without user interaction
                submitFeedback(sentiment: .positive)

            default:
                break
        }
    }

    private func submitFeedback(
        sentiment: LanguageModelFeedback.Sentiment,
        issue: LanguageModelFeedback.Issue? = nil
    ) {
        let data = session.logFeedbackAttachment(sentiment: sentiment, issues: [issue].compactMap { $0 })

        // This is where you would submit data as feedback to Apple.
        print(String(data: data, encoding: .utf8) ?? "")
    }
}

struct FeedbackDialogView: View {
    @Environment(\.dismiss) private var dismiss

    let onSubmit: (LanguageModelFeedback.Issue.Category, String) -> Void

    @State private var selectedCategory: LanguageModelFeedback.Issue.Category = .incorrect
    @State private var explanation: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Picker("Issue Category", selection: $selectedCategory) {
                    ForEach(LanguageModelFeedback.Issue.Category.allCases, id: \.self) { category in
                        Text(category.localizedDescription)
                            .tag(category)
                    }
                }
                .pickerStyle(.menu)

#if os(iOS)
                Section("Explanation") {
                    TextField("Please describe the issue", text: $explanation, axis: .vertical)
                        .lineLimit(5...10)
                }
#else
                TextField("Description", text: $explanation, axis: .vertical)
                    .lineLimit(5...10)
#endif
            }
            .padding()
            .navigationTitle("Report a Concern")
            .adaptiveFeedbackDialogFrame()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit Report") {
                        onSubmit(selectedCategory, explanation)
                        dismiss()
                    }
                    .disabled(explanation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .adaptiveSheet()
    }
}

extension LanguageModelFeedback.Issue.Category {
    var localizedDescription: String {
        switch self {
            case .unhelpful: return "Unhelpful"
            case .tooVerbose: return "Too Verbose"
            case .didNotFollowInstructions: return "Did not follow instructions"
            case .incorrect: return "Incorrect"
            case .stereotypeOrBias: return "Stereotype of bias issue"
            case .suggestiveOrSexual: return "Suggestive or sexual issue"
            case .vulgarOrOffensive: return "Vulgar or offensive"
            case .triggeredGuardrailUnexpectedly: return "Unexpectedly triggered guardrail"
            default: return "\(self)"
        }
    }
}
