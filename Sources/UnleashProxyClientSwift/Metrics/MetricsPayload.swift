struct MetricsPayload {
    let appName: String
    let instanceId: String
    let bucket: Bucket

    func toJson() -> [String: Any] {
        [
            "appName": appName,
            "instanceId": instanceId,
            "bucket": bucket.toJson()
        ]
    }
}
