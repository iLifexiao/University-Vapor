//
//  CollectionController.swift
//  App
//
//  Created by 肖权 on 2018/11/8.
//

import Vapor
import FluentPostgreSQL

final class CollectionController: RouteCollection {
    
    func boot(router: Router) throws {
        let group = router.grouped("api", "v1", "collection")
        group.get("all", use: getAllHandler)
        group.get(Collection.parameter, use: getHandler)
        
        group.post(Collection.self, use: createHandler)
        group.post(Collection.DelInfo.self, at: "del", use: deleteByInfoHandler)
        group.delete(Collection.parameter, use: deleteHandler)
                
        group.get("sort", use: sortedHandler)
    }
    
}

extension CollectionController {
    func getAllHandler(_ req: Request) throws -> Future<[Collection]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Collection.query(on: req).filter(\.status != 0).all()
    }
    
    // id
    func getHandler(_ req: Request) throws -> Future<Collection> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Collection.self)
    }
    
    func createHandler(_ req: Request, collection: Collection) throws -> Future<Response> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Collection.query(on: req).filter(\.userID == collection.userID).filter(\.collectionID == collection.collectionID).first().flatMap { fetchCollection in
            guard fetchCollection == nil else {
                return try ResponseJSON<Empty>(status: .error, message: "你已经收藏了~").encode(for: req)
            }
            
            collection.createdAt = Date().timeIntervalSince1970
            collection.status = 1
            return collection.save(on: req).flatMap { _ in
                return try ResponseJSON<Empty>(status: .ok, message: "收藏成功，去个人中心看看吧~").encode(for: req)
            }
        }
    }
    
    func deleteByInfoHandler(_ req: Request, info: Collection.DelInfo) throws -> Future<Response> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Collection.query(on: req).filter(\.userID == info.userID).filter(\.collectionID == info.collectionID).first().flatMap { fetchCollection in
            guard let existCollection = fetchCollection else {
                return try ResponseJSON<Empty>(status: .error, message: "该收藏已经删除了~").encode(for: req)
            }
            return existCollection.delete(on: req).flatMap { _ in
                return try ResponseJSON<Empty>(status: .ok, message: "删除成功").encode(for: req)
            }
        }
    }
    
    // id
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Collection.self).delete(on: req).transform(to: .ok)
    }
    
    func sortedHandler(_ req: Request) throws -> Future<[Collection]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Collection.query(on: req).filter(\.status != 0).sort(\.createdAt, .descending).all()
    }
}

