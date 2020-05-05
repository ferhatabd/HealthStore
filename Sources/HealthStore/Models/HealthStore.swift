
import Foundation
import HealthKit
import os.log

internal let __HSHealthStoreDomain = "com.ferhatab.HealthStore"

/// API errors
public enum HSHealthStoreErrors: Error {
    /// Health data is not available on the current device
    case healthDataNotAvailable
    
    /// HealthKit internal errors
    case apiError(Error)
    
}


/// Authorization callback
public typealias HealthKitAuthorizationCallback = ((_ success: Bool, _ error: HSHealthStoreErrors?)->())




/// Main Health data supplier
final public class HSHealthStore: Loggable {
    
    // MARK: - Properties
    //
    
    
    // MARK: - Private properties
    
    /// Internal reference to the `HealthStore`
    private lazy var healthStore = HKHealthStore()
    
    
    // MARK: - Internal properties
    
    // MARK: Loggable
    
    /// Logger domain
    internal var domain: String { __HSHealthStoreDomain }
    
    internal lazy var logger: OSLog = OSLog(subsystem: __HSHealthStoreDomain, category: "Health-Store")
    
    
    // MARK: - Public properties
    
    /// Flag regarding whether the health data is available on the current device
    public static var isHealthKitAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }
    
    /// Shared storage
    public static let shared = HSHealthStore()
    
    // MARK: Characteristic information
    
    /// Bilogical sex of the user
    ///
    /// The value will be `.notSet` if the user not allowed the
    /// app to access this data
    ///
    public var sex: HKBiologicalSexObject? {
        try? healthStore.biologicalSex()
    }
    
    
    /// Birthday of the user
    ///
    /// The value will be `.notSet` if the user not allowed the
    /// app to access this data
    ///
    public var birthday: Date? {
        guard let components  = try? healthStore.dateOfBirthComponents() else {
            return nil
        }
        
        return Calendar.current.date(from: components)
    }
    
    
    
    // MARK: - Initialization
    //
    
    /// Internal initialization 
    internal init()  {
        log(getLog("Initialized"))
    }
    
    
    // MARK: - Methods
    //
    
    
    // MARK: - Private methods
    
    /// Create the message format and propagtes to the logger through the protocol
    /// - Parameter message: Message
    private func getLog(_ message: String) -> String {
        "[HSHealthStore] => \(message)"
    }
    
    
    // MARK: - Public methods
    
    /// Tries to Authorize against the given objects and
    /// notifies the callee through the callback
    /// - Parameters:
    ///   - toRead: Objects to authorize for read access
    ///   - toWrite: Objects to autorize for write access
    ///   - callback: Callback for the caller
    public func authorizeForObjects(toRead read: [HKObjectType], toWrite write: [HKSampleType], _ callback:  HealthKitAuthorizationCallback? = nil) {
        /// guard against HealthData not being available
        guard HealthStore.HSHealthStore.isHealthKitAvailable else {
            callback?(false, .healthDataNotAvailable)
            log(getLog("Health data is not available on the current device"), type: .error)
            return
        }
        
        /// try to authorize the given obejcts
        let typesToRead: Set<HKObjectType> = Set(read)
        let typesToWrite: Set<HKSampleType> = Set(write)
        
        log(getLog("Authorization started with\nread access for: \(typesToRead.map({"\(String(describing: $0))"})),\nwrite access for: \(typesToWrite.map({"\(String(describing: $0))"})))"),
            type: .info)
        
        healthStore.requestAuthorization(toShare: typesToWrite,
                                         read: typesToRead) { (success, error) in
                                            if let _error = error {
                                                callback?(false, .apiError(_error))
                                                self.log(self.getLog("Authorization failed with error: \(_error) - \(_error.localizedDescription)"), type: .error)
                                            } else {
                                                callback?(true, nil)
                                                self.log(self.getLog("Authorization successful"))
                                            }
        }
    

        
    }
}

