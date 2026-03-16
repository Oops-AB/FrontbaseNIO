public protocol FrontbaseMetricsHandler {
    func collectMetrics (statement: String, duration: Double)
    func with (tags: [String: String]) -> Self
}

public struct NoopFrontbaseMetricsHandler: FrontbaseMetricsHandler {
    public func with (tags: [String : String]) -> Self { self }
    public init() {}
    public func collectMetrics (statement: String, duration: Double) {}
}
