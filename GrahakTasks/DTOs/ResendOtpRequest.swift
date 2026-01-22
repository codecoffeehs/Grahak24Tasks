//
//  ResendOtpRequest.swift
//  GrahakTasks
//
//  Created by Hemant Sharma on 22/01/26.
//

struct ResendOtpRequest: Encodable {
    let email: String
    let otpPurpose: Int
}
