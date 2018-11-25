//
//  UploadFileController.swift
//  App
//
//  Created by 肖权 on 2018/11/24.
//

import Vapor
import FluentPostgreSQL

final class UploadFileController: RouteCollection {
    
    func boot(router: Router) throws {
        let group = router.grouped("api", "v1", "upload")
        group.post("image", use: uploadImageHandle)
    }
    
}

extension UploadFileController {
    /// 上传图片并返回图片路径
    func uploadImageHandle(_ req: Request) throws -> Future<Response> {
        _ = try req.requireAuthenticated(APIUser.self)
        
        // 获取文件上传的保存路径「book/club/idlegoods/lostandfound/resource/head」
        return req.content.get(String.self, at: "type").flatMap { type in
            // 获得服务器的工作路径
            let directory = DirectoryConfig.detect()
            let workPath = directory.workDir
            
            // 生成文件唯一的名字
            let name = UUID().uuidString + ".png"
            
            // 上传的测试路径
            let imageFolder = "Public/image/\(type)"
            let saveURL = URL(fileURLWithPath: workPath).appendingPathComponent(imageFolder, isDirectory: true).appendingPathComponent(name, isDirectory: false)
            
            // 上传的参数包含image即可
            // 上传类型:form-data
            return req.content.get(File.self, at: "image").flatMap { file in
                do {
                    guard file.data.count <= ImageMaxByteSize else {
                        return try ResponseJSON<Empty>(status: .imageToBig).encode(for: req)
                    }                    
                    try file.data.write(to: saveURL)
                    return try ResponseJSON<Empty>(status: .ok, message: "/image/\(type)/\(name)").encode(for: req)
                } catch {
                    throw Abort(.internalServerError, reason: "Unable to write multipart form data to file. Underlying error \(error)")
                }
            }
        }
    }
}
