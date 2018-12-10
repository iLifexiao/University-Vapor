//
//  AddressListController.swift
//  App
//
//  Created by 肖权 on 2018/11/8.
//

import Vapor
import FluentPostgreSQL

final class AddressListController: RouteCollection {
    
    func boot(router: Router) throws {
        let group = router.grouped("api", "v1", "addresslist")
        group.get("all", use: getAllHandler)
        group.get(AddressList.parameter, use: getHandler)
        
        group.post(AddressList.self, use: createHandler)
        group.patch(AddressList.parameter, use: updateHandler)
        group.delete(AddressList.parameter, use: deleteHandler)
        
        group.get("search", use: searchHandler)
        group.get("split", use: getPageHandler)
        group.get("sort", use: sortedHandler)
    }
    
}

extension AddressListController {
    func getAllHandler(_ req: Request) throws -> Future<[AddressList]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return AddressList.query(on: req).filter(\.status != 0).all()
    }
    
    func getPageHandler(_ req: Request) throws -> Future<[AddressList]> {
        _ = try req.requireAuthenticated(APIUser.self)
        guard let page = req.query[String.self, at: "page"] else {
            throw Abort(.badRequest)
        }
        // 查询失败，则返回最新的10条
        let up = (Int(page) ?? 1) * 10
        let low = up - 10
        
        return AddressList.query(on: req).filter(\.status != 0).sort(\.createdAt, .descending).range(low..<up).all()
    }
    
    // id
    func getHandler(_ req: Request) throws -> Future<AddressList> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(AddressList.self)
    }
    
    func createHandler(_ req: Request, addressList: AddressList) throws -> Future<AddressList> {
        _ = try req.requireAuthenticated(APIUser.self)
        addressList.createdAt = Date().timeIntervalSince1970
        addressList.status = 1
        return addressList.save(on: req)
    }
    
    // id
    func updateHandler(_ req: Request) throws -> Future<AddressList> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try flatMap(to: AddressList.self, req.parameters.next(AddressList.self), req.content.decode(AddressList.self)) { addressList, newAddressList in
            addressList.name = newAddressList.name
            addressList.phone = newAddressList.phone
            addressList.type = newAddressList.type
            addressList.updatedAt = Date().timeIntervalSince1970
            return addressList.save(on: req)
        }
    }
    
    // id
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(AddressList.self).delete(on: req).transform(to: .ok)
    }
    
    // search?term=
    func searchHandler(_ req: Request) throws -> Future<[AddressList]> {
        _ = try req.requireAuthenticated(APIUser.self)
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        return AddressList.query(on: req).group(.or) { or in
            or.filter(\.name == searchTerm)
            or.filter(\.phone == searchTerm)
            or.filter(\.type == searchTerm)
            }.all()
    }
    
    func sortedHandler(_ req: Request) throws -> Future<[AddressList]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return AddressList.query(on: req).filter(\.status != 0).sort(\.createdAt, .descending).all()
    }
}

