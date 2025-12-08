import Foundation

/// Defines a set of specific errors that can occur while interacting with HealthKit.
///
/// Using a custom error enum provides a clear and type-safe way to handle
/// different failure scenarios, such as data unavailability or authorization issues.
enum HKError: Error, LocalizedError {
    /// The HealthKit store is not available on the current device.
    case healthDataNotAvailable
    
    /// The app lacks the necessary authorization to read the requested data.
    case authorizationFailed(String)
    
    /// An error occurred when executing a query.
    case queryError(String)

    /// Provides a user-friendly description for each error case.
    var errorDescription: String? {
        switch self {
        case .healthDataNotAvailable:
            return "HealthKit is not available on this device."
        case .authorizationFailed(let reason):
            return "Authorization failed: \(reason)"
        case .queryError(let reason):
            return "Failed to execute HealthKit query: \(reason)"
        }
    }
}
