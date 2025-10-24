import Foundation

public struct TranscriptionChunk {
    public let text: String
    public let isFinal: Bool
    public let timestamp: Date
    
    public init(text: String, isFinal: Bool = false, timestamp: Date = Date()) {
        self.text = text
        self.isFinal = isFinal
        self.timestamp = timestamp
    }
}

public struct ProviderConfig {
    public let apiKey: String
    public let model: String
    public let systemPrompt: String?
    public let language: String?
    public let temperature: Float?
    public let keywords: [String]?
    
    public init(apiKey: String, model: String, systemPrompt: String? = nil, language: String? = nil, temperature: Float? = nil, keywords: [String]? = nil) {
        self.apiKey = apiKey
        self.model = model
        self.systemPrompt = systemPrompt
        self.language = language
        self.temperature = temperature
        self.keywords = keywords
    }
}

public enum STTProviderType: String, CaseIterable, Codable {
    case openai = "OpenAI"

    public var restModels: [String] {
        return ["whisper-1", "gpt-4o-transcribe", "gpt-4o-mini-transcribe"]
    }

    public var realtimeModels: [String] {
        return ["gpt-4o-transcribe", "gpt-4o-mini-transcribe", "whisper-1"]
    }

    /// Returns all available models (both REST and real-time)
    public var allModels: [String] {
        return Array(Set(restModels + realtimeModels)).sorted()
    }

    /// Checks if a model supports real-time streaming
    public func supportsRealtime(_ model: String) -> Bool {
        return realtimeModels.contains(model)
    }

    /// Checks if the provider supports real-time streaming at all
    public var supportsRealtimeStreaming: Bool {
        return !realtimeModels.isEmpty
    }
}