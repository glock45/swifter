# Changelog
All notable changes to this project will be documented in this file. Changes notes typically follow this pattern:

> **Fixed**
> * Something was fixed. (#pr-number) by @pr-author
> 
> **Changed**
> * Something was changed. (#pr-number) by @pr-author
> 
> **Added**
> * Something was added. (#pr-number) by @pr-author
> 
> **Removed**
> * Something was removed. (#pr-number) by @pr-author
> 
> **Deprecated**
> * Something was deprecated. (#pr-number) by @pr-author

# [Unreleased]

## Added
- Add support for using `**` as a catch-all at the end of a route. ([#479](https://github.com/httpswift/swifter/pull/479)) by [@michaelenger](https://github.com/michaelenger)
- Set `Content-Type` to HttpBody and Text HttpResponse. ([#474](https://github.com/httpswift/swifter/pull/474)) by [@mtgto](https://github.com/mtgto)

## Fixed

* Fix misspell `serialise`. ([#473](https://github.com/httpswift/swifter/pull/473)) by [@mtgto](https://github.com/mtgto)
* Fix an issue causing Danger was not working properly. ([#486](https://github.com/httpswift/swifter/pull/486)) by [@Vkt0r](https://github.com/Vkt0r)

# [1.5.0]

## Added
- Add two new cases to the responses (`notAcceptable`, `tooManyRequests`). ([#437](https://github.com/httpswift/swifter/pull/437)) by [@KKuzmichev](https://github.com/KKuzmichev)

## Fixed
- Fix an issue causing a crash when the `Content-Lenght` was negative. ([#457](https://github.com/httpswift/swifter/pull/457)) by [@Vkt0r](https://github.com/Vkt0r)

## Changed

- Fix `SUPPORTED_PLATFORMS` for tvOS. This helps Carthage to build only the specified platform when the option `--platform` is used. ([#464](https://github.com/httpswift/swifter/pull/464)) by [@jasminlapalme](https://github.com/jasminlapalme)


# [1.5.0-rc.1]

## Removed

- Support for the iOS 8 deployment target. ([#462](https://github.com/httpswift/swifter/pull/462)) by [@Vkt0r](https://github.com/Vkt0r)

## Added

- Add the `trailing_whitespace` rule in Swiftlint and autocorrect all the source files. ([#421](https://github.com/httpswift/swifter/pull/421)) by [@Vkt0r](https://github.com/Vkt0r)
- Update the project for Xcode 11.1. ([#438](https://github.com/httpswift/swifter/pull/438)) by [@Vkt0r](https://github.com/Vkt0r)
- Add optional 'Content-Type' to Data HttpResponse. ([#450](https://github.com/httpswift/swifter/pull/450)) by [@SoftwareEngineerChris](https://github.com/SoftwareEngineerChris)
- Support Xcode 12 and Swift 5+. ([#462](https://github.com/httpswift/swifter/pull/462)) by [@Vkt0r](https://github.com/Vkt0r)

## Changed

- Turn `HttpServer` and `HttpServerIO` into open classes to allow for more customization. ([#443](https://github.com/httpswift/swifter/pull/443)) by [@cobbal](https://github.com/cobbal)
- Set the version of the HTTP Server based in the project version in the **Info.plist** for macOS, iOS and tvOS platforms. ([#416](https://github.com/httpswift/swifter/pull/416)) by [@Vkt0r](https://github.com/Vkt0r)
- Update `HttpParser` so it percent-encodes the URL components before initializing `URLComponents`. ([#423](https://github.com/httpswift/swifter/pull/423)) by [@nejcvivod](https://github.com/nejcvivod)
- Update `SwifterTestsHttpParser` with a test for parsing bracketed query strings. ([#423](https://github.com/httpswift/swifter/pull/423)) by [@nejcvivod](https://github.com/nejcvivod)
- Use `swift_version` CocoaPods DSL. ([#425](https://github.com/httpswift/swifter/pull/425)) by [@dnkoutso](https://github.com/dnkoutso)
- Fix compiler warnings in Socket+File.swift for iOS, tvOS, and Linux platforms by using `withUnsafeBytes` rather than `&` to get a scoped UnsafeRawPointer ([#445](https://github.com/httpswift/swifter/pull/445)) by [@kbongort](https://github.com/kbongort).
- Fix tests on linux by importing FoundationNetworking for NSURLSession APIs. ([#446](https://github.com/httpswift/swifter/pull/446)) by [@kbongort](https://github.com/kbongort)
- Replace CircleCI for continuous integration in favor of Github Actions. ([#446](https://github.com/httpswift/swifter/pull/446)) by [@Vkt0r](https://github.com/Vkt0r)

# [1.4.7] 

## Added
- A new `CHANGELOG.md` to keep track of changes in the project. ([#385](https://github.com/httpswift/swifter/pull/385)) by [@Vkt0r](https://github.com/Vkt0r)
- Added [Danger](https://danger.systems/ruby/) and Swiftlint to the project. ([#398](https://github.com/httpswift/swifter/pull/398)) by [@Vkt0r](https://github.com/Vkt0r)
- Added the following to `Scopes`: `manifest`, `ontouchstart`, `dataText`. ([#410](https://github.com/httpswift/swifter/pull/410)) by [@apocolipse](https://github.com/apocolipse)
- Added `htmlBody(String)` to `HttpResonse`  as a compability case for the changed `html(String)` case.

## Fixed
- An issue causing a crash regarding a thread race condition. ([#399](https://github.com/httpswift/swifter/pull/399)) by [@Vkt0r](https://github.com/Vkt0r)
- An issue in the `HttpRouter` causing issues to handle routes with overlapping in the tail. ([#379](https://github.com/httpswift/swifter/pull/359), [#382](https://github.com/httpswift/swifter/pull/382)) by [@Vkt0r](https://github.com/Vkt0r)

- Fixes build errors by excluding XC(UI)Test files from regular targets [#397](https://github.com/httpswift/swifter/pull/397)) by [@ChristianSteffens](https://github.com/ChristianSteffens)
- Fixes `HttpRequest.path` value to be parsed without query parameters [#404](https://github.com/httpswift/swifter/pull/404)) by [@mazyod](https://github.com/mazyod)
- Fixes the issue of missing `Content-Length` header item when `shareFilesFromDirectory` is being used to share files [#406](https://github.com/httpswift/swifter/pull/406) by [@nichbar](https://github.com/nichbar)

## Changed
- Performance: Batch reads of websocket payloads rather than reading byte-by-byte. ([#387](https://github.com/httpswift/swifter/pull/387)) by [@lynaghk](https://github.com/lynaghk)
- Podspec source_files updated to match source file directory changes. ([#400](https://github.com/httpswift/swifter/pull/400)) by [@welsonpan](https://github.com/welsonpan)
- Refactor: Use Foundation API for Base64 encoding. ([#403](https://github.com/httpswift/swifter/pull/403)) by [@mazyod](https://github.com/mazyod)
- Refactor: Use `URLComponents` for `HttpRequest` path and query parameters parsing [#404](https://github.com/httpswift/swifter/pull/404)) by [@mazyod](https://github.com/mazyod)
- `HttpResponse` functions `statusCode()` and `reasonPhrase` changed to computed variables instead of functions, and made public (No impact on existing usage as it was previously internal). ([#410](https://github.com/httpswift/swifter/pull/410)) by [@apocolipse](https://github.com/apocolipse)
- Adjusted the associated type of enum case `HttpResponseBody.json` from `AnyObject` to `Any` to allow Swift dictionaries/arrays without converting to their Objective-C counterparts. ([#393](https://github.com/httpswift/swifter/pull/393)) by [@edwinveger](https://github.com/edwinveger)
- `HttpResponse`: `html` requires now a complete html-string, not only the body-part.
- Include the `CHANGELOG.md` and `README.md` in the Xcode-Project for easy access / changes.

## Removed
- Dropped macOS 10.9 support ([#404](https://github.com/httpswift/swifter/pull/404), [#408](https://github.com/httpswift/swifter/pull/408)) by [@mazyod](https://github.com/mazyod), [@Vkt0r](https://github.com/Vkt0r)

# [1.4.6] 
## Added
 -  The `.movedTemporarily` case (HTTP 307) to possibles HTTP responses. ([#352](https://github.com/httpswift/swifter/pull/352)) by [@csch](https://github.com/csch)
 - An example to the `README` for `"How to load HTML by string?"`. ([#352](https://github.com/httpswift/swifter/pull/352)) by [@IvanovDeveloper]( https://github.com/IvanovDeveloper)
 - CircleCI for Continous Integration in the project. ([#364](https://github.com/httpswift/swifter/pull/364)) by [@Vkt0r](https://github.com/Vkt0r)
 - Support for the Swift 5. ([#370](https://github.com/httpswift/swifter/pull/370)) by [@alanzeino](https://github.com/alanzeino)

## Changed
- The syntax to support Swift 3 and Swift 4. ([#347](https://github.com/httpswift/swifter/pull/347)) by [@fandyfyf](https://github.com/fandyfyf)
- Set to `NO` the `ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES` in the **tvOS** target to avoid App Store checks due to the _Frameworks_ directory. ([#361](https://github.com/httpswift/swifter/pull/361)) by [@Vkt0r](https://github.com/Vkt0r)
- The process of reading of request body and headers. ([#362](https://github.com/httpswift/swifter/pull/362)) by [@adamkaplan](https://github.com/adamkaplan)

## Fixed
- An issue in the `HttpRouter` causing issues to handle routes with overlapping. ([#359](https://github.com/httpswift/swifter/pull/359)) by [@Vkt0r](https://github.com/Vkt0r)


[Unreleased]: https://github.com/httpswift/swifter/compare/1.5.0...HEAD
[1.4.6]: https://github.com/httpswift/swifter/compare/1.4.5...1.4.6
[1.4.7]: https://github.com/httpswift/swifter/compare/1.4.6...1.4.7
[1.5.0-rc.1]: https://github.com/httpswift/swifter/compare/1.4.7...1.5.0-rc.1
[1.5.0]: https://github.com/httpswift/swifter/compare/1.5.0-rc.1...1.5.0
