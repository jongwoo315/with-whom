import Contacts
#if canImport(WithWhomCore)
import WithWhomCore
#endif

struct ContactsSource {
    enum SourceError: Error { case denied }

    /// 이름(given·family)만 읽는다.
    func contacts() async throws -> [Contact] {
        let store = CNContactStore()
        guard try await store.requestAccess(for: .contacts) else { throw SourceError.denied }
        let request = CNContactFetchRequest(keysToFetch: [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
        ])
        var result: [Contact] = []
        try store.enumerateContacts(with: request) { contact, _ in
            result.append(Contact(given: contact.givenName, family: contact.familyName))
        }
        return result
    }
}
