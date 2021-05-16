//
//  SwifterTestsHttpRouter.swift
//  Swifter
//

//  Copyright © 2016 Damian Kołakowski. All rights reserved.
//

import XCTest
@testable import Swifter

class SwifterTestsHttpRouter: XCTestCase {

    var router: HttpRouter!

    override func setUp() {
        super.setUp()
        router = HttpRouter()
    }

    override func tearDown() {
        router = nil
        super.tearDown()
    }

    func testHttpRouterSlashRoot() {

        router.register(nil, path: "/", handler: { _ in
            return .ok(.htmlBody("OK"))
        })

        XCTAssertNotNil(router.route(nil, path: "/"))
    }

    func testHttpRouterSimplePathSegments() {

        router.register(nil, path: "/a/b/c/d", handler: { _ in
            return .ok(.htmlBody("OK"))
        })

        XCTAssertNil(router.route(nil, path: "/"))
        XCTAssertNil(router.route(nil, path: "/a"))
        XCTAssertNil(router.route(nil, path: "/a/b"))
        XCTAssertNil(router.route(nil, path: "/a/b/c"))
        XCTAssertNotNil(router.route(nil, path: "/a/b/c/d"))
    }

    func testHttpRouterSinglePathSegmentWildcard() {

        router.register(nil, path: "/a/*/c/d", handler: { _ in
            return .ok(.htmlBody("OK"))
        })

        XCTAssertNil(router.route(nil, path: "/"))
        XCTAssertNil(router.route(nil, path: "/a"))
        XCTAssertNotNil(router.route(nil, path: "/a/foo/c/d"))
        XCTAssertNotNil(router.route(nil, path: "/a/b/c/d"))
        XCTAssertNil(router.route(nil, path: "/a/b"))
        XCTAssertNil(router.route(nil, path: "/a/b/foo/d"))
    }

    func testHttpRouterVariables() {

        router.register(nil, path: "/a/:arg1/:arg2/b/c/d/:arg3", handler: { _ in
            return .ok(.htmlBody("OK"))
        })

        XCTAssertNil(router.route(nil, path: "/"))
        XCTAssertNil(router.route(nil, path: "/a"))
        XCTAssertNil(router.route(nil, path: "/a/b/c/d"))
        XCTAssertEqual(router.route(nil, path: "/a/value1/value2/b/c/d/value3")?.0[":arg1"], "value1")
        XCTAssertEqual(router.route(nil, path: "/a/value1/value2/b/c/d/value3")?.0[":arg2"], "value2")
        XCTAssertEqual(router.route(nil, path: "/a/value1/value2/b/c/d/value3")?.0[":arg3"], "value3")
    }

    func testHttpRouterMultiplePathSegmentWildcards() {

        router.register(nil, path: "/a/**/e/f/g", handler: { _ in
            return .ok(.htmlBody("OK"))
        })

        XCTAssertNil(router.route(nil, path: "/"))
        XCTAssertNil(router.route(nil, path: "/a"))
        XCTAssertNotNil(router.route(nil, path: "/a/b/c/d/e/f/g"))
        XCTAssertNil(router.route(nil, path: "/a/e/f/g"))
    }

    func testHttpRouterMultiplePathSegmentWildcardTail() {

        router.register(nil, path: "/a/b/**", handler: { _ in
            return .ok(.htmlBody("OK"))
        })

        XCTAssertNil(router.route(nil, path: "/"))
        XCTAssertNil(router.route(nil, path: "/a"))
        XCTAssertNotNil(router.route(nil, path: "/a/b/c/d/e/f/g"))
        XCTAssertNil(router.route(nil, path: "/a/e/f/g"))
    }

    func testHttpRouterEmptyTail() {

        router.register(nil, path: "/a/b/", handler: { _ in
            return .ok(.htmlBody("OK"))
        })

        router.register(nil, path: "/a/b/:var", handler: { _ in
            return .ok(.htmlBody("OK"))
        })

        XCTAssertNil(router.route(nil, path: "/"))
        XCTAssertNil(router.route(nil, path: "/a"))
        XCTAssertNotNil(router.route(nil, path: "/a/b/"))
        XCTAssertNil(router.route(nil, path: "/a/e/f/g"))

        XCTAssertEqual(router.route(nil, path: "/a/b/value1")?.0[":var"], "value1")

        XCTAssertEqual(router.route(nil, path: "/a/b/")?.0[":var"], nil)
    }

    func testHttpRouterPercentEncodedPathSegments() {

        router.register(nil, path: "/a/<>/^", handler: { _ in
            return .ok(.htmlBody("OK"))
        })

        XCTAssertNil(router.route(nil, path: "/"))
        XCTAssertNil(router.route(nil, path: "/a"))
        XCTAssertNotNil(router.route(nil, path: "/a/%3C%3E/%5E"))
    }

    func testHttpRouterHandlesOverlappingPaths() {

        let request = HttpRequest()

        let staticRouteExpectation = expectation(description: "Static Route")
        var foundStaticRoute = false
        router.register("GET", path: "a/b") { _ in
            foundStaticRoute = true
            staticRouteExpectation.fulfill()
            return HttpResponse.accepted
        }

        let variableRouteExpectation = expectation(description: "Variable Route")
        var foundVariableRoute = false
        router.register("GET", path: "a/:id/c") { _ in
            foundVariableRoute = true
            variableRouteExpectation.fulfill()
            return HttpResponse.accepted
        }

        let staticRouteResult = router.route("GET", path: "a/b")
        let staticRouterHandler = staticRouteResult?.1
        XCTAssertNotNil(staticRouteResult)
        _ = staticRouterHandler?(request)

        let variableRouteResult = router.route("GET", path: "a/b/c")
        let variableRouterHandler = variableRouteResult?.1
        XCTAssertNotNil(variableRouteResult)
        _ = variableRouterHandler?(request)

        waitForExpectations(timeout: 10, handler: nil)
        XCTAssertTrue(foundStaticRoute)
        XCTAssertTrue(foundVariableRoute)
    }

    func testHttpRouterHandlesOverlappingPathsInDynamicRoutes() {

        let request = HttpRequest()

        let firstVariableRouteExpectation = expectation(description: "First Variable Route")
        var foundFirstVariableRoute = false
        router.register("GET", path: "a/:id") { _ in
            foundFirstVariableRoute = true
            firstVariableRouteExpectation.fulfill()
            return HttpResponse.accepted
        }

        let secondVariableRouteExpectation = expectation(description: "Second Variable Route")
        var foundSecondVariableRoute = false
        router.register("GET", path: "a/:id/c") { _ in
            foundSecondVariableRoute = true
            secondVariableRouteExpectation.fulfill()
            return HttpResponse.accepted
        }

        let firstRouteResult = router.route("GET", path: "a/b")
        let firstRouterHandler = firstRouteResult?.1
        XCTAssertNotNil(firstRouteResult)
        _ = firstRouterHandler?(request)

        let secondRouteResult = router.route("GET", path: "a/b/c")
        let secondRouterHandler = secondRouteResult?.1
        XCTAssertNotNil(secondRouteResult)
        _ = secondRouterHandler?(request)

        waitForExpectations(timeout: 10, handler: nil)
        XCTAssertTrue(foundFirstVariableRoute)
        XCTAssertTrue(foundSecondVariableRoute)
    }

    func testHttpRouterShouldHandleOverlappingRoutesInTrail() {

        let request = HttpRequest()

        let firstVariableRouteExpectation = expectation(description: "First Variable Route")
        var foundFirstVariableRoute = false
        router.register("GET", path: "/a/:id") { _ in
            foundFirstVariableRoute = true
            firstVariableRouteExpectation.fulfill()
            return HttpResponse.accepted
        }

        let secondVariableRouteExpectation = expectation(description: "Second Variable Route")
        var foundSecondVariableRoute = false
        router.register("GET", path: "/a") { _ in
            foundSecondVariableRoute = true
            secondVariableRouteExpectation.fulfill()
            return HttpResponse.accepted
        }

        let thirdVariableRouteExpectation = expectation(description: "Third Variable Route")
        var foundThirdVariableRoute = false
        router.register("GET", path: "/a/:id/b") { _ in
            foundThirdVariableRoute = true
            thirdVariableRouteExpectation.fulfill()
            return HttpResponse.accepted
        }

        let firstRouteResult = router.route("GET", path: "/a")
        let firstRouterHandler = firstRouteResult?.1
        XCTAssertNotNil(firstRouteResult)
        _ = firstRouterHandler?(request)

        let secondRouteResult = router.route("GET", path: "/a/b")
        let secondRouterHandler = secondRouteResult?.1
        XCTAssertNotNil(secondRouteResult)
        _ = secondRouterHandler?(request)

        let thirdRouteResult = router.route("GET", path: "/a/b/b")
        let thirdRouterHandler = thirdRouteResult?.1
        XCTAssertNotNil(thirdRouteResult)
        _ = thirdRouterHandler?(request)

        waitForExpectations(timeout: 10, handler: nil)
        XCTAssertTrue(foundFirstVariableRoute)
        XCTAssertTrue(foundSecondVariableRoute)
        XCTAssertTrue(foundThirdVariableRoute)
    }

    func testHttpRouterHandlesOverlappingPathsInDynamicRoutesInTheMiddle() {

        let request = HttpRequest()

        let firstVariableRouteExpectation = expectation(description: "First Variable Route")
        var foundFirstVariableRoute = false
        router.register("GET", path: "/a/b/c/d/e") { _ in
            foundFirstVariableRoute = true
            firstVariableRouteExpectation.fulfill()
            return HttpResponse.accepted
        }

        let secondVariableRouteExpectation = expectation(description: "Second Variable Route")
        var foundSecondVariableRoute = false
        router.register("GET", path: "/a/:id/f/g") { _ in
            foundSecondVariableRoute = true
            secondVariableRouteExpectation.fulfill()
            return HttpResponse.accepted
        }

        let firstRouteResult = router.route("GET", path: "/a/b/c/d/e")
        let firstRouterHandler = firstRouteResult?.1
        XCTAssertNotNil(firstRouteResult)
        _ = firstRouterHandler?(request)

        let secondRouteResult = router.route("GET", path: "/a/b/f/g")
        let secondRouterHandler = secondRouteResult?.1
        XCTAssertNotNil(secondRouteResult)
        _ = secondRouterHandler?(request)

        waitForExpectations(timeout: 10, handler: nil)
        XCTAssertTrue(foundFirstVariableRoute)
        XCTAssertTrue(foundSecondVariableRoute)
    }
}
