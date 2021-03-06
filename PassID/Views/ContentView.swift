//
//  ContentView.swift
//  PassID
//
//  Created by smlu on 03/12/2019.
//  Copyright © 2019 ZeroPass. All rights reserved.
//

import SwiftUI


struct ContentView: View {

    init() {
        UITableView.appearance().backgroundColor = .systemGray6
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                    .frame(height: 75)
                NavigationLink(destination: ActionView(action: .register)) {
                    ButtonView(text: "Register")
                }
                Spacer()
                    .frame(height: 10)
                NavigationLink(destination: ActionView(action: .login)) {
                    ButtonView(text: "Login")
                }
                Spacer()
            }
            .navigationBarTitle("PassID")
            .navigationBarItems(trailing: SettingsButton())
            .background(
                Color(UIColor.systemGray6).edgesIgnoringSafeArea(.all)
            )
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
                .environment(\.colorScheme, .dark)
        }
    }
}
