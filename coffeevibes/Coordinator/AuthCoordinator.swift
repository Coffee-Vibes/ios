//
//  AuthCoordinator.swift
//  CoffeeVibes
//
//  Created by Andrew Trach on 12/6/24.
//

import Foundation
import SwiftUI
import FlowStacks

class AuthCoordinatorViewModel: ObservableObject {
    enum Screen {
        case login
        case signUp
        case optCode(email: String)
        case createProfile
        case forgotPass
        case resetPass
        case succsesfull
    }
    
    @Published var routes: Routes<Screen> = [.root(.login, embedInNavigationView: true)]
    
    func goBack() {
        routes.goBack()
    }

}

struct AuthCoordinator: View {
    @StateObject var viewModel: AuthCoordinatorViewModel
    
    var body: some View {
        Router($viewModel.routes) { screen, _ in
            switch screen {
            case .login:
                LoginView() { event in
                    switch event {
                    case .back:
                        viewModel.goBack()
                    case .signUp:
                        viewModel.routes.push(.signUp)
                    }
                }
            case .signUp:
                SignUpView() { event in
                    switch event {
                    case .back:
                        viewModel.goBack()
                    case .optCode(let email):
                        viewModel.routes.push(.optCode(email: email))
                    }
                }
            case .optCode(let email):
                OTPVerificationView(onEvent: { event in
                    switch event {
                    case .back:
                        viewModel.goBack()
                    case .createProfile:
                        viewModel.routes.push(.createProfile)
                    }
                }, email: email)
            case .createProfile:
                CreateProfileView()
            case .forgotPass:
                ForgotPasswordView()
            case .resetPass:
                LoginView() { event in
                    switch event {
                    case .back:
                        viewModel.goBack()
                    case .signUp:
                        viewModel.routes.push(.signUp)
                    }
                }
            case .succsesfull:
                LoginView() { event in
                    switch event {
                    case .back:
                        viewModel.goBack()
                    case .signUp:
                        viewModel.routes.push(.signUp)
                    }
                }
            }
        }
    }
}
