//
//  ModelManager.swift
//  Eris.
//
//  Created by Ignacio Palacio on 19/6/25.
//  Changed by Arya Mirsepasi on 27.07.25.

import Foundation
import MLX
import MLXLLM
import MLXLMCommon
import SwiftUI

// Custom error types for better error handling
enum ModelDownloadError: LocalizedError {
    case requiresWiFi
    case downloadFailed(String)
    case networkUnavailable
    case unsupportedModelType(String)
    case modelNotFound(String)
    case configurationError(String)
    
    var errorDescription: String? {
        switch self {
        case .requiresWiFi:
            return "Model downloads require a Wi-Fi connection. The MLX framework doesn't support downloading over cellular data.\n\nPlease connect to Wi-Fi to download. Once downloaded, you can use the app offline or with any connection type."
        case .downloadFailed(let message):
            return "Download failed: \(message)"
        case .networkUnavailable:
            return "No internet connection available."
        case .unsupportedModelType(let type):
            return "This model uses '\(type)' architecture which is not supported by MLX framework. Please choose a different model."
        case .modelNotFound(let name):
            return "Model '\(name)' could not be found or accessed. It may have been moved or removed from the repository."
        case .configurationError(let details):
            return "Model configuration error: \(details)"
        }
    }
}

@MainActor
class ModelManager: ObservableObject {
    @Published var downloadedModels: Set<String> = []
    @Published var activeModel: ModelConfiguration?
    @Published var activeAIModel: AIModel?
    @Published var downloadingModels: Set<String> = []
    @Published var downloadProgress: [String: Double] = [:]
    
    private let userDefaults = UserDefaults.standard
    private let downloadedModelsKey = "downloadedModels"
    private let activeModelKey = "activeModel"
    
    static let shared = ModelManager()
    
    init() {
        loadDownloadedModels()
        loadActiveModel()
    }
    
    private func loadDownloadedModels() {
        if let saved = userDefaults.stringArray(forKey: downloadedModelsKey) {
            downloadedModels = Set(saved)
        }
    }
    
    private func loadActiveModel() {
        if let modelName = userDefaults.string(forKey: activeModelKey),
           let aiModel = AIModelsRegistry.shared.modelByName(modelName) {
            activeModel = aiModel.configuration
            activeAIModel = aiModel
        }
    }
    
    private func saveDownloadedModels() {
        userDefaults.set(Array(downloadedModels), forKey: downloadedModelsKey)
    }
    
    func isModelDownloaded(_ model: ModelConfiguration) -> Bool {
        downloadedModels.contains(model.name)
    }
    
    func setActiveModel(_ model: ModelConfiguration) {
        activeModel = model
        activeAIModel = AIModelsRegistry.shared.modelByConfiguration(model)
        userDefaults.set(model.name, forKey: activeModelKey)
    }
    
    private func validateModel(_ model: ModelConfiguration) throws {
        // List of known unsupported model types
        let unsupportedModelTypes = ["stablelm", "stablecode"]
        let modelNameLower = model.name.lowercased()
        
        // Check for known unsupported model types
        for unsupported in unsupportedModelTypes {
            if modelNameLower.contains(unsupported) {
                throw ModelDownloadError.unsupportedModelType(unsupported)
            }
        }
        
        // List of known problematic models
        let problematicModels = [
            "mlx-community/CodeLlama-7b-Instruct-hf-4bit",
            "mlx-community/stable-code-instruct-3b-4bit"
        ]
        
        if problematicModels.contains(model.name) {
            throw ModelDownloadError.modelNotFound(model.name)
        }
        
        // Validate model is in our registry
        guard AIModelsRegistry.shared.modelByConfiguration(model) != nil else {
            throw ModelDownloadError.configurationError("Model not found in registry")
        }
    }
    
    func downloadModel(_ model: ModelConfiguration, progressHandler: @escaping (Progress) -> Void) async throws {
        print("Starting download for model: \(model.name)")
        
        // Validate model before attempting download
        try validateModel(model)
        
        // Mark as downloading
        downloadingModels.insert(model.name)
        downloadProgress[model.name] = 0.0
        
        // Check network connectivity
        if !NetworkMonitor.shared.isConnected {
            throw ModelDownloadError.networkUnavailable
        }
        
        // Use lower cache limit for better compatibility with cellular connections
        // Similar to Fullmoon's approach (20MB)
        let cacheLimit = 20 * 1024 * 1024 // 20MB for all devices during download
        MLX.GPU.set(cacheLimit: cacheLimit)
        print("Download cache limit set to: \(cacheLimit / 1024 / 1024)MB")
        
        var lastError: Error?
        let maxRetries = 3
        let baseDelay: UInt64 = 2_000_000_000 // 2 seconds in nanoseconds
        
        // Retry logic with exponential backoff
        for attempt in 0..<maxRetries {
            if attempt > 0 {
                let delay = baseDelay * UInt64(pow(2.0, Double(attempt - 1)))
                print("Retrying download after \(Double(delay) / 1_000_000_000) seconds...")
                try await Task.sleep(nanoseconds: delay)
            }
            
            do {
                // Download the model
                print("Download attempt \(attempt + 1) of \(maxRetries)")
                _ = try await LLMModelFactory.shared.loadContainer(
                    configuration: model,
                    progressHandler: { progress in
                        print("Download progress: \(progress.fractionCompleted)")
                        Task { @MainActor in
                            self.downloadProgress[model.name] = progress.fractionCompleted
                        }
                        progressHandler(progress)
                    }
                )
                
                print("Model downloaded successfully")
                
                // Mark as downloaded
                downloadedModels.insert(model.name)
                saveDownloadedModels()
                
                // If no active model, set this as active
                if activeModel == nil {
                    setActiveModel(model)
                }
                
                // Clean up download state
                downloadingModels.remove(model.name)
                downloadProgress.removeValue(forKey: model.name)
                
                return // Success, exit the function
                
            } catch {
                lastError = error
                print("Download attempt \(attempt + 1) failed: \(error)")
                
                // Check if it's the "Repository not available locally" error
                let errorMessage = error.localizedDescription.lowercased()
                let errorString = String(describing: error)
                
                if errorMessage.contains("repository not available") || 
                   errorMessage.contains("offline mode") ||
                   errorString.contains("offlineModeError") {
                    // This is a known MLX framework limitation on cellular
                    print("MLX Framework entered offline mode on cellular connection")
                    // Clean up download state
                    downloadingModels.remove(model.name)
                    downloadProgress.removeValue(forKey: model.name)
                    throw ModelDownloadError.requiresWiFi
                }
                
                // Check for unsupported model type errors
                if errorMessage.contains("unsupported model type") || errorString.contains("stablelm") {
                    let modelType = errorString.components(separatedBy: "\"").dropFirst().first ?? "unknown"
                    print("Unsupported model type detected: \(modelType)")
                    // Clean up download state
                    downloadingModels.remove(model.name)
                    downloadProgress.removeValue(forKey: model.name)
                    throw ModelDownloadError.unsupportedModelType(modelType)
                }
                
                // Check for missing config.json or model not found errors
                if errorMessage.contains("config.json") || errorMessage.contains("couldn't be opened") ||
                   errorMessage.contains("not found") || errorMessage.contains("404") {
                    print("Model not found or configuration missing")
                    // Clean up download state
                    downloadingModels.remove(model.name)
                    downloadProgress.removeValue(forKey: model.name)
                    throw ModelDownloadError.modelNotFound(model.name)
                }
                
                // Check for other configuration errors
                if errorMessage.contains("configuration") || errorMessage.contains("invalid") {
                    print("Model configuration error")
                    // Clean up download state
                    downloadingModels.remove(model.name)
                    downloadProgress.removeValue(forKey: model.name)
                    throw ModelDownloadError.configurationError(errorMessage)
                }
            }
        }
        
        // All retries failed
        // Clean up download state
        downloadingModels.remove(model.name)
        downloadProgress.removeValue(forKey: model.name)
        
        if let error = lastError {
            throw ModelDownloadError.downloadFailed(error.localizedDescription)
        } else {
            throw ModelDownloadError.downloadFailed("Unknown error")
        }
    }
    
    func deleteModel(_ model: ModelConfiguration) {
        // If this is the active model, clear it first
        if activeModel?.name == model.name {
            activeModel = nil
            activeAIModel = nil
            userDefaults.removeObject(forKey: activeModelKey)
        }

        // Remove from downloaded set and persist
        downloadedModels.remove(model.name)
        saveDownloadedModels()

        // Delete files
        deleteModelFiles(for: model)

        // Pick a different active model if available
        if activeModel == nil {
            if let next = AIModelsRegistry.shared.allModels.first(where: {
                downloadedModels.contains($0.configuration.name)
            }) {
                setActiveModel(next.configuration)
            }
        }

        // Ask MLXService to unload model if it’s loaded
        Task { @MainActor in
            if let service = MLXServiceIfPresent() {
                await service.unloadIfMatches(model)
            }
        }
    }
    
    func deleteAllModels() {
        // Clear all models
        downloadedModels.removeAll()
        saveDownloadedModels()
        
        // Clear active model
        activeModel = nil
        userDefaults.removeObject(forKey: activeModelKey)
        
        // Delete all model files
        for aiModel in AIModelsRegistry.shared.allModels {
            deleteModelFiles(for: aiModel.configuration)
        }
    }
    
    private func huggingFaceRootCandidates() -> [URL] {
            var roots: [URL] = []
            let fm = FileManager.default

            if let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first {
                // Typical MLXLLM location
                roots.append(docs.appendingPathComponent("huggingface", isDirectory: true))
                roots.append(docs.appendingPathComponent("HuggingFace", isDirectory: true))
            }

            if let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                // Some builds use Application Support
                roots.append(appSupport.appendingPathComponent("huggingface", isDirectory: true))
                roots.append(appSupport.appendingPathComponent("HuggingFace", isDirectory: true))
            }

            if let caches = fm.urls(for: .cachesDirectory, in: .userDomainMask).first {
                // Partial downloads / caches
                roots.append(caches.appendingPathComponent("huggingface", isDirectory: true))
                roots.append(caches.appendingPathComponent("HuggingFace", isDirectory: true))
            }

            return roots
        }

        private func removeIfExists(_ url: URL) {
            let fm = FileManager.default
            do {
                if fm.fileExists(atPath: url.path) {
                    try fm.removeItem(at: url)
                    print("Deleted: \(url.path)")
                }
            } catch {
                print("Failed to delete \(url.path): \(error)")
            }
        }

        fileprivate func deleteModelFiles(for model: ModelConfiguration) {
            let fm = FileManager.default

            // 1) Remove specific model folders under all known roots
            for root in huggingFaceRootCandidates() {
                // models/<repo>
                let modelDir = root
                    .appendingPathComponent("models", isDirectory: true)
                    .appendingPathComponent(model.name, isDirectory: true)
                removeIfExists(modelDir)

                // snapshots/<repo> (HuggingFace cache pattern)
                let snapshotsDir = root
                    .appendingPathComponent("snapshots", isDirectory: true)
                    .appendingPathComponent(model.name, isDirectory: true)
                removeIfExists(snapshotsDir)

                // downloads/<repo> (partial downloads)
                let downloadsDir = root
                    .appendingPathComponent("downloads", isDirectory: true)
                    .appendingPathComponent(model.name, isDirectory: true)
                removeIfExists(downloadsDir)

                // hub/<repo> (older cache layout)
                let hubDir = root
                    .appendingPathComponent("hub", isDirectory: true)
                    .appendingPathComponent(model.name, isDirectory: true)
                removeIfExists(hubDir)
            }

            // 2) Remove stray partial downloads in tmp (best-effort)
            if let tmp = URL(string: NSTemporaryDirectory()) {
                let tmpHF = tmp.appendingPathComponent("huggingface", isDirectory: true)
                removeIfExists(tmpHF)
            }

            // 3) Optionally, nuke all HuggingFace cache roots if the user deletes all models
            if downloadedModels.isEmpty {
                for root in huggingFaceRootCandidates() {
                    removeIfExists(root)
                }
            }

            // 4) Clear URLCache (network cached responses)
            URLCache.shared.removeAllCachedResponses()

            // 5) Reset MLX GPU cache to free memory (not disk, but prevents immediate re-growth)
            MemoryManager.shared.resetGPUCacheLimit()

            // 6) Optional: clear Metal shader caches (can reclaim tens to hundreds of MB).
            // This is safe; they will be rebuilt as needed.
            clearMetalShaderCache()
        }

        private func clearMetalShaderCache() {
            // Common Metal shader cache locations
            // Note: iOS sandboxes typically store them in Library/Caches.
            let fm = FileManager.default
            if let caches = fm.urls(for: .cachesDirectory, in: .userDomainMask).first {
                let metalCaches = [
                    "com.apple.metal",          // general metal cache
                    "com.apple.metal.shadercache",
                    "com.apple.mtlcompilerservice",
                    "Shaders" // some frameworks use a generic folder name
                ]
                for name in metalCaches {
                    let path = caches.appendingPathComponent(name, isDirectory: true)
                    removeIfExists(path)
                }
            }
        }
}


extension MLXService {
    // Keep this on MainActor (class is @MainActor)
    func unloadIfMatches(_ model: ModelConfiguration) {
        let target = model.name

        switch loadState {
        case .loaded(let container):
            // Hop to a detached task to read non-MainActor data
            Task.detached { [weak self] in
                let currentName = await container.configuration.name
                guard currentName == target else { return }
                // Switch back to MainActor to mutate state
                await self?.performUnloadAfterMatch()
            }
        default:
            break
        }
    }

    private func performUnloadAfterMatch() {
        // MainActor context (class is @MainActor)
        loadState = .idle
        isLoadingModel = false
        output = ""
        tokensGenerated = 0
        MLX.GPU.set(cacheLimit: 20 * 1024 * 1024)
    }
}

func MLXServiceIfPresent() -> MLXService? {
    // If you store it in Environment, inject a reference.
    // Placeholder: return a singleton if you have one, or nil.
    return nil
}
