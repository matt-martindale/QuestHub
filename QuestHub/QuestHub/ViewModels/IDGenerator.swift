import Foundation

enum IDGenerator {
    /// Generates a short, URL-safe ID using an unambiguous character set.
    /// - Parameter length: Desired length of the generated ID. Default is 6.
    /// - Returns: A random string of the requested length.
    static func makeShortID(length: Int = 6) -> String {
        let characters = Array("ABCDEFGHJKLMNPQRSTUVWXYZ0123456789")
        var result = String()
        result.reserveCapacity(length)
        for _ in 0..<length {
            if let random = characters.randomElement() {
                result.append(random)
            }
        }
        return result
    }
}
