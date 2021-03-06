//
//  Error.swift
//  Pods
//
//  Created by Javier Fuchs on 7/26/16.
//
//

import Foundation

public class Error : ErrorType {
    
    public var error: NSError?
    
    public init(code: Int, desc: String?, reason: String?, suggestion: String?, underError error: NSError?) {
        var dict = [String: AnyObject]()
        if let adesc = desc {
            dict[NSLocalizedDescriptionKey] = adesc
        }
        if let areason = reason {
            dict[NSLocalizedFailureReasonErrorKey] = areason
        }
        
        if let asuggestion = suggestion {
            dict[NSLocalizedRecoverySuggestionErrorKey] = asuggestion
        }
        if let aerror = error {
            dict[NSUnderlyingErrorKey] = aerror
        }
        self.error = NSError(domain: NSBundle.mainBundle().bundleIdentifier!, code:code, userInfo: dict)
    }
    
    public init(_ error: NSError?) {
        if let e = error {
            self.error = e
        }
    }
    
    public func title() -> String? {
        if let e = self.error {
            return e.localizedDescription
        }
        return nil
    }
    
    public func reason() -> String? {
        if let e = self.error {
            return e.localizedFailureReason
        }
        return nil
    }
    
    public func asDictionary() -> [String : AnyObject]? {
        if let error = self.error {
            return ["code": error.code,
                    NSLocalizedDescriptionKey: error.localizedDescription,
                    NSLocalizedFailureReasonErrorKey: error.localizedFailureReason ?? "",
                    NSLocalizedRecoverySuggestionErrorKey: error.localizedRecoverySuggestion ?? "",
                    NSUnderlyingErrorKey: "\(error.userInfo)"]
        }
        return nil
    }

    public var debugDescription : String {
        var aux : String = "["
        if let _error = self.error {
            aux += "\(_error.code);"
            aux += "\(_error.localizedDescription);"
            if let _failureReason = _error.localizedFailureReason {
                aux += "\(_failureReason);"
            } else { aux += "();" }
            if let _recoverySuggestion = _error.localizedRecoverySuggestion {
                aux += "\(_recoverySuggestion);"
            } else { aux += "();" }
            aux += "\(_error.userInfo.description);"
        }
        aux += "]"
        return aux
    }
 
    public var description : String {
        var aux : String = "Error: "
        if let _error = self.error {
            aux += "code=\(_error.code). "
            aux += "\(_error.localizedDescription)\n"
        }
        aux += "Please contact us claiming this error."
        return aux
    }

    
    public func fatal() {
        fatalError("fatal:\(self.debugDescription)")
    }

}
