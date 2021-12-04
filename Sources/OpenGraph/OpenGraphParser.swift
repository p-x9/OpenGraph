import Foundation

public protocol OpenGraphParser {
    func parse(htmlString: String) -> [String: String]
}

extension OpenGraphParser {
    func parse(htmlString: String) -> [String: String] {
        // extract meta tag
        let metatagRegex  = try! NSRegularExpression(
            pattern: "<meta(?:\".*?\"|\'.*?\'|[^\'\"])*?>",
            options: [.dotMatchesLineSeparators]
        )
        let metaTagMatches = metatagRegex.matches(in: htmlString,
                                       options: [],
                                       range: NSMakeRange(0, htmlString.count))
        if metaTagMatches.isEmpty {
            return [:]
        }

        // prepare regular expressions to extract og property and content.
        let propertyRegexp = try! NSRegularExpression(
            pattern: "\\s(property|name)=(?:\"|\')*([a-zA_Z:]+)(?:\"|\')*",
            options: []
        )
        let contentRegexp = try! NSRegularExpression(
            pattern: "\\scontent=\\\\*?\"(.*?)\\\\*?\"",
            options: []
        )
        
        // create attribute dictionary
        let nsString = htmlString as NSString
        let attributes = metaTagMatches.reduce([String: String]()) { (attributes, result) -> [String: String] in
            var copiedAttributes = attributes
            
            let property = { () -> (name: String, content: String)? in
                let metaTag = nsString.substring(with: result.range(at: 0))
                let propertyMatches = propertyRegexp.matches(in: metaTag,
                                               options: [],
                                               range: NSMakeRange(0, metaTag.count))
                guard let propertyResult = propertyMatches.first else { return nil }
                
                var contentMatches = contentRegexp.matches(in: metaTag, options: [], range: NSMakeRange(0, metaTag.count))
                if contentMatches.first == nil {
                    let contentRegexp = try! NSRegularExpression(
                        pattern: "\\scontent=\\\\*?'(.*?)\\\\*?'",
                        options: []
                    )
                    contentMatches = contentRegexp.matches(in: metaTag, options: [], range: NSMakeRange(0, metaTag.count))
                }
                guard let contentResult = contentMatches.first else { return nil }
                
                let nsMetaTag = metaTag as NSString
                let property = nsMetaTag.substring(with: propertyResult.range(at: 1))
                let content = nsMetaTag.substring(with: contentResult.range(at: 1))
                
                return (name: property, content: content)
            }()
            if let property = property {
                copiedAttributes[property.name] = property.content
            }
            return copiedAttributes
        }
        
        return attributes
    }
}
