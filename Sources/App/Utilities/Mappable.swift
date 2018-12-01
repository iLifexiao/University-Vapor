//
//  Mappable.swift
//  App
//
//  Created by 肖权 on 2018/12/1.
//

// 用于序列化字典
protocol Mappable {
    
    func toDictionary() -> [String : Any]
    
}
