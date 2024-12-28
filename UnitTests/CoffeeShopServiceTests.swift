//
//  CoffeeShopServiceTests.swift
//  CoffeeVibes
//
//  Created by Brian Foster on 11/23/24.
//

import XCTest
@testable import CoffeeVibes

final class CoffeeShopServiceTests: XCTestCase {
    @MainActor var coffeeShopService: CoffeeShopService!

    override func setUp() async throws {
        try await super.setUp()
        await MainActor.run {
            coffeeShopService = CoffeeShopService()
        }
    }

    override func tearDown() async throws {
        await MainActor.run {
            coffeeShopService = nil
        }
        try await super.tearDown()
    }

    func testGetAllCoffeeShops() async throws {
        let expectation = self.expectation(description: "Fetch coffee shops")

        await coffeeShopService.getAllCoffeeShops { shops, error in
            if let error = error {
                XCTFail("Error fetching coffee shops: \(error.localizedDescription)")
            } else if let shops = shops {
                XCTAssertGreaterThan(shops.count, 0, "No coffee shops fetched")
                XCTAssertEqual(shops[0].name, "The Cozy Corner", "First shop's name mismatch")
            }
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 5)
    }

    func testGetFavoriteCoffeeShops() async throws {
        let expectation = self.expectation(description: "Fetch favorite coffee shops")

        await coffeeShopService.getFavoriteCoffeeShops(by: "user-id") { favorites, error in
            if let error = error {
                XCTFail("Error fetching favorite coffee shops: \(error.localizedDescription)")
            } else if let favorites = favorites {
                XCTAssertGreaterThan(favorites.count, 0, "No favorite coffee shops fetched")
                XCTAssertEqual(favorites[0].name, "Brew & Chill", "First favorite shop's name mismatch")
            }
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 5)
    }
}

