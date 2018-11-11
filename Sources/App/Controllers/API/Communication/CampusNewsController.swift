//
//  CampusNewsController.swift
//  App
//
//  Created by 肖权 on 2018/11/8.
//

import Vapor
import FluentPostgreSQL

final class CampusNewsController: RouteCollection {
    
    func boot(router: Router) throws {
        let group = router.grouped("api", "v1", "campusnews")
        group.get("all", use: getAllHandler)
        group.get(CampusNews.parameter, use: getHandler)
        
        group.post(CampusNews.self, use: createHandler)
        group.patch(CampusNews.parameter, use: updateHandler)
        group.delete(CampusNews.parameter, use: deleteHandler)
        
        group.get("search", use: searchHandler)        
        group.get("sort", use: sortedHandler)
    }
    
}

extension CampusNewsController {
    func getAllHandler(_ req: Request) throws -> Future<[CampusNews]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return CampusNews.query(on: req).all()
    }
    
    // id
    func getHandler(_ req: Request) throws -> Future<CampusNews> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(CampusNews.self)
    }
    
    func createHandler(_ req: Request, campusNews: CampusNews) throws -> Future<CampusNews> {
        _ = try req.requireAuthenticated(APIUser.self)
        campusNews.createdAt = Date().timeIntervalSince1970
        campusNews.status = 1
        campusNews.readCount = 0
        campusNews.commentCount = 0
        return campusNews.save(on: req)
    }
    
    // id
    func updateHandler(_ req: Request) throws -> Future<CampusNews> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try flatMap(to: CampusNews.self, req.parameters.next(CampusNews.self), req.content.decode(CampusNews.self)) { campusNews, newCampusNews in
            campusNews.imageURL = newCampusNews.imageURL
            campusNews.title = newCampusNews.title
            campusNews.content = newCampusNews.content
            campusNews.from = newCampusNews.from
            campusNews.type = newCampusNews.type
            campusNews.updatedAt = Date().timeIntervalSince1970
            return campusNews.save(on: req)
        }
    }
    
    // id
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(CampusNews.self).delete(on: req).transform(to: .ok)
    }
    
    // search?term=
    func searchHandler(_ req: Request) throws -> Future<[CampusNews]> {
        _ = try req.requireAuthenticated(APIUser.self)
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        return CampusNews.query(on: req).group(.or) { or in
            or.filter(\.title == searchTerm)            
            or.filter(\.type == searchTerm)
        }.all()
    }
    
    func sortedHandler(_ req: Request) throws -> Future<[CampusNews]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return CampusNews.query(on: req).sort(\.createdAt, .ascending).all()
    }
}