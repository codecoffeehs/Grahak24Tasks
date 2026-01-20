//
//  TaskRequests.swift
//  GrahakTasks
//
//  Created by Hemant Sharma on 20/01/26.
//
import Foundation

struct TaskRequests : Identifiable,Codable{
    let id : String
    var title: String
    var invitedByUserEmail : String
    var sharedOn : String
}
