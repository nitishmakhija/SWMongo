// swift-tools-version:4.2
// Generated automatically by Perfect Assistant
// Date: 2019-06-10 09:04:30 +0000
import PackageDescription

#if os(Linux)
let cOpenSSLRepo = "https://github.com/PerfectlySoft/Perfect-COpenSSL-Linux.git"
#else
let cOpenSSLRepo = "https://github.com/PerfectlySoft/Perfect-COpenSSL.git"
#endif

let package = Package(
	name: "MongoKitten",
	products: [
		.library(name: "MongoKitten", targets: ["MongoKitten"]),
	],
	dependencies: [
        .package(url: cOpenSSLRepo, from: "4.0.0")
	],
	targets: [
        .target(name: "BSON", dependencies: []),
        .target(name: "CryptoKitten", dependencies: []),
        .target(name: "Cheetah", dependencies: []),
        .target(name: "MongoSocket", dependencies: ["COpenSSL"]),
        .target(name: "ExtendedJSON", dependencies: ["CryptoKitten", "Cheetah", "BSON"]),
        .target(name: "GeoJSON", dependencies: ["BSON"]),
		.target(name: "MongoKitten", dependencies: ["GeoJSON", "MongoSocket", "ExtendedJSON"]),
		.testTarget(name: "MongoKittenTests", dependencies: ["MongoKitten"])
	]
)
