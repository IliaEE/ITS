import Foundation
import PostHog

/// Every event the app reports, in one place: the dashboard stays free of typos, and it is
/// readable at a glance what leaves the device.
///
/// What is sent: which tool was opened, which options were chosen, how long a job took and how
/// many photos it touched. What is never sent: file names, photo contents, pixel data, or any
/// identifier beyond PostHog's own anonymous id (no IDFA, so no ATT prompt).
enum Analytics {
    private static let projectToken = "phc_mFuHZ9fqpK6kg9QEeuaZkdnXFJ4B7VkvathuK54vR8kE"
    private static let host = "https://eu.i.posthog.com"

    static func start() {
        let config = PostHogConfig(projectToken: projectToken, host: host)
        // SwiftUI screens are not UIViewControllers, so autocapture sees one screen for the whole
        // app. Tool screens are reported explicitly in `toolOpened` instead.
        config.captureScreenViews = false
        PostHogSDK.shared.setup(config)
    }

    fileprivate static func capture(_ event: String, _ props: [String: Any] = [:]) {
        PostHogSDK.shared.capture(event, properties: props)
    }

    // MARK: - Funnel: home → tool → photos → job → result

    static func toolOpened(_ tool: Tool) {
        PostHogSDK.shared.screen(tool.rawValue)
        capture("tool_opened", ["tool": tool.rawValue])
    }

    static func photosPicked(_ tool: Tool, count: Int, format: String) {
        capture("photos_picked", ["tool": tool.rawValue, "count": count, "source_format": format])
    }

    /// `options` is what the user chose before running — the answer to "what do people actually use".
    static func jobStarted(_ tool: Tool, count: Int, options: [String: Any]) {
        capture("job_started", options.merging(["tool": tool.rawValue, "count": count]) { a, _ in a })
    }

    static func jobFinished(_ tool: Tool, count: Int, startedAt: Date, inBytes: Int, outBytes: Int) {
        capture("job_finished", [
            "tool": tool.rawValue,
            "count": count,
            "duration_ms": Int(Date().timeIntervalSince(startedAt) * 1000),
            "input_kb": inBytes / 1024,
            "output_kb": outBytes / 1024,
        ])
    }

    static func jobFailed(_ tool: Tool, reason: String) {
        capture("job_failed", ["tool": tool.rawValue, "reason": reason])
    }

    static func resultSaved(_ tool: String, method: String, count: Int) {
        capture("result_saved", ["tool": tool, "method": method, "count": count])
    }

    static func startedOver(_ tool: String) {
        capture("started_over", ["tool": tool])
    }

    // MARK: - Paywall

    static func paywallShown(trigger: String) {
        capture("paywall_shown", ["trigger": trigger])
    }

    static func paywallClosed(purchased: Bool) {
        capture("paywall_closed", ["purchased": purchased])
    }
}

// MARK: - Identity & feature requests

extension Analytics {
    /// PostHog's anonymous id. Shown in the app so a user can quote it in support, and so a
    /// request can be matched to the session that produced it. Not tied to any account.
    static var userID: String { PostHogSDK.shared.getDistinctId() }

    static func featureRequestOpened() {
        capture("feature_request_opened")
    }

    static func featureRequested(_ ids: [String]) {
        capture("feature_requested", ["features": ids, "count": ids.count])
        // Requests are rare and the answer matters immediately, so don't wait for the batch timer.
        PostHogSDK.shared.flush()
    }
}
