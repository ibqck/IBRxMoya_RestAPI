import Foundation

public class IBRESTFileSystem {
    public let documentsDirectory: URL = {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.endIndex - 1]
    }()

    static let documentsDirectory: URL = {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.endIndex - 1]
    }()

    public let cacheDirectory: URL = {
        let urls = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        return urls[urls.endIndex - 1]
    }()

    public let downloadDirectory: URL = {
        let directory: URL = IBRESTFileSystem.documentsDirectory.appendingPathComponent("/RESTAPI_Download/")
        return directory
    }()

    public init() {
    }

}

