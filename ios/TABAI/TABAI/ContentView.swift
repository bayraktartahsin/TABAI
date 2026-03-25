//
//  ContentView.swift
//  TAI
//
//  Created by Tahsin Bayraktar on 19.02.2026.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        RootView()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppEnvironment(keychain: KeychainStore(), featureFlags: FeatureFlags(useTABAI: false)))
    }
}
