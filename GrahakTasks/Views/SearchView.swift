//
//  SearchView.swift
//  GrahakTasks
//
//  Created by Hemant Sharma on 09/01/26.
//

import SwiftUI

struct SearchView: View {
    @State private var searchTerm = ""
    var body: some View {
        NavigationStack{
            Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
        }.navigationTitle("Serach Tasks")
        .searchable(text:$searchTerm)
    }
   
}

#Preview {
    SearchView()
}
