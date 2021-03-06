//
//  JRPClient.swift
//  PassID
//
//  Created by smlu on 4/12/2019.
//  Copyright © 2019 ZeroPass. All rights reserved.
//
import Alamofire
import Foundation
import SwiftyJSON


public enum JRPCError : Error {
    case rpcError(JsonRpcError)
    case connectionError(AFError)
}

public struct JRPCResult {
    let id: JsonRpcRequest.ID?
    let data: JSON
}

class JRPClient {
    
    var defaultTimeout: TimeInterval
    var userAgent: String? = nil
    var origin: String? = nil
    
    var url: URL {
        get {
            return self._url
        }
        set {
            self._url = newValue
            if let tm = self.session.serverTrustManager {
                if let ste = tm.evaluators.first?.value {
                    self.session = self.makeSession(ste: ste)
                }
            }
        }
    }
    
    private var _url: URL
    private let log = Log(category: "jrpc")
    private var session: Session
    
    init(url: URL, defaultTimeout: TimeInterval = SettingsStore.DEFAULT_TIMEOUT, ste: ServerTrustEvaluating? = nil) {
        self._url = url
        self.defaultTimeout = defaultTimeout
        self.session = JRPClient.makeSession(url: url, ste: ste)
    }
    
    func call(method: String, params: JSON? = nil, completion: @escaping (Result<JRPCResult, JRPCError>)->Void) -> JsonRpcRequest.ID {
        return self.call(method: method, params: params, timeout: self.defaultTimeout, completion: completion)
    }
    
    func call(method: String, params: JSON? = nil, timeout: TimeInterval, completion: @escaping (Result<JRPCResult, JRPCError>)->Void) -> JsonRpcRequest.ID {
        let jrpcReq = JsonRpcRequest(id: .string(UUID().uuidString), method: method, params: params)
        self.call(jrpcReq: jrpcReq, timeout: timeout, completion: completion)
        return jrpcReq.id!
    }
    
    func call(jrpcReq: JsonRpcRequest, timeout: TimeInterval, completion: @escaping (Result<JRPCResult, JRPCError>)->Void) {
        var req = URLRequest(url: self.url, timeoutInterval: timeout)
        req.httpMethod = "POST"
        req.allHTTPHeaderFields = self.makeHttpHeader()
        req.httpBody = try? jrpcReq.toJSON().rawData()

        log.debug("Sending new RPC call to %@ reqId: %@", self.url as CVarArg,  jrpcReq.id?.string ?? "null")
        log.verbose("RPC(method: \"%@\" params: %@)", jrpcReq.method, jrpcReq.params?.description ?? "null")
        session.request(req).responseJSON{ response in
            _ = self.session // Capture session in case self is destroyed before this closure is called.
            self.handleResponse(resp: response, completion: completion)
        }
    }
    
    func notify(method: String, params: JSON? = nil) {
        notify(method: method, params: params, timeout: self.defaultTimeout)
    }

    func notify(method: String, params: JSON? = nil, timeout: TimeInterval) {
        let jrpcReq = JsonRpcRequest(id: nil, method: method, params: params)
        call(jrpcReq: jrpcReq, timeout: timeout){_ in }
    }
    
    
    private func handleResponse(resp: AFDataResponse<Any>, completion: @escaping (Result<JRPCResult, JRPCError>)->Void) {
       switch resp.result {
           case .success(let value):
               let rpcResponse = JsonRpcResponse(json: JSON(value))
               let isError =  rpcResponse.error != nil
               log.log(isError ? .error : .debug,
                       "Received RPC %@ from: %@ reqId: %@",
                       isError ? "error" : "response",
                       resp.request?.url as CVarArg? ?? "null",
                       rpcResponse.id?.string ?? "null"
               )
               if isError {
                   log.verbose("RPC error: %@", rpcResponse.error!.localizedDescription )
                   completion(.failure(JRPCError.rpcError(rpcResponse.error!)))
               }
               else {
                   log.verbose("RPC result: %@", rpcResponse.result?.description ?? "null")
                   completion(.success(JRPCResult(id: rpcResponse.id, data: rpcResponse.result!)))
               }
           case .failure(let error):
               log.error("Failed to connect to: %@ error: \"%@\"", resp.request?.url as CVarArg? ?? "null", error.localizedDescription)
               completion(.failure(JRPCError.connectionError(error)))
       }
    }
    
    private func makeSession(ste: ServerTrustEvaluating?) -> Session {
        return JRPClient.makeSession(url: self.url, ste: ste)
    }
    
    private static func makeSession(url: URL, ste: ServerTrustEvaluating?) -> Session {
        let host = url.host
        if host != nil && ste != nil {
            let tm = ServerTrustManager(evaluators: [host! : ste!])
            return Session(serverTrustManager: tm)
        }
        return Session.default
    }
    
    private func makeHttpHeader() -> [String : String] {
        var header = [
             "Accept" : "application/json",
             "Content-type" : "application/json"
        ]
        
        if (self.userAgent != nil) {
            header["User-Agent"] = self.userAgent
        }
        
        if (self.origin != nil) {
            header["Origin"] = self.origin
        }
        
        return header
    }
}
