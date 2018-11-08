//
//  CampusNews.swift
//  App
//
//  Created by 肖权 on 2018/11/7.
//

import Vapor
import FluentPostgreSQL

final class CampusNews: PostgreSQLModel {
    var id: Int?
    
    var imageURL: String
    var title: String
    var content: String
    var from: String // 来源：校内、网络等等
    var type: String // 科技、教育、社会等等
    var commentCount: Int
    var readCount: Int

    var status: Int // 状态[0, 1] = [禁止, 正常]
    var createdAt: TimeInterval? // 创建时间
    
    
    init(id: Int? = nil, imageURL: String, title: String, content: String, from: String, type: String, commentCount: Int = 0, readCount: Int = 0, status: Int = 1) {
        self.id = id
        self.imageURL = imageURL
        self.title = title
        self.content = content
        self.from = from
        self.type = type
        self.commentCount = commentCount
        self.readCount = readCount
        self.status = status
    }
}

extension CampusNews: PostgreSQLMigration { }
extension CampusNews: Content { }
extension CampusNews: Parameter { }
