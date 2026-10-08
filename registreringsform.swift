//
//  registreringsform.swift
//  GithubSamples
//
//  Created by Domos Szegi on 2026-10-08.
//

import Foundation
import Combine

class CreateAccountViewModel: FormViewModel<(name: String, email: String, password: String)> {
    
    // Controls whether the username is valid and available
    @Published private(set) var isUsernameValid: Bool?
    
    // This will turn icons to ProgressView() during usename query
    @Published private(set) var usernameRequestActive: Bool = false
    
    // Computed property based on username validity
    var iconColor: Color {
        if value.name.isEmpty {
            return AppColor.textInActive
        } else {
            switch isUsernameValid {
            case nil:
                return AppColor.textInActive
            case true:
                return AppColor.fieldValid
            case false:
                return .red
            }
        }
    }
    
    // Cancellables
    private var cancellables = Set<AnyCancellable>()
    
    // Designated initializer
    override init(initialValue: (name: String, email: String, password: String), action: @escaping Action) {
        super.init(initialValue: initialValue, action: action)
        // Extract the username from the generic value (Value in FormViewModel), and check if it's available
        $value
            .map(\.name)
            .filter { !$0.isEmpty }
            .debounce(for: .milliseconds(400), scheduler: RunLoop.main)
            .removeDuplicates()
            .map { username in
                Deferred {
                    Future<String?, Never> { promise in
                        newUsernameExists(username) { available in
                            promise(.success(available ? username : nil))
                        }
                    }
                }
                .handleEvents(
                    receiveSubscription: { [weak self] _ in self?.usernameRequestActive = true },
                    receiveCompletion:   { [weak self] _ in self?.usernameRequestActive = false },
                    receiveCancel:       { [weak self] in self?.usernameRequestActive = false }
                )
            }
            .switchToLatest()
            .receive(on: RunLoop.main)
            .sink { [weak self] username in
                // If username is available, set the boolean value controlling validity to true
                self?.isUsernameValid = (username != nil)
            }
            .store(in: &cancellables)
    }
    
    // Single parameter (action) — no extra closures needed
    convenience init(action: @escaping Action) {
        // 1. Init
        self.init(initialValue: (name: "", email: "", password: ""), action: action)
    }
}

// Defines letters, numbers and the following characters as valid: ".", "_"
private static let validCharacters =
    CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "._"))

// Checks that the characters are part of valid charactes
private static func areCharactersValid(on name: String, maxLength: Int = 30) -> Bool {
    // Check length
    guard name.count <= maxLength else { return false }
    
    // Check that all characters are valid
    return name.unicodeScalars.allSatisfy { validCharacters.contains($0) }
}

private static func newUsernameExists(_ username: String, completion: @escaping(Bool) -> Void) {
    // If there ar invalid characters, complete with false and return
    if !areCharactersValid(on: username) {
        completion(false)
        return
    }
    
    // Firestore
    let db = Firestore.firestore()
    
    // Query the firestore database for the typed in username
    db.collection("usernames").document(username).getDocument { snapshot, error in
        
        // Check that there was not error returned from the API call
        if let error = error {
            // If there was an error contacting the backend, then this is a high priority error, and should send a notification
            // but the user should see their chosen name as available and get a specific error when they try to register instead
            // to be informed why the app is unusable.
            completion(false)
            print(error.localizedDescription)
            return
        }
        
        // If there was no error, unwrap the response
        guard let snapshot = snapshot else {
            // It could throw an error, but I will let the error be thrown when the user tries to register
            return
        }
        
        // If snapshot.exists == false, then !snapshot.exists = true, so I can use "available" in the closure outside the function
        completion(!snapshot.exists)
    }
}
