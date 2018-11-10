//
//  Speech.swift
//  App
//
//  Created by 肖权 on 2018/11/7.
//

import Vapor
import FluentPostgreSQL

final class Speech: PostgreSQLModel {
    var id: Int?
    
    var speaker: String
    var title: String
    var site: String
    var time: String
    var company: String
    
    var status: Int? // 状态[0, 1] = [禁止, 正常]
    var createdAt: TimeInterval? // 创建时间
    var updatedAt: TimeInterval? // 更新时间
    
    init(id: Int? = nil, speaker: String, title: String, site: String, time: String, company: String, status: Int? = 1) {
        self.id = id
        self.speaker = speaker
        self.title = title
        self.site = site
        self.time = time
        self.company = company
        self.status = status
    }
}

extension Speech: PostgreSQLMigration { }
extension Speech: Content { }
extension Speech: Parameter { }
