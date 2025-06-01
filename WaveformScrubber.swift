import AVKit

struct WaveformScrubber: View {
    let config: Config = .init()
    let url: URL
    @Binding var progress: Double
    
    var info: (AudioInfo) -> () = { _ in }
    var onGestureActive: (Bool) -> () = { _ in }
    
    @State private var samples: [Float] = []
    @State private var downsizedSamples: [Float] = []
    @State private var viewSize: CGSize = .zero
    
    @State private var sizeChangeWorkItem: DispatchWorkItem? = nil
    @State private var isComputingWaveform: Bool = false
    
    @State private var lastProgress: CGFloat = 0
    @GestureState private var isActive: Bool = false
    
    var body: some View {
        ZStack {
            if !isComputingWaveform {
                WaveformShape(samples: downsizedSamples)
                    .fill(config.inactiveTint)
                
                WaveformShape(samples: downsizedSamples)
                    .fill(config.activeTint)
                    .mask {
                        Rectangle()
                            .scale(x: progress, anchor: .leading)
                    }
            }
        }
        .frame(maxWidth: .infinity)
        .contentShape(.rect)
        .gesture(
            DragGesture()
                .updating($isActive, body: { _, out, _ in
                    out = true
                })
                .onChanged({ value in
                    let progress = max(min((value.translation.width / viewSize.width) + lastProgress, 1), 0)
                    self.progress = progress
                })
                .onEnded({ _ in
                    lastProgress = progress
                })
        )
        .onChange(of: url, { oldValue, newValue in
            self.samples = [] // we need to reset the samples in order to not skip the calculation
            calcWaveform(for: self.viewSize)
        })
        .onChange(of: progress, { oldValue, newValue in
            // Update lastProgress when progress is updated from outside the view
            guard !isActive else { return }
            lastProgress = newValue
        })
        .onChange(of: isActive, { oldValue, newValue in
            onGestureActive(newValue)
        })
        .onGeometryChange(for: CGSize.self) { geometryProxy in
            geometryProxy.size
        } action: { newValue in
            // Initial progress
            if viewSize == .zero {
                lastProgress = progress
            }
            
            if newValue.width != viewSize.width {
                calcWaveform(for: newValue)
            }
        }
    }
    
    func calcWaveform(for viewSize: CGSize) {
        sizeChangeWorkItem?.cancel()
        let workItem = DispatchWorkItem {
            self.viewSize = viewSize
            initAudioFile(for: viewSize)
        }
        sizeChangeWorkItem = workItem
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: workItem)
    }
    
    struct Config {
        var spacing: Float = 2
        var shapeWidth: Float = 2
        var activeTint: Color = .accentColor
        var inactiveTint: Color = .gray.opacity(0.7)
    }
    
    struct AudioInfo {
        var duration: TimeInterval = 0
    }
}

extension WaveformScrubber {
    /// Audio Helpers
    private func initAudioFile(for size: CGSize) {
        Task.detached(priority: .high) {
            await MainActor.run {
                isComputingWaveform = true
            }
            
            do {
                let audioFile = try AVAudioFile(forReading: url)
                let audioInfo = await extractAudioInfo(from: audioFile)
                
                // Ensures that the heavy recomputation is only done once (and not everytime the view changes...)
                if await self.samples.isEmpty {
                    let samples = try extractAudioSamples(from: audioFile)
                    
                    await MainActor.run {
                        self.samples = samples
                    }
                }
                
                let downSampleCount = Int(Float(size.width) / (config.spacing + config.shapeWidth))
                let downSamples = await downSampleAudioSamples(self.samples, by: downSampleCount)
                
                await MainActor.run {
                    self.downsizedSamples = downSamples
                    self.info(audioInfo)
                }
            } catch {
                print(error.localizedDescription)
            }
            
            await MainActor.run {
                isComputingWaveform = false
            }
        }
    }
    
    nonisolated func extractAudioSamples(from file: AVAudioFile) throws -> [Float] {
        print("INFO: Recalculate audio samples for waveform") // TODO: change to log... but keep it visible as this is a very expensive opreration that should be closely monitored
        
        let format = file.processingFormat
        let frameCount = UInt32(file.length)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return []
        }
        
        try file.read(into: buffer)
        
        guard let channel = buffer.floatChannelData else {
            return []
        }
        
        return Array(UnsafeBufferPointer(start: channel[0], count: Int(buffer.frameLength)))
    }
    
    nonisolated func downSampleAudioSamples(_ samples: [Float], by count: Int) -> [Float] {
        let chunk = samples.count / count
        var downSamples: [Float] = []
        
        for index in 0..<count {
            let start = index * chunk
            let end = min((index + 1) * chunk, samples.count)
            let chunckSamples = samples[start..<end]
            
            let maxValue = chunckSamples.max() ?? 0
            downSamples.append(maxValue)
        }
        
        return downSamples
    }
    
    nonisolated func extractAudioInfo(from file: AVAudioFile) async -> AudioInfo {
        let format = file.processingFormat
        let sampleRate = format.sampleRate
        
        let duration = file.length / Int64(sampleRate)
        
        return .init(duration: TimeInterval(duration))
    }
}

struct WaveformShape: Shape {
    var samples: [Float]
    var spacing: Float = 2
    var width: Float = 2
    
    nonisolated func path(in rect: CGRect) -> Path {
        Path { path in
            var x: CGFloat = 0
            for sample in samples {
                let height = max(CGFloat(sample) * rect.height, 1)
                
                path.addRect(CGRect(
                    origin: .init(x: x + CGFloat(width), y: -height / 2),
                    size: .init(width: CGFloat(width), height: height)
                ))
                
                x += CGFloat(spacing + width)
            }
        }
        .offsetBy(dx: 0, dy: rect.height / 2)
    }
}