//
//  PrimaryActionButton.swift
//  GrahakTasks
//
//  Created by Hemant Sharma on 07/01/26.
//
import SwiftUI

struct PrimaryActionButton : View {
    let title:String
    let isLoading: Bool
    let isDisabled:Bool
    let action: () async -> Void
    var body : some View{
        Button {
            Task {
                await action()
            }
        } label: {
            HStack {
                if isLoading {
                    ProgressView()
                } else {
                    Text(title)
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
        }
        .tint(Color.orange)
        .buttonStyle(.borderedProminent)
        .disabled(isDisabled)
    }
}
