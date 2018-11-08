//
//  middlewares.swift
//  App
//
//  Created by 肖权 on 2018/11/7.
//

import Vapor

public func middlewares(config: inout MiddlewareConfig) throws {
    // 1. 跨域请求设置
    let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: .all,
        allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin]
    )
    let corsMiddleware = CORSMiddleware(configuration: corsConfiguration)
    config.use(corsMiddleware)
    
    // 2. 静态资源 Serves files from `Public/` directory
    config.use(FileMiddleware.self)
    
    // 3. 错误处理 Catches errors and converts to HTTP response
    config.use(ErrorMiddleware.self)
}
