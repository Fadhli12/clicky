import SwiftUI
import Combine

struct FloatingChatView: View {
    @State private var isExpanded: Bool = false
    @StateObject private var viewModel = ChatViewModel()
    @State private var isHoveringOrb: Bool = false
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Expanded Chat Window
            if isExpanded {
                expandedChatView
                    .frame(width: 380, height: 500)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.95, anchor: .bottomTrailing).combined(with: .opacity),
                        removal: .scale(scale: 0.95, anchor: .bottomTrailing).combined(with: .opacity)
                    ))
                    .zIndex(1)
            }
            
            // Orb / Trigger Button
            orbView
                .zIndex(2)
        }
        .padding(20) // Give breathing room from screen edges
        // This frame makes sure our host NSWindow has enough room to expand into
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
    }
    
    // MARK: - Orb View
    private var orbView: some View {
        Button(action: {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                isExpanded.toggle()
                if isExpanded {
                    // Delay focus slightly so the view has time to appear
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isInputFocused = true
                    }
                }
            }
        }) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [Color(hex: "#4F46E5"), Color(hex: "#7C3AED")]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 56, height: 56)
                    .shadow(color: Color(hex: "#4F46E5").opacity(isHoveringOrb ? 0.6 : 0.3), radius: isHoveringOrb ? 12 : 8, x: 0, y: 4)
                
                Image(systemName: isExpanded ? "xmark" : "sparkles")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHoveringOrb = hovering
            }
        }
    }
    
    // MARK: - Expanded Chat View
    private var expandedChatView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Clicky")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        isExpanded = false
                    }
                }) {
                    Image(systemName: "minus")
                        .foregroundColor(Color(hex: "#A1A1AA")) // Zinc 400
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(hex: "#18181B")) // Zinc 900
            
            Divider()
                .background(Color(hex: "#27272A")) // Zinc 800
            
            // Messages Area
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                        // Spacer to pad the bottom of the scroll view
                        Spacer().frame(height: 8).id("bottom")
                    }
                    .padding(16)
                }
                .onChange(of: viewModel.messages.count) { _ in
                    withAnimation {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
                .onChange(of: viewModel.messages.last?.text) { _ in
                    // Keep auto-scrolling during streaming
                    withAnimation {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }
            
            // Input Area
            HStack(spacing: 12) {
                TextField("Message Clicky...", text: $viewModel.inputText)
                    .focused($isInputFocused)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(Color(hex: "#27272A")) // Zinc 800
                            .overlay(
                                Capsule()
                                    .stroke(Color(hex: "#3F3F46"), lineWidth: 1) // Zinc 700
                            )
                    )
                    .onSubmit {
                        viewModel.sendMessage()
                    }
                
                Button(action: {
                    viewModel.sendMessage()
                }) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(viewModel.inputText.isEmpty ? Color(hex: "#3F3F46") : Color(hex: "#4F46E5"))
                        )
                }
                .buttonStyle(.plain)
                .disabled(viewModel.inputText.isEmpty)
            }
            .padding(16)
            .background(Color(hex: "#18181B")) // Zinc 900
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(hex: "#18181B").opacity(0.95))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(hex: "#27272A"), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
        // Add offset to not overlap exactly with the Orb
        .padding(.bottom, 72)
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer(minLength: 40)
                Text(message.text)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color(hex: "#4F46E5"))
                    )
            } else {
                Text(message.text)
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#F4F4F5")) // Zinc 100
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color(hex: "#27272A")) // Zinc 800
                    )
                Spacer(minLength: 40)
            }
        }
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let timestamp: Date
}

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    
    // Uses the existing ClaudeAPI logic under the hood
    private lazy var claudeAPI: ClaudeAPI = {
        return ClaudeAPI(proxyURL: "http://localhost:20130/v1/chat/completions", model: "antigravity/gemini-3.8-flash-tiered")
    }()

    init() {
        // Initial greeting
        messages.append(ChatMessage(text: "Hi! I am Clicky. How can I help?", isUser: false, timestamp: Date()))
    }
    
    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        // 1. Add User Message
        let userMsg = ChatMessage(text: text, isUser: true, timestamp: Date())
        messages.append(userMsg)
        inputText = "" // Clear input
        
        // 2. Add an empty Assistant message for streaming placeholder
        let initialAssistantMsg = ChatMessage(text: "...", isUser: false, timestamp: Date())
        messages.append(initialAssistantMsg)
        
        // We need the index to update it
        let backendIndex = messages.count - 1
        
        // Construct the history for ClaudeAPI
        let conversationHistory: [(String, String)] = []
        
        Task {
            do {
                // Call Claude/Omniroute directly without screenshot for now
                let (_, _) = try await claudeAPI.analyzeImageStreaming(
                    images: [],
                    systemPrompt: "You are an AI assistant living in a floating window. Be helpful and concise.",
                    conversationHistory: conversationHistory,
                    userPrompt: text,
                    onTextChunk: { [weak self] chunk in
                        guard let self = self else { return }
                        // Update the message in place
                        if self.messages[backendIndex].text == "..." {
                            // Replace placeholder with first chunk
                            self.messages[backendIndex] = ChatMessage(text: chunk, isUser: false, timestamp: Date())
                        } else {
                            // Append to existing
                            let existing = self.messages[backendIndex].text
                            self.messages[backendIndex] = ChatMessage(text: existing + chunk, isUser: false, timestamp: Date())
                        }
                    }
                )
            } catch {
                self.messages[backendIndex] = ChatMessage(text: "Error connecting to Omniroute: \(error.localizedDescription)", isUser: false, timestamp: Date())
            }
        }
    }
}

