import SwiftUI

struct PerformanceAnalysisView: View {
    @Environment(\.dismiss) private var dismiss
    let transcriptions: [Transcription]
    private let analysis: AnalysisResult

    init(transcriptions: [Transcription]) {
        self.transcriptions = transcriptions
        self.analysis = Self.analyze(transcriptions: transcriptions)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    summarySection
                    
                    systemInfoSection
                    
                    if !analysis.transcriptionModels.isEmpty {
                        transcriptionPerformanceSection
                    }
                    
                    if !analysis.enhancementModels.isEmpty {
                        enhancementPerformanceSection
                    }
                }
                .padding()
            }
        }
        .frame(minWidth: 550, idealWidth: 600, maxWidth: 700, minHeight: 600, idealHeight: 750, maxHeight: 900)
        .background(Color(.windowBackgroundColor))
    }

    private var header: some View {
        HStack {
            Text("Performance Analysis")
                .font(.title2)
                .fontWeight(.bold)
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.borderless)
        }
    }

    private var summarySection: some View {
        HStack(spacing: 12) {
            SummaryCard(
                icon: "doc.text.fill", 
                value: "\(analysis.totalTranscripts)", 
                label: "Total Transcripts",
                color: .indigo
            )
            SummaryCard(
                icon: "waveform.path.ecg", 
                value: "\(analysis.totalWithTranscriptionData)", 
                label: "Analyzable",
                color: .teal
            )
            SummaryCard(
                icon: "sparkles", 
                value: "\(analysis.totalEnhancedFiles)", 
                label: "Enhanced",
                color: .mint
            )
        }
    }

    private var systemInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("System Information")
                .font(.system(.title2, design: .default, weight: .bold))
                .foregroundColor(.primary)

            HStack(spacing: 12) {
                SystemInfoCard(label: "Device", value: getMacModel())
                SystemInfoCard(label: "Processor", value: getCPUInfo())
                SystemInfoCard(label: "Memory", value: getMemoryInfo())
            }
        }
    }

    private var transcriptionPerformanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Transcription Models")
                .font(.system(.title2, design: .default, weight: .bold))
                .foregroundColor(.primary)

            ForEach(analysis.transcriptionModels) { modelStat in
                TranscriptionModelCard(modelStat: modelStat)
            }
        }
    }

    private var enhancementPerformanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Enhancement Models")
                .font(.system(.title2, design: .default, weight: .bold))
                .foregroundColor(.primary)

            ForEach(analysis.enhancementModels) { modelStat in
                EnhancementModelCard(modelStat: modelStat)
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "0s"
    }

    // MARK: - Analysis Logic
    
    struct AnalysisResult {
        let totalTranscripts: Int
        let totalWithTranscriptionData: Int
        let totalAudioDuration: TimeInterval
        let totalEnhancedFiles: Int
        let transcriptionModels: [ModelStat]
        let enhancementModels: [ModelStat]
    }

    struct ModelStat: Identifiable {
        let id = UUID()
        let name: String
        let fileCount: Int
        let totalProcessingTime: TimeInterval
        let avgProcessingTime: TimeInterval
        let avgAudioDuration: TimeInterval
        let speedFactor: Double // RTFX
    }

    static func analyze(transcriptions: [Transcription]) -> AnalysisResult {
        let totalTranscripts = transcriptions.count
        let totalWithTranscriptionData = transcriptions.filter { $0.transcriptionDuration != nil }.count
        let totalAudioDuration = transcriptions.reduce(0) { $0 + $1.duration }
        let totalEnhancedFiles = transcriptions.filter { $0.enhancedText != nil && $0.enhancementDuration != nil }.count
        
        let transcriptionStats = processStats(
            for: transcriptions,
            modelNameKeyPath: \.transcriptionModelName,
            durationKeyPath: \.transcriptionDuration,
            audioDurationKeyPath: \.duration
        )
        
        let enhancementStats = processStats(
            for: transcriptions,
            modelNameKeyPath: \.aiEnhancementModelName,
            durationKeyPath: \.enhancementDuration
        )
        
        return AnalysisResult(
            totalTranscripts: totalTranscripts,
            totalWithTranscriptionData: totalWithTranscriptionData,
            totalAudioDuration: totalAudioDuration,
            totalEnhancedFiles: totalEnhancedFiles,
            transcriptionModels: transcriptionStats,
            enhancementModels: enhancementStats
        )
    }
    
    static func processStats(for transcriptions: [Transcription],
                             modelNameKeyPath: KeyPath<Transcription, String?>,
                             durationKeyPath: KeyPath<Transcription, TimeInterval?>,
                             audioDurationKeyPath: KeyPath<Transcription, TimeInterval>? = nil) -> [ModelStat] {
        
        let relevantTranscriptions = transcriptions.filter {
            $0[keyPath: modelNameKeyPath] != nil && $0[keyPath: durationKeyPath] != nil
        }
        
        let groupedByModel = Dictionary(grouping: relevantTranscriptions) {
            $0[keyPath: modelNameKeyPath] ?? "Unknown"
        }
        
        return groupedByModel.map { modelName, items in
            let fileCount = items.count
            let totalProcessingTime = items.reduce(0) { $0 + ($1[keyPath: durationKeyPath] ?? 0) }
            let avgProcessingTime = totalProcessingTime / Double(fileCount)
            
            let totalAudioDuration = items.reduce(0) { $0 + $1.duration }
            let avgAudioDuration = totalAudioDuration / Double(fileCount)
            
            var speedFactor = 0.0
            if let audioDurationKeyPath = audioDurationKeyPath, totalProcessingTime > 0 {
                speedFactor = totalAudioDuration / totalProcessingTime
            }
            
            return ModelStat(
                name: modelName,
                fileCount: fileCount,
                totalProcessingTime: totalProcessingTime,
                avgProcessingTime: avgProcessingTime,
                avgAudioDuration: avgAudioDuration,
                speedFactor: speedFactor
            )
        }.sorted { $0.name < $1.name }
    }
}

// MARK: - Helper Functions for System Info

private func getMacModel() -> String {
    var size = 0
    sysctlbyname("hw.model", nil, &size, nil, 0)
    var machine = [CChar](repeating: 0, count: size)
    sysctlbyname("hw.model", &machine, &size, nil, 0)
    return String(cString: machine)
}

private func getCPUInfo() -> String {
    var size = 0
    sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0)
    var buffer = [CChar](repeating: 0, count: size)
    sysctlbyname("machdep.cpu.brand_string", &buffer, &size, nil, 0)
    return String(cString: buffer)
}

private func getMemoryInfo() -> String {
    let totalMemory = ProcessInfo.processInfo.physicalMemory
    return ByteCountFormatter.string(fromByteCount: Int64(totalMemory), countStyle: .memory)
}


// MARK: - Subviews

struct SummaryCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundColor(.primary)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.headline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.body)
                .foregroundColor(.primary)
        }
    }
}

struct SystemInfoCard: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            Text(value)
                .font(.system(.body, design: .default, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
        .background(CardBackground(isSelected: false))
        .cornerRadius(8)
    }
}

struct TranscriptionModelCard: View {
    let modelStat: PerformanceAnalysisView.ModelStat

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Model name and transcript count
            HStack(alignment: .firstTextBaseline) {
                Text(modelStat.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(modelStat.fileCount) transcripts")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            VStack(spacing: 12) {
                // First row of metrics
                HStack(spacing: 24) {
                    MetricDisplay(
                        title: "Avg. Transcript Duration", 
                        value: formatDuration(modelStat.avgAudioDuration),
                        color: .indigo
                    )
                    
                    MetricDisplay(
                        title: "Avg. Transcription Time",
                        value: String(format: "%.2f s", modelStat.avgProcessingTime),
                        color: .teal
                    )
                    
                    MetricDisplay(
                        title: "Speed Factor",
                        value: String(format: "%.1fx faster", modelStat.speedFactor),
                        color: .mint
                    )
                }
            }
        }
        .padding(16)
        .background(CardBackground(isSelected: false))
        .cornerRadius(8)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "0s"
    }
}

struct EnhancementModelCard: View {
    let modelStat: PerformanceAnalysisView.ModelStat

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Model name and transcript count
            HStack(alignment: .firstTextBaseline) {
                Text(modelStat.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(modelStat.fileCount) transcripts")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            VStack(spacing: 12) {
                HStack(spacing: 24) {
                    MetricDisplay(
                        title: "Avg. Enhancement Time",
                        value: String(format: "%.2f s", modelStat.avgProcessingTime),
                        color: .indigo
                    )
                }
            }
        }
        .padding(16)
        .background(CardBackground(isSelected: false))
        .cornerRadius(8)
    }
}

struct MetricDisplay: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
            
            Text(value)
                .font(.system(.body, design: .monospaced, weight: .semibold))
                .foregroundColor(color)
        }
    }
}
