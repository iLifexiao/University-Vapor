//
//  ResponseJSON.swift
//  App
//
//  Created by 肖权 on 2018/11/9.
//

import Vapor

// 返回Data为空时使用
struct Empty: Content {}

// 用于格式化JSON输出
struct ResponseJSON<T: Content>: Content {
    
    private var status: ResponseStatus
    private var message: String
    private var data: T?
    
    init(data: T) {
        self.status = .ok
        self.message = status.desc
        self.data = data
    }
    
    init(status:ResponseStatus = .ok) {
        self.status = status
        self.message = status.desc
        self.data = nil
    }
    
    
    init(status:ResponseStatus = .ok,
         message: String = ResponseStatus.ok.desc) {
        self.status = status
        self.message = message
        self.data = nil
    }
    
    init(status:ResponseStatus = .ok,
         message: String = ResponseStatus.ok.desc,
         data: T?) {
        self.status = status
        self.message = message
        self.data = data
    }
}

// 返回JSON的状态码
enum ResponseStatus:Int, Content {
    case ok = 0
    case error = 1
    case missesPara = 3
    
    case unknown = 10
    
    case userExist = 20
    case userNotExist = 21
    case accountOrPwdError = 22
    
    case registerCodeInvalid = 30
    
    var desc : String {
        switch self {
        case .ok:
            return "请求成功"
        case .error:
            return "请求失败"
        case .missesPara:
            return "缺少参数"
        case .unknown:
            return "未知失败"
        case .userExist:
            return "用户已存在"
        case .userNotExist:
            return "用户不存在"
        case .accountOrPwdError:
            return "帐号或密码错误"
        case .registerCodeInvalid:
            return "注册码无效"
        }        
    }
}