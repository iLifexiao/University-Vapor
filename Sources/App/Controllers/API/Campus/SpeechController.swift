//
//  SpeechController.swift
//  App
//
//  Created by 肖权 on 2018/11/8.
//

import Vapor
import FluentPostgreSQL

final class SpeechController: RouteCollection {
    
    func boot(router: Router) throws {
        let group = router.grouped("api", "v1", "speech")
        group.get("all", use: getAllHandler)
        group.get(Speech.parameter, use: getHandler)
        
        group.post(Speech.self, use: createHandler)
        group.patch(Speech.parameter, use: updateHandler)
        group.delete(Speech.parameter, use: deleteHandler)
        
        group.get("search", use: searchHandler)
        group.get("split", use: getPageHandler)
        group.get("sort", use: sortedHandler)
    }
    
}

extension SpeechController {
    func getAllHandler(_ req: Request) throws -> Future<[Speech]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Speech.query(on: req).filter(\.status != 0).all()
    }
    
    func getPageHandler(_ req: Request) throws -> Future<[Speech]> {
        _ = try req.requireAuthenticated(APIUser.self)
        guard let page = req.query[String.self, at: "page"] else {
            throw Abort(.badRequest)
        }
        // 查询失败，则返回最新的5条
        let up = (Int(page) ?? 1) * 5
        let low = up - 5
        
        return Speech.query(on: req).filter(\.status != 0).sort(\.createdAt, .descending).range(low..<up).all()
    }
    
    // id
    func getHandler(_ req: Request) throws -> Future<Speech> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Speech.self)
    }
    
    func createHandler(_ req: Request, speech: Speech) throws -> Future<Speech> {
        _ = try req.requireAuthenticated(APIUser.self)
        speech.createdAt = Date().timeIntervalSince1970
        speech.status = 1
        return speech.save(on: req)
    }
    
    // id
    func updateHandler(_ req: Request) throws -> Future<Speech> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try flatMap(to: Speech.self, req.parameters.next(Speech.self), req.content.decode(Speech.self)) { speech, newSpeech in
            speech.speaker = newSpeech.speaker
            speech.title = newSpeech.title
            speech.site = newSpeech.site
            speech.time = newSpeech.time
            speech.company = newSpeech.company
            speech.updatedAt = Date().timeIntervalSince1970
            return speech.save(on: req)
        }
    }
    
    // id
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        _ = try req.requireAuthenticated(APIUser.self)
        return try req.parameters.next(Speech.self).delete(on: req).transform(to: .ok)
    }
    
    // search?term=
    func searchHandler(_ req: Request) throws -> Future<[Speech]> {
        _ = try req.requireAuthenticated(APIUser.self)
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        return Speech.query(on: req).group(.or) { or in
            or.filter(\.speaker == searchTerm)
            or.filter(\.title == searchTerm)
            or.filter(\.site == searchTerm)
        }.all()
    }
    
    func sortedHandler(_ req: Request) throws -> Future<[Speech]> {
        _ = try req.requireAuthenticated(APIUser.self)
        return Speech.query(on: req).filter(\.status != 0).sort(\.createdAt, .descending).all()
    }
}

