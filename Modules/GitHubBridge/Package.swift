// swift-tools-version:5.5
import PackageDescription


let package = Package(
	name: "GitHubBridge",
	platforms: [.iOS(.v12)],
	products: [.library(name: "GitHubBridge", targets: ["GitHubBridge"])],
	dependencies: [
		.package(url: "https://github.com/Frizlab/LinkHeaderParser.git", branch: "main")
	],
	targets: [
		.target(name: "GitHubBridge", dependencies: [
			.product(name: "LinkHeaderParser", package: "LinkHeaderParser")
		]/*, swiftSettings: [
			.unsafeFlags(["-Xfrontend", "-warn-concurrency", "-Xfrontend", "-enable-actor-data-race-checks"])
		]*/)
	]
)
