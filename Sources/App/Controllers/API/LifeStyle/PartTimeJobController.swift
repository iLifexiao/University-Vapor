//
//  PartTimeJobController.swift
//  App
//
//  Created by 肖权 on 2018/11/8.
//

import Vapor
import FluentPostgreSQL

final class PartTimeJobController: RouteCollection {
    
    func boot(router: Router) throws {
        let group = router.grouped("api", "v1", "parttimejob")
        group.get("all", use: getAllHandler)
        group.get(PartTimeJob.parameter, use: getHandler)
        
        group.post(PartTimeJob.self, use: createHandler)
        group.patch(PartTimeJob.parameter, use: updateHandler)
        group.delete(PartTimeJob.parameter, use: deleteHandler)
        
        group.get("search", use: searchHandler)        
        group.get("sort", use: sortedHandler)
    }
    
}

extension PartTimeJobController {
    func getAllHandler(_ req: Request) throws -> Future<[PartTimeJob]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return PartTimeJob.query(on: req).all()
    }
    
    // id
    func getHandler(_ req: Request) throws -> Future<PartTimeJob> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(PartTimeJob.self)
    }
    
    func createHandler(_ req: Request, partTimeJob: PartTimeJob) throws -> Future<PartTimeJob> {
        _ = try req.requireAuthenticated(APIUser.self)
        partTimeJob.createdAt = Date().timeIntervalSince1970
        return partTimeJob.save(on: req)
    }
    
    // id
    func updateHandler(_ req: Request) throws -> Future<PartTimeJob> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try flatMap(to: PartTimeJob.self, req.parameters.next(PartTimeJob.self), req.content.decode(PartTimeJob.self)) { partTimeJob, newPartTimeJob in
            partTimeJob.title = newPartTimeJob.title
            partTimeJob.imageURL = newPartTimeJob.imageURL
            partTimeJob.company = newPartTimeJob.company
            partTimeJob.price = newPartTimeJob.price
            partTimeJob.introduce = newPartTimeJob.introduce
            partTimeJob.site = newPartTimeJob.site
            partTimeJob.deadLine = newPartTimeJob.deadLine
            partTimeJob.phone = newPartTimeJob.phone
            partTimeJob.updatedAt = Date().timeIntervalSince1970
            return partTimeJob.save(on: req)
        }
    }
    
    // id
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(PartTimeJob.self).delete(on: req).transform(to: .ok)
    }
    
    // search?term=
    func searchHandler(_ req: Request) throws -> Future<[PartTimeJob]> {
        _ = try req.requireAuthenticated(APIUser.self)
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        return PartTimeJob.query(on: req).group(.or) { or in
            or.filter(\.title == searchTerm)
            or.filter(\.company == searchTerm)
            or.filter(\.introduce == searchTerm)
            or.filter(\.site == searchTerm)
            or.filter(\.phone == searchTerm)
        }.all()
    }
    
    func sortedHandler(_ req: Request) throws -> Future<[PartTimeJob]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return PartTimeJob.query(on: req).sort(\.createdAt, .ascending).all()
    }
}
