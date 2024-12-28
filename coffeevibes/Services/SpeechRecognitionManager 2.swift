import Foundation
import Speech

class SpeechRecognitionManager: ObservableObject {
    @Published var isRecording = false
    @Published var errorMessage: String?
    private var audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    
    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    self.errorMessage = nil
                case .denied:
                    self.errorMessage = "Speech recognition access was denied"
                case .restricted:
                    self.errorMessage = "Speech recognition is restricted"
                case .notDetermined:
                    self.errorMessage = "Speech recognition not yet authorized"
                @unknown default:
                    self.errorMessage = "Unknown authorization status"
                }
            }
        }
    }
    
    func startRecording(completion: @escaping (String) -> Void) {
        // Check if there's any recording running and cancel it
        if isRecording {
            stopRecording()
            return
        }
        
        // Guard against missing speech recognizer
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            errorMessage = "Speech recognition is not available"
            return
        }
        
        // Configure the audio session
        do {
            try AVAudioSession.sharedInstance().setCategory(.record, mode: .measurement, options: .duckOthers)
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "Failed to set up audio session: \(error.localizedDescription)"
            return
        }
        
        // Create and configure the speech recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            errorMessage = "Failed to create recognition request"
            return
        }
        recognitionRequest.shouldReportPartialResults = true
        
        // Create the audio engine input node
        let inputNode = audioEngine.inputNode
        
        // Create the recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                self.errorMessage = error.localizedDescription
                self.stopRecording()
                return
            }
            
            if let result = result {
                let transcribedString = result.bestTranscription.formattedString
                completion(transcribedString)
                
                if result.isFinal {
                    self.stopRecording()
                }
            }
        }
        
        // Configure the microphone input
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        // Start the audio engine
        do {
            audioEngine.prepare()
            try audioEngine.start()
            isRecording = true
            errorMessage = nil
        } catch {
            errorMessage = "Failed to start audio engine: \(error.localizedDescription)"
            stopRecording()
        }
    }
    
    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false
    }
} 