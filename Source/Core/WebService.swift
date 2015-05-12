//
//  WebService.swift
//  Swallow
//
//  Created by Angelo Di Paolo on 2/16/15.
//  Copyright (c) 2015 TheHolyGrail. All rights reserved.
//

import Foundation

public protocol SessionDataTaskDataSource {
    func dataTaskWithRequest(request: NSURLRequest, completion: (NSData?, NSURLResponse?, NSError?) -> Void) -> NSURLSessionDataTask
}

public struct WebService {
    
    // MARK: NSURLSessionDataTask
    
    private struct DataTaskDataSource: SessionDataTaskDataSource {
        func dataTaskWithRequest(request: NSURLRequest, completion: (NSData?, NSURLResponse?, NSError?) -> Void) -> NSURLSessionDataTask {
            return NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: completion);
        }
    }
    
    /**
     Base URL of the web service.
    */
    public let baseURLString: String
    
    /**
     Set to `false` to prevent `ServiceTask` instances from resuming 
     immediately.
    */
    public var startTasksImmediately = true
    
    /**
     Object responsible for creating a `NSURLSessionDataTask` based on a
     `NSURLRequest`.
    */
    public var dataTaskSource: SessionDataTaskDataSource = DataTaskDataSource()
    
    // MARK: Initialization
    
    /**
     Initialize a web service value.
    
     :param: baseURLString URL string to use as the base URL of the web service.
    */
    public init(baseURLString: String) {
        self.baseURLString = baseURLString
    }
    
    // MARK: Web Service API
    
    /**
     Create a service task for a `GET` HTTP request.
    
     :param: path Request path. The value can be relative to the base URL string
      or absolute.
     :param: parameters Optional request parameters. The data is URL encoded as
       a query string for `GET` requests.
     :param: options Endpoint options used to configure the HTTP request.
     :returns: A ServiceTask instance that refers to the lifetime of processing
      a given request. The newly created task is resumed immediately if the 
      `startTasksImmediately` poperty is set to `true`.
    */
    public func GET(path: String, parameters: [String : AnyObject]? = nil, options: [Request.Option]? = nil) -> ServiceTask {
        return request(.GET, path: path, parameters: parameters, options: options)
    }
    
    /**
     Create a service task for a `POST` HTTP request.
     
     :param: path Request path. The value can be relative to the base URL string
      or absolute.
     :param: parameters Optional request parameters. The data is URL encoded and
      is set as the HTTP body for `POST` requests.
     :param: options Endpoint options used to configure the HTTP request.
     :returns: A ServiceTask instance that refers to the lifetime of processing
      a given request. The newly created task is resumed immediately if the
      `startTasksImmediately` poperty is set to `true`.
    */
    public func POST(path: String, parameters: [String : AnyObject]? = nil, options: [Request.Option]? = nil) -> ServiceTask {
        return request(.POST, path: path, parameters: parameters, options: options)
    }
    
    /**
     Create a service task for a PUT HTTP request.
    
     :param: path Request path. The value can be relative to the base URL string
      or absolute.
     :param: parameters Optional request parameters. The data is URL encoded and
      is set as the HTTP body for `PUT` requests.
     :param: options Endpoint options used to configure the HTTP request.
     :returns: A ServiceTask instance that refers to the lifetime of processing
      a given request. The newly created task is resumed immediately if the 
      `startTasksImmediately` poperty is set to `true`.
    */
    public func PUT(path: String, parameters: [String : AnyObject]? = nil, options: [Request.Option]? = nil) -> ServiceTask {
        return request(.PUT, path: path, parameters: parameters, options: options)
    }
    
    /**
     Create a service task for a DELETE HTTP request.
    
     :param: path Request path. The value can be relative to the base URL string
      or absolute.
     :param: parameters Optional request parameters. The data is URL encoded and
      is set as the HTTP body for `DELETE` requests.
     :param: options Endpoint options used to configure the HTTP request.
     :returns: A ServiceTask instance that refers to the lifetime of processing
      a given request. The newly created task is resumed immediately if the 
      `startTasksImmediately` poperty is set to `true`.
    */
    public func DELETE(path: String, parameters: [String : AnyObject]? = nil, options: [Request.Option]? = nil) -> ServiceTask {
        return request(.DELETE, path: path, parameters: parameters, options: options)
    }
    
    /**
     Create a service task for a HEAD HTTP request.
    
     :param: path Request path. The value can be relative to the base URL string
      or absolute.
     :param: parameters Optional request parameters. The data is URL encoded as
      a query string for `HEAD` requests.
     :param: options Endpoint options used to configure the HTTP request.
     :returns: A ServiceTask instance that refers to the lifetime of processing
      a given request. The newly created task is resumed immediately if the 
      `startTasksImmediately` poperty is set to `true`.
    */
    public func HEAD(path: String, parameters: [String : AnyObject]? = nil, options: [Request.Option]? = nil) -> ServiceTask {
        return request(.HEAD, path: path, parameters: parameters, options: options)
    }
    
    // MARK: ServiceTask
    
    /**
     Create a service task to fulfill a service request. By default the service 
     task is started by calling resume(). To prevent service tasks from 
     automatically resuming set the `startTasksImmediately` of the WebService
     value to `false`.
    
     :param: method HTTP request method.
     :param: path Request path. The value can be relative to the base URL string
      or absolute.
     :param: parameters Optional request parameters.
     :param: options Optional endpoint options used to configure the HTTP request.
     :returns: A ServiceTask instance that refers to the lifetime of processing
      a given request. The newly created task is resumed immediately if the 
      `startTasksImmediately` poperty is set to `true`.
    */
    private func request(method: Request.Method, path: String, parameters: [String : AnyObject]? = nil, options: [Request.Option]? = nil) -> ServiceTask {
        let urlString = absoluteURLString(requestPath(relativePath: path))
        let request = constructRequest(method, url: urlString, parameters: parameters, options: options)
        return serviceTask(urlRequestEncoder: request)
    }
    
    /**
     Create a `ServiceTask`
     
     :param: urlRequestEncoder Type that provides the encoded NSURLRequest value.
     :returns: A ServiceTask instance that refers to the lifetime of processing
      a given request. The newly created task is resumed immediately if the 
      `startTasksImmediately` poperty is set to `true`.
    */
    private func serviceTask(#urlRequestEncoder: URLRequestEncodable) -> ServiceTask {
        let task = ServiceTask(urlRequestEncoder: urlRequestEncoder, dataTaskSource: dataTaskSource)
        
        if startTasksImmediately {
            task.resume()
        }
        
        return task
    }
    
    // MARK: Request Path
    
    /**
     Override to customize how all web service request paths are constructed. 
     Useful for prefixing request endpoint paths.
     
     :param: relativePath Relative request path.
     :returns: A relative request path.
    */
    public func requestPath(#relativePath: String) -> String {
        return relativePath
    }
    
    // MARK: Request
    
    /**
     Override to customize how all web service request objects are constructed.
    
     :param: method HTTP request method.
     :param: url Request URL. The value can be relative to the base URL string
      or absolute.
     :param: parameters Optional request parameters.
     :param: options Optional endpoint options used to configure the HTTP request.
     :returns: A request value.
    */
    public func constructRequest(method: Request.Method, url: String, parameters: [String : AnyObject]? = nil, options: [Request.Option]? = nil) -> Request {
        var request = Request(method, url: url)
        
        if let parameters = parameters {
            request.parameters = parameters
        }
        
        if let options = options {
            request = request.encodeOptions(options)
        }
        
        return request
    }
}

// MARK: - URL String Construction

extension WebService {
    
    /**
     Return an absolute URL string relative to the baseURLString value.
    
     :param: string URL string.
     :returns: An absoulte URL string relative to the value of `baseURLString`.
    */
    public func absoluteURLString(string: String) -> String {
        return constructURLString(string, relativeToURLString: baseURLString)
    }
    
    /**
     Return an absolute URL string relative to the baseURLString value.
    
     :param: string URL string value.
     :param: relativeURLString Value of relative URL string.
     :returns: An absolute URL string.
    */
    public func constructURLString(string: String, relativeToURLString relativeURLString: String) -> String {
        let relativeURL = NSURL(string: relativeURLString)
        return NSURL(string: string, relativeToURL: relativeURL)!.absoluteString!
    }
}