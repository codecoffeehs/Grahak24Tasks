//
//  APIError.swift
//  GrahakTasks
//
//  Created by Hemant Sharma on 06/01/26.
//

import Foundation

struct ApiErrorResponse : Codable{
    let message : String
}

struct ApiError: LocalizedError {
    let message: String

    var errorDescription: String? {
        message
    }
}
