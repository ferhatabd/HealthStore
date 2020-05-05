
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

/// Authorization status of a given type
public enum AuthorizationRequestStatus: Int {
    case willPresentRequestSheet
    case wontPresentRequestSheet
    case unknown
    
    internal init(status: HKAuthorizationRequestStatus) {
        switch status {
        case .shouldRequest:
            self = .willPresentRequestSheet
        case .unnecessary:
            self = .wontPresentRequestSheet
        case .unknown:
            self = .unknown
        }
    }
}


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
    
    /// Get access to the underlying `HealthStore`
    public var store: HKHealthStore {
        healthStore
    }
    
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
    
    /// Determines whether to Health app authorization request had proceeded
    /// completely once throughout the lifetime of the app
    public var authorizationRequestedOnce: Bool {
        UserDefaults.standard.bool(forKey: "healthAuthorizationRequested")
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
                                            
                                            /// set the flag that the authorization
                                            /// request proceeded throughout successfully once
                                            if success {
                                                UserDefaults.standard.set(true, forKey: "healthAuthorizationRequested")
                                            }
                                            
                                            if let _error = error {
                                                callback?(false, .apiError(_error))
                                                
                                                self.log(self.getLog("Authorization failed with error: \(_error) - \(_error.localizedDescription)"), type: .error)
                                            } else {
                                                callback?(true, nil)
                                                self.log(self.getLog("Authorization successful"))
                                            }
        }
    
    }
    
    
    /// Returns the Workout building context for the given workout
    /// - Parameter workout: Wrkout
    /// - Returns: A tuple representing the current `HKHealthStore` and the associated `HKWorkoutBuilder`
    public func workoutContext() -> (store: HKHealthStore, builder: HKWorkoutBuilder) {
        let store = healthStore
        let workoutConfig = HKWorkoutConfiguration()
        workoutConfig.activityType = .pilates
        workoutConfig.locationType = .indoor
        
        let builder = HKWorkoutBuilder(healthStore: store,
                                       configuration: workoutConfig,
                                       device: .local())
        
        return (store, builder)
    }
    
    /// Queries if the user has already been presented with a permission sheet by the OS
    ///
    /// The result can be used to take the necessary action when the user wants to start using
    /// the Helath app intergation. In case they denied the request before, they will not be presented
    /// the sheet. Which means then they need addtional guidance to open the Health app externally to allow the integration
    ///
    /// - Parameters:
    ///   - share: Types to determine the write access for
    ///   - read: Types to determine the read access for
    ///   - callback: Callback for results
    public func requestStatus(toShare share: [HKSampleType], toRead read: [HKObjectType], _ callback: @escaping ((_ status: AuthorizationRequestStatus)->()))  {
        healthStore.getRequestStatusForAuthorization(toShare: Set(share),
                                                     read: Set(read)) { (status, error) in
                                                        guard error == nil else {
                                                            callback(.unknown)
                                                            return
                                                        }
                                                        /// notify the callback
                                                        callback(.init(status: status))
        }
    }
}

