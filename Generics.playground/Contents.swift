import UIKit

protocol APIRequest {
    associatedtype Response
    
    var urlRequest: URLRequest { get }
    func decodeResponse(data: Data) throws -> Response
}

enum APIRequestError: Error {
    case itemNotFound
}

// Generic method that is able to send a request and return a concrete type that adopts "APIRequest".
func sendRequest<Request: APIRequest>(_ request: Request) async throws -> Request.Response {
    let (data, response) = try await URLSession.shared.data(for: request.urlRequest)
    
    guard let httpReponse = response as? HTTPURLResponse, httpReponse.statusCode == 200 else {
        throw APIRequestError.itemNotFound
    }
    
    let decodedResponse = try request.decodeResponse(data: data)
    return(decodedResponse)
}

struct PhotoInfo: Codable {
    var title: String
    var description: String
    var url: URL
    var copyright: String?
    
    enum CodingKeys: String, CodingKey {
        case title
        case description = "explanation"
        case url
        case copyright
    }
}

struct PhotoInfoAPIRequest: APIRequest {
    var apiKey: String
    
    var urlRequest: URLRequest {
        var urlComponents = URLComponents(string: "https://api.nasa.gov/planetary/apod")!
        urlComponents.queryItems = [URLQueryItem(name: "date", value: "2023-01-20"), URLQueryItem(name: "api_key", value: apiKey)]
        
        return URLRequest(url: urlComponents.url!)
    }
    
    func decodeResponse(data: Data) throws -> PhotoInfo {
        let photoInfo = try JSONDecoder().decode(PhotoInfo.self, from: data)
        return photoInfo
    }
}

struct ImageAPIRequest: APIRequest {
    enum ResponseError: Error {
        case invalidImageData
    }
    
    let url: URL
    
    var urlRequest: URLRequest {
        return URLRequest(url: url)
    }
    
    func decodeResponse(data: Data) throws -> UIImage {
        guard let image = UIImage(data: data) else {
            throw ResponseError.invalidImageData
        }
        return image
    }
}

let photoInfoRequest = PhotoInfoAPIRequest(apiKey: "DEMO_KEY")
Task {
    do {
        let photoInfo = try await sendRequest(photoInfoRequest)
        let imageRequest = ImageAPIRequest(url: photoInfo.url)
        let image = try await sendRequest(imageRequest)
        image
    } catch {
        print(error)
    }
}
