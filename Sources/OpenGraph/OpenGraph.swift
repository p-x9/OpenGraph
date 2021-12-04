import Foundation

public struct OpenGraph {
    
    public let source: [String: String]
    
    @discardableResult
    public static func fetch(url: URL, headers: [String: String]? = nil, configuration: URLSessionConfiguration = .default, completion: @escaping (Result<OpenGraph, Error>) -> Void) -> URLSessionDataTask {
        var mutableURLRequest = URLRequest(url: url)
        headers?.compactMapValues { $0 }.forEach {
            mutableURLRequest.setValue($1, forHTTPHeaderField: $0)
        }
        let session = URLSession(configuration: configuration)
        let task = session.dataTask(with: mutableURLRequest, completionHandler: { data, response, error in
            if let error = error {
                completion(.failure(error))
            } else {
                handleFetchResult(data: data, response: response, completion: completion)
            }
        })
        task.resume()
        return task
    }
    
    #if compiler(>=5.5.2) && canImport(_Concurrency)
    @available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
    public static func fetch(url: URL, headers: [String: String]? = nil, configuration: URLSessionConfiguration = .default) async throws-> OpenGraph {
        var mutableURLRequest = URLRequest(url: url)
        headers?.compactMapValues { $0 }.forEach {
            mutableURLRequest.setValue($1, forHTTPHeaderField: $0)
        }
        let session = URLSession(configuration: configuration)
        let (data, response) = try await session.data(for: mutableURLRequest)
        return try handleFetchResult(data: data, response: response)
    }
    #elseif compiler(>=5.5) && canImport(_Concurrency)
    @available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
    public static func fetch(url: URL, headers: [String: String]? = nil, configuration: URLSessionConfiguration = .default) async throws-> OpenGraph {
        var mutableURLRequest = URLRequest(url: url)
        headers?.compactMapValues { $0 }.forEach {
            mutableURLRequest.setValue($1, forHTTPHeaderField: $0)
        }
        let session = URLSession(configuration: configuration)
        let (data, response) = try await session.data(for: mutableURLRequest)
        return try handleFetchResult(data: data, response: response)
    }
    #endif
    
    private static func handleFetchResult(data: Data?, response: URLResponse?, completion: @escaping (Result<OpenGraph, Error>) -> Void) {
        guard let data = data, let response = response as? HTTPURLResponse else {
            return
        }
        if !(200..<300).contains(response.statusCode) {
            completion(.failure(OpenGraphResponseError.unexpectedStatusCode(response.statusCode)))
        } else {
            guard let htmlString = String(data: data, encoding: String.Encoding.utf8) else {
                completion(.failure(OpenGraphParseError.encodingError))
                return
            }
            let og = OpenGraph(htmlString: htmlString)
            completion(.success(og))
        }
    }
    
    private static func handleFetchResult(data: Data, response: URLResponse) throws -> OpenGraph {
        if let response = response as? HTTPURLResponse,
           !(200..<300).contains(response.statusCode) {
            throw OpenGraphResponseError.unexpectedStatusCode(response.statusCode)
        } else {
            guard let htmlString = String(data: data, encoding: String.Encoding.utf8) else {
                throw OpenGraphParseError.encodingError
            }
            return OpenGraph(htmlString: htmlString)
        }
    }

    public init(htmlString: String) {
        self = OpenGraph(htmlString: htmlString, parser: DefaultOpenGraphParser())
    }
    
    init(htmlString: String, parser: OpenGraphParser) {
        source = parser.parse(htmlString: htmlString)
    }
    
    public subscript (og ogpAttributeName: OpenGraphMetadata) -> String? {
        return source["og:" + ogpAttributeName.rawValue]
    }
    
    public subscript (attributeName: SiteMetadata) -> String? {
        return source[attributeName.rawValue]
    }
    
    public subscript (raw attributeName: String) -> String? {
        return source[attributeName]
    }
}

private struct DefaultOpenGraphParser: OpenGraphParser {
}
