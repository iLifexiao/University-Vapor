//
//  UtilityBillController.swift
//  App
//
//  Created by 肖权 on 2018/11/8.
//

import Vapor
import FluentPostgreSQL

final class UtilityBillController: RouteCollection {
    
    func boot(router: Router) throws {
        let group = router.grouped("api", "v1", "utilitybill")
        group.get("all", use: getAllHandler)
        group.get(UtilityBill.parameter, use: getHandler)
        
        group.post(UtilityBill.self, use: createHandler)
        group.patch(UtilityBill.parameter, use: updateHandler)
        group.delete(UtilityBill.parameter, use: deleteHandler)
        
        group.get("search", use: searchHandler)        
        group.get("sort", use: sortedHandler)
    }
    
}

extension UtilityBillController {
    func getAllHandler(_ req: Request) throws -> Future<[UtilityBill]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return UtilityBill.query(on: req).all()
    }
    
    // id
    func getHandler(_ req: Request) throws -> Future<UtilityBill> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(UtilityBill.self)
    }
    
    func createHandler(_ req: Request, utilityBill: UtilityBill) throws -> Future<UtilityBill> {
        _ = try req.requireAuthenticated(APIUser.self)
        utilityBill.createdAt = Date().timeIntervalSince1970
        utilityBill.status = 1
        return utilityBill.save(on: req)
    }
    
    // id
    func updateHandler(_ req: Request) throws -> Future<UtilityBill> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try flatMap(to: UtilityBill.self, req.parameters.next(UtilityBill.self), req.content.decode(UtilityBill.self)) { utilityBill, newUtilityBill in
            utilityBill.site = newUtilityBill.site
            utilityBill.time = newUtilityBill.time
            utilityBill.electricityPrice = newUtilityBill.electricityPrice
            utilityBill.waterPrice = newUtilityBill.waterPrice
            utilityBill.hotWaterPrice = newUtilityBill.hotWaterPrice            
            utilityBill.updatedAt = Date().timeIntervalSince1970
            return utilityBill.save(on: req)
        }
    }
    
    // id
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(UtilityBill.self).delete(on: req).transform(to: .ok)
    }
    
    // search?term=
    func searchHandler(_ req: Request) throws -> Future<[UtilityBill]> {
        _ = try req.requireAuthenticated(APIUser.self)
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        guard let searchYear = req.query[String.self, at: "year"] else {
            throw Abort(.badRequest)
        }
        return UtilityBill.query(on: req).filter(\.site == searchTerm).filter(\.time == searchYear).all()
    }
    
    func sortedHandler(_ req: Request) throws -> Future<[UtilityBill]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return UtilityBill.query(on: req).sort(\.createdAt, .ascending).all()
    }
}
