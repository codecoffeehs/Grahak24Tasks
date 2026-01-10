//
//  SearchView.swift
//  GrahakTasks
//
//  Created by Hemant Sharma on 10/01/26.
//

import SwiftUI

struct SearchView: View {
    @State private  var searchText = ""
    var body: some View {
        NavigationStack{
            Text("Search View")
        }.navigationTitle("Search")
            .searchable(text: $searchText)
        
    }
}

#Preview {
    SearchView()
}
