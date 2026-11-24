import SwiftUI
import PhotosUI
import LocalAuthentication
import UserNotifications
import StoreKit
import Combine

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - Entry Point
// ═══════════════════════════════════════════════════════════════════════════

struct ContentView: View {
    @StateObject private var appStore = ShiftStore()

    var body: some View {
        Group {
            if !appStore.config.isSetupComplete {
                SetupWizardView()
                    .environmentObject(appStore)
            } else {
                NavigationStack { WelcomeView() }
                    .environmentObject(appStore)
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - Models
// ═══════════════════════════════════════════════════════════════════════════

// ── Roles ─────────────────────────────────────────────────────────────────

enum AppRole: String, Codable, CaseIterable, Identifiable {
    case admin      = "admin"
    case supervisor = "supervisor"
    case lead       = "lead"
    case worker     = "worker"
    var id: String { rawValue }
}

// ── Custom Labels (everything renameable) ─────────────────────────────────

struct CustomLabels: Codable {
    // Role display names
    var adminName:      String = "Admin"
    var supervisorName: String = "Supervisor"
    var leadName:       String = "Lead"
    var workerName:     String = "Worker"

    // Core concepts
    var overtimeTerm:    String = "Overtime"
    var slotTerm:        String = "Slot"
    var waitlistTerm:    String = "Waitlist"
    var claimTerm:       String = "Claim"
    var departmentTerm:  String = "Department"
    var shiftTerm:       String = "Shift"
    var positionTerm:    String = "Position"
    var employeeTerm:    String = "Employee ID"

    // Nav / Screen labels
    var leadershipLabel:      String = "Leadership Access"
    var teamMemberLabel:      String = "Team Member"
    var dashboardTitle:       String = "Dashboard"
    var postRequestLabel:     String = "Post Request"
    var claimSlotLabel:       String = "Claim Slot"
    var joinWaitlistLabel:    String = "Join Waitlist"
    var confirmedLabel:       String = "Confirmed"
    var activeLabel:          String = "Active"
    var notActiveLabel:       String = "Not Active"
    var remainingOpenLabel:   String = "Remaining Open"
    var filledLabel:          String = "Filled"
    var requestedLabel:       String = "Requested"
    var skillsNotesLabel:     String = "Skills / Notes"
    var staffingReqLabel:     String = "Staffing Requirement"
    var howManyNeededLabel:   String = "How many people are needed?"
    var removeLabel:          String = "Remove Me"
    var signOutLabel:         String = "Sign Out"
    var notificationsLabel:   String = "Notifications"
    var workAreasLabel:       String = "Work Areas"
    var appTagline:           String = "Workforce Shift Manager"
    var selectAccessLabel:    String = "Select your access path"
}

// ── Member Field Configuration ─────────────────────────────────────────────

struct MemberFieldConfig: Codable {
    // Free tier fields
    var showPhone: Bool       = true
    var phoneRequired: Bool   = false
    var showEmployeeID: Bool   = true
    var employeeIDRequired: Bool = false

    // Premium fields
    var showShift: Bool            = false   // premium
    var shiftRequired: Bool        = false
    var showPosition: Bool         = false   // premium
    var positionRequired: Bool     = false
    var showDeptOnProfile: Bool    = false   // premium

    // Visibility permissions
    var leadCanSeePhone: Bool        = false
    var workerCanSeeOthersNames: Bool = true
}

// ── Color Theme ────────────────────────────────────────────────────────────

struct ColorTheme: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let primaryR: Double
    let primaryG: Double
    let primaryB: Double
    let accentR: Double
    let accentG: Double
    let accentB: Double
    let isPremium: Bool

    var primary: Color { Color(red: primaryR, green: primaryG, blue: primaryB) }
    var accent:  Color { Color(red: accentR,  green: accentG,  blue: accentB)  }

    static let all: [ColorTheme] = [
        // ── Free ──
        ColorTheme(id: "blue",       name: "Professional Blue",  primaryR: 0.05, primaryG: 0.14, primaryB: 0.25, accentR: 0.00, accentG: 0.37, accentB: 0.66, isPremium: false),
        ColorTheme(id: "green",      name: "Forest Green",       primaryR: 0.05, primaryG: 0.22, primaryB: 0.10, accentR: 0.10, accentG: 0.50, accentB: 0.18, isPremium: false),
        ColorTheme(id: "charcoal",   name: "Charcoal",           primaryR: 0.12, primaryG: 0.14, primaryB: 0.16, accentR: 0.28, accentG: 0.32, accentB: 0.38, isPremium: false),
        // ── Premium ──
        ColorTheme(id: "purple",     name: "Royal Purple",       primaryR: 0.22, primaryG: 0.05, primaryB: 0.38, accentR: 0.50, accentG: 0.10, accentB: 0.80, isPremium: true),
        ColorTheme(id: "crimson",    name: "Crimson",            primaryR: 0.45, primaryG: 0.04, primaryB: 0.08, accentR: 0.80, accentG: 0.10, accentB: 0.15, isPremium: true),
        ColorTheme(id: "orange",     name: "Sunset Orange",      primaryR: 0.48, primaryG: 0.18, primaryB: 0.00, accentR: 0.90, accentG: 0.40, accentB: 0.05, isPremium: true),
        ColorTheme(id: "teal",       name: "Ocean Teal",         primaryR: 0.00, primaryG: 0.28, primaryB: 0.32, accentR: 0.00, accentG: 0.55, accentB: 0.62, isPremium: true),
        ColorTheme(id: "rosegold",   name: "Rose Gold",          primaryR: 0.40, primaryG: 0.20, primaryB: 0.18, accentR: 0.72, accentG: 0.45, accentB: 0.42, isPremium: true),
        ColorTheme(id: "midnight",   name: "Midnight",           primaryR: 0.04, primaryG: 0.04, primaryB: 0.14, accentR: 0.15, accentG: 0.18, accentB: 0.45, isPremium: true),
        ColorTheme(id: "emerald",    name: "Emerald",            primaryR: 0.00, primaryG: 0.28, primaryB: 0.16, accentR: 0.00, accentG: 0.55, accentB: 0.32, isPremium: true),
        ColorTheme(id: "slate",      name: "Slate",              primaryR: 0.18, primaryG: 0.26, primaryB: 0.32, accentR: 0.30, accentG: 0.46, accentB: 0.56, isPremium: true),
        ColorTheme(id: "burntorg",   name: "Burnt Orange",       primaryR: 0.42, primaryG: 0.20, primaryB: 0.02, accentR: 0.75, accentG: 0.38, accentB: 0.05, isPremium: true),
        ColorTheme(id: "sky",        name: "Sky Blue",           primaryR: 0.02, primaryG: 0.30, primaryB: 0.55, accentR: 0.10, accentG: 0.58, accentB: 0.90, isPremium: true),
        ColorTheme(id: "hotpink",    name: "Hot Pink",           primaryR: 0.45, primaryG: 0.05, primaryB: 0.28, accentR: 0.85, accentG: 0.10, accentB: 0.55, isPremium: true),
        ColorTheme(id: "gold",       name: "Gold",               primaryR: 0.32, primaryG: 0.24, primaryB: 0.00, accentR: 0.70, accentG: 0.55, accentB: 0.00, isPremium: true),
    ]

    static var defaultTheme: ColorTheme { all[0] }
    static func find(_ id: String) -> ColorTheme { all.first(where: { $0.id == id }) ?? defaultTheme }
}

// ── Custom Department ──────────────────────────────────────────────────────

struct CustomDepartment: Codable, Identifiable, Equatable, Hashable {
    let id: String
    var name: String
    var subtitle: String
    var iconName: String

    static let availableIcons: [String] = [
        "chart.bar.doc.horizontal.fill","gearshape.2.fill","wrench.and.screwdriver.fill",
        "truck.box.fill","shippingbox.fill","person.3.fill","building.2.fill","hammer.fill",
        "bolt.fill","cpu.fill","leaf.fill","shield.fill","cart.fill","phone.fill",
        "doc.text.fill","flame.fill","airplane","car.fill","pencil.and.ruler.fill",
        "archivebox.fill","paintbrush.pointed.fill","printer.fill","stethoscope",
        "figure.walk","cross.fill","antenna.radiowaves.left.and.right",
        "bed.double.fill","fork.knife","music.note","sportscourt.fill",
        "theatermasks.fill","graduationcap.fill","briefcase.fill","bus.fill"
    ]

    static func generateCode() -> String {
        let chars = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0..<8).compactMap { _ in chars.randomElement() })
    }
}

// ── Company Config ─────────────────────────────────────────────────────────

struct CompanyConfig: Codable {
    var companyName: String              = ""
    var departments: [CustomDepartment]  = []
    var labels: CustomLabels             = CustomLabels()
    var fieldConfig: MemberFieldConfig   = MemberFieldConfig()
    var selectedThemeID: String          = "blue"
    var supervisorCodes: [String: String] = [:]
    var teamMemberCodes: [String: String] = [:]
    var adminCode: String                = ""
    var isSetupComplete: Bool            = false

    var theme: ColorTheme { ColorTheme.find(selectedThemeID) }
}

// ── Claim Record ───────────────────────────────────────────────────────────

struct ClaimRecord: Codable, Identifiable, Equatable {
    let id: String
    let userID: String
    let displayName: String
    let email: String
    let phone: String
    let timestamp: Date
}

// ── Department Overtime State ──────────────────────────────────────────────

struct DepartmentOvertimeState: Codable, Identifiable {
    var id: String { departmentID }
    let departmentID: String
    var overtimeNeeded: Bool          = false
    var peopleNeeded: Int             = 1
    var comments: String              = ""
    var confirmedClaims: [ClaimRecord] = []
    var waitlistClaims: [ClaimRecord]  = []

    var remainingOpenSlots: Int { max(peopleNeeded - confirmedClaims.count, 0) }
    var hasActiveClaims: Bool {
        overtimeNeeded || !confirmedClaims.isEmpty || !waitlistClaims.isEmpty
    }
}

// ── Team Member Account ────────────────────────────────────────────────────

struct TeamMemberAccount: Codable, Identifiable {
    let id: String
    var firstName: String
    var lastName: String
    var email: String
    var password: String
    var departmentID: String
    var role: AppRole
    var phone: String
    var employeeID: String
    var shift: String
    var position: String
    var faceIDEnabled: Bool
    var notificationsEnabled: Bool

    init(id: String, firstName: String, lastName: String, email: String,
         password: String, departmentID: String, role: AppRole,
         phone: String = "", employeeID: String = "",
         shift: String = "", position: String = "") {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.password = password
        self.departmentID = departmentID
        self.role = role
        self.phone = phone
        self.employeeID = employeeID
        self.shift = shift
        self.position = position
        self.faceIDEnabled = false
        self.notificationsEnabled = false
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id                   = try c.decode(String.self,   forKey: .id)
        firstName            = try c.decode(String.self,   forKey: .firstName)
        lastName             = try c.decode(String.self,   forKey: .lastName)
        email                = try c.decode(String.self,   forKey: .email)
        password             = try c.decode(String.self,   forKey: .password)
        departmentID         = try c.decodeIfPresent(String.self, forKey: .departmentID) ?? ""
        role                 = try c.decodeIfPresent(AppRole.self, forKey: .role) ?? .worker
        phone                = try c.decodeIfPresent(String.self, forKey: .phone) ?? ""
        employeeID           = try c.decodeIfPresent(String.self, forKey: .employeeID) ?? ""
        shift                = try c.decodeIfPresent(String.self, forKey: .shift) ?? ""
        position             = try c.decodeIfPresent(String.self, forKey: .position) ?? ""
        faceIDEnabled        = try c.decodeIfPresent(Bool.self, forKey: .faceIDEnabled) ?? false
        notificationsEnabled = try c.decodeIfPresent(Bool.self, forKey: .notificationsEnabled) ?? false
    }

    var displayName: String { "\(firstName) \(lastName.first.map(String.init) ?? "")." }
    var fullName: String    { "\(firstName) \(lastName)" }
}

// ── Action Result & Error ──────────────────────────────────────────────────

struct ActionResult { let success: Bool; let message: String }

struct AppError: Error, LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - Premium Manager (StoreKit 2)
// ═══════════════════════════════════════════════════════════════════════════

// Configure these product IDs in App Store Connect before submitting
private let kMonthlyProductID  = "com.dattage.HangerTime.monthly"
private let kLifetimeProductID = "com.dattage.HangerTime.lifetime"

// Free tier limits
let kFreeDepartmentLimit = 1
let kFreeMemberLimit     = 10

@MainActor
final class PremiumManager: ObservableObject {
    @Published var isPremium: Bool = false
    @Published var monthlyProduct: Product? = nil
    @Published var lifetimeProduct: Product? = nil
    @Published var isLoading: Bool = false

    static let shared = PremiumManager()
    private init() { Task { await loadProducts() } }

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let products = try await Product.products(for: [kMonthlyProductID, kLifetimeProductID])
            for p in products {
                if p.id == kMonthlyProductID  { monthlyProduct  = p }
                if p.id == kLifetimeProductID { lifetimeProduct = p }
            }
        } catch {
            // Products unavailable — sandbox or no App Store Connect setup yet
        }
        await checkEntitlements()
    }

    func purchase(_ product: Product) async -> Bool {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await checkEntitlements()
                return true
            default:
                return false
            }
        } catch {
            return false
        }
    }

    func restorePurchases() async {
        do {
            try await StoreKit.AppStore.sync()
            await checkEntitlements()
        } catch {}
    }

    func checkEntitlements() async {
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                if transaction.productID == kMonthlyProductID ||
                   transaction.productID == kLifetimeProductID {
                    isPremium = true
                    return
                }
            }
        }
        // Uncomment below to test premium in simulator without StoreKit setup:
        // isPremium = true
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified: throw AppError(message: "Purchase verification failed.")
        case .verified(let value): return value
        }
    }

    // Feature gate helpers
    func canAddDepartment(current: Int) -> Bool { isPremium || current < kFreeDepartmentLimit }
    func canAddMember(current: Int) -> Bool      { isPremium || current < kFreeMemberLimit }
    func canUseTheme(_ theme: ColorTheme) -> Bool { isPremium || !theme.isPremium }
    func canUseField(_ isPremiumField: Bool) -> Bool { isPremium || !isPremiumField }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - Cloud Sync Manager (Firebase-ready stub)
// ═══════════════════════════════════════════════════════════════════════════

// ─────────────────────────────────────────────────────────────────────────
// TO ACTIVATE FIREBASE:
// 1. Create a Firebase project at console.firebase.google.com
// 2. Add an iOS app, download GoogleService-Info.plist into your Xcode project
// 3. Add Firebase via Swift Package Manager:
//    File → Add Package → https://github.com/firebase/firebase-ios-sdk
//    Select: FirebaseFirestore, FirebaseAuth, FirebaseStorage
// 4. In your @main App struct add:
//    import FirebaseCore
//    FirebaseApp.configure()  ← inside init()
// 5. Set isPremium = true in PremiumManager to test cloud (cloud is premium only)
// 6. Uncomment the FirebaseCloudManager class below and delete LocalCloudManager
// ─────────────────────────────────────────────────────────────────────────

protocol CloudSyncManager {
    func saveConfig(_ config: CompanyConfig) async
    func saveMembers(_ members: [TeamMemberAccount]) async
    func saveDepartmentStates(_ states: [DepartmentOvertimeState]) async
    func saveLogoData(_ data: Data?) async
    func loadAll() async -> CloudSnapshot?
}

struct CloudSnapshot {
    var config: CompanyConfig?
    var members: [TeamMemberAccount]
    var states: [DepartmentOvertimeState]
    var logoData: Data?
}

// Local implementation (works without Firebase — default)
final class LocalCloudManager: CloudSyncManager {
    func saveConfig(_ config: CompanyConfig) async {}
    func saveMembers(_ members: [TeamMemberAccount]) async {}
    func saveDepartmentStates(_ states: [DepartmentOvertimeState]) async {}
    func saveLogoData(_ data: Data?) async {}
    func loadAll() async -> CloudSnapshot? { return nil }
}

// ─────────────────────────────────────────────────────────────────────────
// Uncomment this class and delete LocalCloudManager after Firebase setup:
// ─────────────────────────────────────────────────────────────────────────
//
// import FirebaseFirestore
// import FirebaseStorage
//
// final class FirebaseCloudManager: CloudSyncManager {
//     private let db = Firestore.firestore()
//     private let storage = Storage.storage()
//     private var companyID: String { UIDevice.current.identifierForVendor?.uuidString ?? "default" }
//
//     func saveConfig(_ config: CompanyConfig) async {
//         guard let data = try? JSONEncoder().encode(config),
//               let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
//         try? await db.collection("companies").document(companyID).setData(dict)
//     }
//     func saveMembers(_ members: [TeamMemberAccount]) async {
//         guard let data = try? JSONEncoder().encode(members),
//               let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return }
//         try? await db.collection("companies").document(companyID)
//             .collection("members").document("all").setData(["list": arr])
//     }
//     func saveDepartmentStates(_ states: [DepartmentOvertimeState]) async {
//         guard let data = try? JSONEncoder().encode(states),
//               let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return }
//         try? await db.collection("companies").document(companyID)
//             .collection("states").document("all").setData(["list": arr])
//     }
//     func saveLogoData(_ data: Data?) async {
//         guard let data else { return }
//         let ref = storage.reference().child("logos/\(companyID).jpg")
//         try? await ref.putDataAsync(data)
//     }
//     func loadAll() async -> CloudSnapshot? {
//         // Implement real-time listener for production
//         return nil
//     }
// }

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - AppStore (Main ViewModel)
// ═══════════════════════════════════════════════════════════════════════════

@MainActor
final class ShiftStore: ObservableObject {
    @Published var config: CompanyConfig              = CompanyConfig()
    @Published var logoImageData: Data?               = nil
    @Published var departmentStates: [DepartmentOvertimeState] = []
    @Published var teamMembers: [TeamMemberAccount]   = []
    @Published var currentMemberID: String?           = nil
    @Published var rememberedFaceIDUserID: String?    = nil
    @Published var currentSupervisorDeptID: String?   = nil
    @Published var isAdminSession: Bool               = false

    var premium: PremiumManager { PremiumManager.shared }
    var cloud: CloudSyncManager = LocalCloudManager()

    // Convenience
    var labels: CustomLabels   { config.labels }
    var fields: MemberFieldConfig { config.fieldConfig }
    var theme: ColorTheme      { config.theme }

    // Storage keys
    private let kConfig      = "sm_config_v1"
    private let kLogo        = "sm_logo_v1"
    private let kStates      = "sm_states_v1"
    private let kMembers     = "sm_members_v1"
    private let kCurrentUser = "sm_current_user_v1"
    private let kFaceID      = "sm_faceid_user_v1"
    private let kSupervisor  = "sm_supervisor_dept_v1"
    private let kAdminSess   = "sm_admin_session_v1"

    init() { load() }

    // ── Computed ──────────────────────────────────────────────────────────

    var currentMember: TeamMemberAccount? {
        guard let id = currentMemberID else { return nil }
        return teamMembers.first(where: { $0.id == id })
    }
    var currentMemberDisplayName: String { currentMember?.displayName ?? labels.workerName }
    var currentMemberRole: AppRole       { currentMember?.role ?? .worker }
    var currentMemberNotificationsEnabled: Bool { currentMember?.notificationsEnabled ?? false }

    var canUseFaceID: Bool {
        guard let id = rememberedFaceIDUserID else { return false }
        return teamMembers.contains(where: { $0.id == id && $0.faceIDEnabled })
    }
    var currentSupervisorDept: CustomDepartment? {
        guard let id = currentSupervisorDeptID else { return nil }
        return config.departments.first(where: { $0.id == id })
    }

    func departmentState(for id: String) -> DepartmentOvertimeState {
        departmentStates.first(where: { $0.departmentID == id })
            ?? DepartmentOvertimeState(departmentID: id)
    }
    func department(for id: String) -> CustomDepartment? {
        config.departments.first(where: { $0.id == id })
    }

    // ── Setup ─────────────────────────────────────────────────────────────

    func completeSetup(config: CompanyConfig, logoData: Data?) {
        self.config = config
        self.logoImageData = logoData
        self.departmentStates = config.departments.map { DepartmentOvertimeState(departmentID: $0.id) }
        save()
        Task { await syncToCloud() }
    }

    func resetApp() {
        config = CompanyConfig()
        logoImageData = nil
        departmentStates = []
        teamMembers = []
        currentMemberID = nil
        rememberedFaceIDUserID = nil
        currentSupervisorDeptID = nil
        isAdminSession = false
        [kConfig, kLogo, kStates, kMembers, kCurrentUser, kFaceID, kSupervisor, kAdminSess]
            .forEach { UserDefaults.standard.removeObject(forKey: $0) }
    }

    // ── Admin ──────────────────────────────────────────────────────────────

    func verifyAdminCode(_ code: String) -> Bool {
        let ok = code.trimmingCharacters(in: .whitespacesAndNewlines) == config.adminCode
        if ok { isAdminSession = true; save() }
        return ok
    }
    func endAdminSession() { isAdminSession = false; save() }

    func updateCompanyInfo(name: String, logoData: Data?) {
        config.companyName = name
        logoImageData = logoData
        save()
        Task { await cloud.saveConfig(config); await cloud.saveLogoData(logoData) }
    }
    func updateLabels(_ labels: CustomLabels) {
        config.labels = labels; save()
        Task { await cloud.saveConfig(config) }
    }
    func updateFieldConfig(_ fc: MemberFieldConfig) {
        config.fieldConfig = fc; save()
        Task { await cloud.saveConfig(config) }
    }
    func updateTheme(_ themeID: String) {
        config.selectedThemeID = themeID; save()
        Task { await cloud.saveConfig(config) }
    }
    func updateAdminCode(_ code: String) {
        config.adminCode = code; save()
        Task { await cloud.saveConfig(config) }
    }

    func canDeleteDepartment(_ id: String) -> Bool {
        !(departmentStates.first(where: { $0.departmentID == id })?.hasActiveClaims ?? false)
    }
    func updateDepartment(_ dept: CustomDepartment) {
        if let idx = config.departments.firstIndex(where: { $0.id == dept.id }) {
            config.departments[idx] = dept
        } else {
            config.departments.append(dept)
            config.supervisorCodes[dept.id] = CustomDepartment.generateCode()
            config.teamMemberCodes[dept.id]  = CustomDepartment.generateCode()
            departmentStates.append(DepartmentOvertimeState(departmentID: dept.id))
        }
        save()
        Task { await cloud.saveConfig(config); await cloud.saveDepartmentStates(departmentStates) }
    }
    func deleteDepartment(_ id: String) -> Bool {
        guard canDeleteDepartment(id) else { return false }
        config.departments.removeAll { $0.id == id }
        config.supervisorCodes.removeValue(forKey: id)
        config.teamMemberCodes.removeValue(forKey: id)
        departmentStates.removeAll { $0.departmentID == id }
        if currentSupervisorDeptID == id { currentSupervisorDeptID = nil }
        save()
        Task { await cloud.saveConfig(config); await cloud.saveDepartmentStates(departmentStates) }
        return true
    }
    func regenerateSupervisorCode(for id: String) {
        config.supervisorCodes[id] = CustomDepartment.generateCode(); save()
        Task { await cloud.saveConfig(config) }
    }
    func regenerateTeamCode(for id: String) {
        config.teamMemberCodes[id] = CustomDepartment.generateCode(); save()
        Task { await cloud.saveConfig(config) }
    }

    // ── Auth — Supervisor / Admin ─────────────────────────────────────────

    func signInSupervisor(departmentID: String, code: String) -> Result<Void, AppError> {
        let t = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard config.supervisorCodes[departmentID] == t else {
            let name = department(for: departmentID)?.name ?? departmentID
            return .failure(AppError(message: "Incorrect \(labels.supervisorName.lowercased()) code for \(name)."))
        }
        currentSupervisorDeptID = departmentID; save()
        return .success(())
    }
    func signOutSupervisor() { currentSupervisorDeptID = nil; isAdminSession = false; save() }

    // ── Auth — Team Member ────────────────────────────────────────────────

    func createMember(departmentID: String, accessCode: String, firstName: String,
                      lastName: String, email: String, password: String,
                      phone: String, employeeID: String,
                      shift: String, position: String) -> Result<Void, AppError> {

        guard let expected = config.teamMemberCodes[departmentID],
              accessCode.trimmingCharacters(in: .whitespacesAndNewlines) == expected else {
            let name = department(for: departmentID)?.name ?? departmentID
            return .failure(AppError(message: "Incorrect access code for \(name)."))
        }
        let fn = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let ln = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !fn.isEmpty, !ln.isEmpty, !email.isEmpty, !password.isEmpty else {
            return .failure(AppError(message: "Please complete all required fields."))
        }
        let norm = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValidEmail(norm) else {
            return .failure(AppError(message: "Please enter a valid email address."))
        }
        guard !teamMembers.contains(where: { $0.email.lowercased() == norm }) else {
            return .failure(AppError(message: "An account with that email already exists."))
        }

        // Check free limit
        if !premium.isPremium && teamMembers.count >= kFreeMemberLimit {
            return .failure(AppError(message: "FREE_LIMIT_MEMBERS"))
        }

        let account = TeamMemberAccount(
            id: UUID().uuidString, firstName: fn, lastName: ln,
            email: norm, password: password, departmentID: departmentID,
            role: .worker, phone: phone, employeeID: employeeID,
            shift: shift, position: position
        )
        teamMembers.append(account)
        currentMemberID = account.id
        save()
        Task { await cloud.saveMembers(teamMembers) }
        return .success(())
    }

    func signIn(email: String, password: String) -> Result<TeamMemberAccount, AppError> {
        let norm = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard let account = teamMembers.first(where: {
            $0.email.lowercased() == norm && $0.password == password
        }) else {
            return .failure(AppError(message: "Email or password is incorrect."))
        }
        currentMemberID = account.id; save()
        return .success(account)
    }

    func enableFaceID() {
        guard let id = currentMemberID,
              let idx = teamMembers.firstIndex(where: { $0.id == id }) else { return }
        teamMembers[idx].faceIDEnabled = true
        rememberedFaceIDUserID = id
        save()
        Task { await cloud.saveMembers(teamMembers) }
    }

    func signInWithFaceID() -> Result<Void, AppError> {
        guard let id = rememberedFaceIDUserID,
              let account = teamMembers.first(where: { $0.id == id && $0.faceIDEnabled }) else {
            return .failure(AppError(message: "No Face ID account is available on this device."))
        }
        currentMemberID = account.id; save()
        return .success(())
    }

    func signOutMember() { currentMemberID = nil; save() }

    func deleteCurrentMember() {
        guard let id = currentMemberID else { return }

        // Remove from all confirmed and waitlist claims
        for idx in departmentStates.indices {
            departmentStates[idx].confirmedClaims.removeAll { $0.userID == id }
            departmentStates[idx].waitlistClaims.removeAll  { $0.userID == id }
            reconcile(at: idx)
        }

        // Remove the account itself
        teamMembers.removeAll { $0.id == id }

        // Clear Face ID link if it pointed to this account
        if rememberedFaceIDUserID == id { rememberedFaceIDUserID = nil }

        // Sign out
        currentMemberID = nil
        save()
        Task { await cloud.saveMembers(teamMembers); await cloud.saveDepartmentStates(departmentStates) }
    }

    func setNotifications(_ enabled: Bool) {
        guard let id = currentMemberID,
              let idx = teamMembers.firstIndex(where: { $0.id == id }) else { return }
        teamMembers[idx].notificationsEnabled = enabled
        save()
        Task { await cloud.saveMembers(teamMembers) }
    }

    // ── Department Management ──────────────────────────────────────────────

    func setOvertimeNeeded(for deptID: String, needed: Bool) {
        guard let idx = departmentStates.firstIndex(where: { $0.departmentID == deptID }) else { return }
        departmentStates[idx].overtimeNeeded = needed
        if !needed {
            departmentStates[idx].confirmedClaims = []
            departmentStates[idx].waitlistClaims  = []
        }
        save(); Task { await cloud.saveDepartmentStates(departmentStates) }
    }
    func setPeopleNeeded(for deptID: String, count: Int) {
        guard let idx = departmentStates.firstIndex(where: { $0.departmentID == deptID }) else { return }
        departmentStates[idx].peopleNeeded = count
        reconcile(at: idx)
        save(); Task { await cloud.saveDepartmentStates(departmentStates) }
    }
    func setComments(for deptID: String, comments: String) {
        guard let idx = departmentStates.firstIndex(where: { $0.departmentID == deptID }) else { return }
        departmentStates[idx].comments = comments
        save(); Task { await cloud.saveDepartmentStates(departmentStates) }
    }

    // ── Claims ────────────────────────────────────────────────────────────

    func claimStatus(memberID: String, in deptID: String) -> String? {
        guard let state = departmentStates.first(where: { $0.departmentID == deptID }) else { return nil }
        if let claim = state.confirmedClaims.first(where: { $0.userID == memberID }) {
            return "\(labels.confirmedLabel)  •  \(claim.timestamp.displayDateTime)"
        }
        if let pos = state.waitlistClaims.firstIndex(where: { $0.userID == memberID }) {
            return "\(labels.waitlistTerm) #\(pos + 1)  •  \(state.waitlistClaims[pos].timestamp.displayDateTime)"
        }
        return nil
    }

    func globalClaimBlockMessage(for targetID: String, memberID: String) -> String? {
        for state in departmentStates where state.departmentID != targetID {
            let name = department(for: state.departmentID)?.name ?? state.departmentID
            if state.confirmedClaims.contains(where: { $0.userID == memberID }) {
                return "You already have a \(labels.confirmedLabel.lowercased()) \(labels.slotTerm.lowercased()) in \(name). Remove yourself first."
            }
            if state.waitlistClaims.contains(where: { $0.userID == memberID }) {
                return "You are on the \(labels.waitlistTerm.lowercased()) for \(name). Remove yourself first."
            }
        }
        return nil
    }

    func claimSlot(memberID: String, in deptID: String) -> ActionResult {
        guard let member = teamMembers.first(where: { $0.id == memberID }) else {
            return ActionResult(success: false, message: "You must be signed in.")
        }
        guard let idx = departmentStates.firstIndex(where: { $0.departmentID == deptID }) else {
            return ActionResult(success: false, message: "\(labels.departmentTerm) not found.")
        }
        guard departmentStates[idx].overtimeNeeded else {
            return ActionResult(success: false, message: "This section is not accepting \(labels.overtimeTerm.lowercased()) right now.")
        }
        if let block = globalClaimBlockMessage(for: deptID, memberID: memberID) {
            return ActionResult(success: false, message: block)
        }
        if departmentStates[idx].confirmedClaims.contains(where: { $0.userID == memberID }) ||
            departmentStates[idx].waitlistClaims.contains(where: { $0.userID == memberID }) {
            return ActionResult(success: false, message: "You are already listed in this section.")
        }

        let deptName = department(for: deptID)?.name ?? deptID
        let claim = ClaimRecord(
            id: UUID().uuidString, userID: memberID,
            displayName: member.displayName, email: member.email,
            phone: member.phone, timestamp: Date()
        )

        if departmentStates[idx].confirmedClaims.count < departmentStates[idx].peopleNeeded {
            departmentStates[idx].confirmedClaims.append(claim)
            save(); Task { await cloud.saveDepartmentStates(departmentStates) }
            return ActionResult(success: true, message: "\(labels.confirmedLabel) in \(deptName) at \(claim.timestamp.displayDateTime).")
        } else {
            departmentStates[idx].waitlistClaims.append(claim)
            if member.notificationsEnabled {
                scheduleNotification(title: "Added to \(labels.waitlistTerm)",
                                     body: "You joined the \(deptName) \(labels.waitlistTerm.lowercased()).")
            }
            save(); Task { await cloud.saveDepartmentStates(departmentStates) }
            return ActionResult(success: true, message: "Added to the \(deptName) \(labels.waitlistTerm.lowercased()) at \(claim.timestamp.displayDateTime).")
        }
    }

    func removeMemberFromDept(memberID: String, deptID: String) -> ActionResult {
        guard let idx = departmentStates.firstIndex(where: { $0.departmentID == deptID }) else {
            return ActionResult(success: false, message: "Unable to remove your request.")
        }
        let deptName = department(for: deptID)?.name ?? deptID
        let wasConfirmed = departmentStates[idx].confirmedClaims.contains { $0.userID == memberID }
        departmentStates[idx].confirmedClaims.removeAll { $0.userID == memberID }
        departmentStates[idx].waitlistClaims.removeAll  { $0.userID == memberID }
        reconcile(at: idx)
        save(); Task { await cloud.saveDepartmentStates(departmentStates) }
        return wasConfirmed
            ? ActionResult(success: true, message: "Removed from \(labels.confirmedLabel.lowercased()) in \(deptName).")
            : ActionResult(success: true, message: "Removed from the \(deptName) \(labels.waitlistTerm.lowercased()).")
    }

    func removeClaimFromConfirmed(deptID: String, claimID: String) {
        guard let idx = departmentStates.firstIndex(where: { $0.departmentID == deptID }) else { return }
        departmentStates[idx].confirmedClaims.removeAll { $0.id == claimID }
        reconcile(at: idx)
        save(); Task { await cloud.saveDepartmentStates(departmentStates) }
    }
    func removeClaimFromWaitlist(deptID: String, claimID: String) {
        guard let idx = departmentStates.firstIndex(where: { $0.departmentID == deptID }) else { return }
        departmentStates[idx].waitlistClaims.removeAll { $0.id == claimID }
        reconcile(at: idx)
        save(); Task { await cloud.saveDepartmentStates(departmentStates) }
    }

    // ── Private ────────────────────────────────────────────────────────────

    private func reconcile(at index: Int) {
        guard departmentStates.indices.contains(index) else { return }
        let deptID   = departmentStates[index].departmentID
        let deptName = department(for: deptID)?.name ?? deptID

        while departmentStates[index].confirmedClaims.count > departmentStates[index].peopleNeeded {
            let moved = departmentStates[index].confirmedClaims.removeLast()
            departmentStates[index].waitlistClaims.insert(moved, at: 0)
            notifyIfNeeded(moved.userID, title: "Moved to \(labels.waitlistTerm)",
                           body: "Your \(deptName) \(labels.slotTerm.lowercased()) moved to the \(labels.waitlistTerm.lowercased()).")
        }
        while departmentStates[index].confirmedClaims.count < departmentStates[index].peopleNeeded &&
                !departmentStates[index].waitlistClaims.isEmpty {
            let promoted = departmentStates[index].waitlistClaims.removeFirst()
            departmentStates[index].confirmedClaims.append(promoted)
            notifyIfNeeded(promoted.userID, title: "You're \(labels.confirmedLabel)!",
                           body: "You have a \(labels.confirmedLabel.lowercased()) \(labels.slotTerm.lowercased()) in \(deptName).")
        }
    }

    private func notifyIfNeeded(_ userID: String, title: String, body: String) {
        guard let user = teamMembers.first(where: { $0.id == userID }),
              user.notificationsEnabled else { return }
        scheduleNotification(title: title, body: body)
    }

    private func scheduleNotification(title: String, body: String) {
        let content       = UNMutableNotificationContent()
        content.title     = title
        content.body      = body
        content.sound     = .default
        let req = UNNotificationRequest(
            identifier: UUID().uuidString, content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        UNUserNotificationCenter.current().add(req)
    }

    private func isValidEmail(_ email: String) -> Bool {
        let regex = #"^[A-Z0-9a-z._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        return email.range(of: regex, options: .regularExpression) != nil
    }

    private func syncToCloud() async {
        await cloud.saveConfig(config)
        await cloud.saveMembers(teamMembers)
        await cloud.saveDepartmentStates(departmentStates)
        await cloud.saveLogoData(logoImageData)
    }

    func save() {
        let enc = JSONEncoder()
        if let d = try? enc.encode(config) { UserDefaults.standard.set(d, forKey: kConfig) }
        if let d = logoImageData { UserDefaults.standard.set(d, forKey: kLogo) }
        else { UserDefaults.standard.removeObject(forKey: kLogo) }
        if let d = try? enc.encode(departmentStates) { UserDefaults.standard.set(d, forKey: kStates) }
        if let d = try? enc.encode(teamMembers)      { UserDefaults.standard.set(d, forKey: kMembers) }
        UserDefaults.standard.set(currentMemberID,       forKey: kCurrentUser)
        UserDefaults.standard.set(rememberedFaceIDUserID, forKey: kFaceID)
        UserDefaults.standard.set(currentSupervisorDeptID, forKey: kSupervisor)
        UserDefaults.standard.set(isAdminSession,         forKey: kAdminSess)
    }

    private func load() {
        let dec = JSONDecoder()
        if let d = UserDefaults.standard.data(forKey: kConfig),
           let v = try? dec.decode(CompanyConfig.self, from: d) { config = v }
        logoImageData = UserDefaults.standard.data(forKey: kLogo)
        if let d = UserDefaults.standard.data(forKey: kStates),
           let v = try? dec.decode([DepartmentOvertimeState].self, from: d) { departmentStates = v }
        if let d = UserDefaults.standard.data(forKey: kMembers),
           let v = try? dec.decode([TeamMemberAccount].self, from: d) { teamMembers = v }
        currentMemberID        = UserDefaults.standard.string(forKey: kCurrentUser)
        rememberedFaceIDUserID  = UserDefaults.standard.string(forKey: kFaceID)
        currentSupervisorDeptID = UserDefaults.standard.string(forKey: kSupervisor)
        isAdminSession          = UserDefaults.standard.bool(forKey: kAdminSess)
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - Setup Wizard
// ═══════════════════════════════════════════════════════════════════════════

enum SetupStep: Int, CaseIterable {
    case intro=0, company=1, roleNames=2, terminology=3,
         departments=4, memberFields=5, colorTheme=6,
         accessCodes=7, adminCode=8, complete=9
    var total: Int { 8 }  // steps 1-8 are progress tracked
}

struct SetupWizardView: View {
    @EnvironmentObject var appStore: ShiftStore
    @State private var step: SetupStep = .intro
    @State private var errorMessage = ""

    // Step 1 — Company
    @State private var companyName = ""
    @State private var logoData: Data? = nil
    @State private var logoItem: PhotosPickerItem? = nil

    // Step 2 — Role Names
    @State private var adminName      = "Admin"
    @State private var supervisorName = "Supervisor"
    @State private var leadName       = "Lead"
    @State private var workerName     = "Worker"

    // Step 3 — Terminology
    @State private var overtimeTerm   = "Overtime"
    @State private var slotTerm       = "Slot"
    @State private var waitlistTerm   = "Waitlist"
    @State private var claimTerm      = "Claim"
    @State private var deptTerm       = "Department"
    @State private var shiftTerm      = "Shift"
    @State private var positionTerm   = "Position"
    @State private var appTagline     = "Workforce Shift Manager"

    // Step 4 — Departments
    @State private var departments: [CustomDepartment] = []
    @State private var showDeptEditor = false
    @State private var editingDept: CustomDepartment? = nil
    @State private var supervisorCodes: [String: String] = [:]
    @State private var teamCodes: [String: String] = [:]

    // Step 5 — Member Fields
    @State private var showPhone       = true
    @State private var phoneRequired   = false
    @State private var showEmpID       = true
    @State private var empIDRequired   = false
    @State private var showShift       = false
    @State private var showPosition    = false
    @State private var leadSeesPhone   = false
    @State private var workerSeesNames = true

    // Step 6 — Color Theme
    @State private var selectedThemeID = "blue"

    // Step 7 — Codes (display only - auto generated in step 4)

    // Step 8 — Admin Code
    @State private var adminCode        = ""
    @State private var adminCodeConfirm = ""

    var body: some View {
        ZStack {
            themeGradient.ignoresSafeArea()
            // Depth overlay — matches the welcome screen's layered look and
            // guarantees white text stays readable on lighter theme colors.
            LinearGradient(colors: [.black.opacity(0.30), .black.opacity(0.10), .black.opacity(0.38)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 0) {
                if step.rawValue > 0 && step != .complete {
                    progressBar
                        .padding(.top, 56)
                        .padding(.bottom, 6)
                }
                Group {
                    switch step {
                    case .intro:        introStep
                    case .company:      companyStep
                    case .roleNames:    roleNamesStep
                    case .terminology:  terminologyStep
                    case .departments:  departmentsStep
                    case .memberFields: memberFieldsStep
                    case .colorTheme:   colorThemeStep
                    case .accessCodes:  accessCodesStep
                    case .adminCode:    adminCodeStep
                    case .complete:     completeStep
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal:   .move(edge: .leading).combined(with: .opacity)
                ))
                .id(step)
            }
        }
        .animation(.easeInOut(duration: 0.26), value: step)
        .sheet(isPresented: $showDeptEditor) {
            DepartmentEditorSheet(department: editingDept) { saved in
                if let idx = departments.firstIndex(where: { $0.id == saved.id }) {
                    departments[idx] = saved
                } else {
                    departments.append(saved)
                    supervisorCodes[saved.id] = CustomDepartment.generateCode()
                    teamCodes[saved.id]        = CustomDepartment.generateCode()
                }
                editingDept = nil
            }
        }
    }

    // ── Theme gradient for wizard ──────────────────────────────────────────
    private var themeGradient: LinearGradient {
        let t = ColorTheme.find(selectedThemeID)
        return LinearGradient(colors: [t.primary, t.accent],
                              startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    // ── Progress bar ───────────────────────────────────────────────────────
    private var progressBar: some View {
        HStack(spacing: 7) {
            ForEach(1..<9, id: \.self) { s in
                Capsule()
                    .fill(s <= step.rawValue ? Color.white : Color.white.opacity(0.28))
                    .frame(width: s == step.rawValue ? 22 : 7, height: 7)
            }
        }
    }

    // ── Navigation helpers ─────────────────────────────────────────────────
    private func advance(_ to: SetupStep? = nil) {
        errorMessage = ""
        let next = to ?? SetupStep(rawValue: step.rawValue + 1) ?? step
        withAnimation { step = next }
    }
    private func back() {
        errorMessage = ""
        guard let prev = SetupStep(rawValue: step.rawValue - 1) else { return }
        withAnimation { step = prev }
    }

    @ViewBuilder
    private func navRow(canAdvance: Bool, nextLabel: String = "Next →", action: @escaping () -> Void) -> some View {
        VStack(spacing: 10) {
            if !errorMessage.isEmpty && errorMessage != "FREE_LIMIT_DEPARTMENTS" {
                Text(errorMessage)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 8).padding(.horizontal, 14)
                    .background(Color.red.opacity(0.88))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 28)
            }
            Button(action: action) {
                Text(nextLabel)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(ColorTheme.find(selectedThemeID).primary)
                    .frame(maxWidth: .infinity).padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal, 24)
            .opacity(canAdvance ? 1 : 0.48)
            .disabled(!canAdvance)
            if step.rawValue > 0 {
                Button("← Back") { back() }
                    .foregroundColor(.white.opacity(0.92)).font(.system(size: 15, weight: .semibold))
            }
        }
        .padding(.bottom, 44)
    }

    // ── Wizard shared components ───────────────────────────────────────────
    private func wizardHeader(_ title: String, _ sub: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title).font(.system(size: 26, weight: .bold)).foregroundColor(.white)
                .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 1)
            Text(sub).font(.system(size: 15)).foregroundColor(.white.opacity(0.95))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 24)
    }

    @ViewBuilder
    private func card<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 0) { content() }
            .padding(18).background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: .black.opacity(0.20), radius: 10, x: 0, y: 5)
            // Cards are always white — force light-mode text inside them so
            // labels stay readable even when the device is in Dark Mode.
            .environment(\.colorScheme, .light)
            .padding(.horizontal, 24)
    }

    private func fieldLabel(_ t: String) -> some View {
        Text(t).font(.system(size: 12, weight: .semibold)).foregroundColor(.secondary)
    }

    private func wizardField(_ title: String, placeholder: String, text: Binding<String>, secure: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldLabel(title)
            Group {
                if secure { SecureField(placeholder, text: text).textInputAutocapitalization(.never).autocorrectionDisabled() }
                else      { TextField(placeholder, text: text).autocorrectionDisabled() }
            }
            .foregroundColor(.black)
            .padding(10).background(Color(.systemGray6)).clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    // ─────────────────────────────────────────────────────────────────────
    // STEP 0 — Intro
    // ─────────────────────────────────────────────────────────────────────
    private var introStep: some View {
        VStack(spacing: 0) {
            Spacer()
            Image(systemName: "clock.badge.checkmark.fill")
                .font(.system(size: 68)).foregroundColor(.white).padding(.bottom, 26)
            Text("Hanger Time").font(.system(size: 36, weight: .bold)).foregroundColor(.white)
            Text("Built for any team that manages shifts,\nstaffing, or overtime.")
                .font(.system(size: 15)).foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center).padding(.top, 10).padding(.horizontal, 32)
            Spacer()
            VStack(alignment: .leading, spacing: 14) {
                introRow("building.2.fill",        "Your company name & logo")
                introRow("person.3.fill",          "Custom role names for your team")
                introRow("textformat",             "Rename every label to match your industry")
                introRow("rectangle.3.group.fill", "Your departments or work areas")
                introRow("person.crop.circle.badge.checkmark", "Choose what info members share")
                introRow("paintpalette.fill",      "Pick your brand colors")
                introRow("key.fill",               "Auto-generated access codes")
                introRow("lock.shield.fill",       "Private admin code")
            }
            .padding(20).background(Color.white.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 20)).padding(.horizontal, 24)
            Spacer()
            Button { advance() } label: {
                Text("Get Started →")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(ColorTheme.find(selectedThemeID).primary)
                    .frame(maxWidth: .infinity).padding()
                    .background(Color.white).clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal, 24).padding(.bottom, 48)
        }
    }
    private func introRow(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 16)).foregroundColor(.white).frame(width: 24)
            Text(text).font(.system(size: 14, weight: .medium)).foregroundColor(.white.opacity(0.95))
        }
    }

    // ─────────────────────────────────────────────────────────────────────
    // STEP 1 — Company Name + Logo
    // ─────────────────────────────────────────────────────────────────────
    private var companyStep: some View {
        ScrollView {
            VStack(spacing: 20) {
                wizardHeader("Your Company", "Enter your company or organization name and upload a logo to display on the home screen.")
                card {
                    wizardField("COMPANY / ORGANIZATION NAME", placeholder: "e.g. Metro Health, Acme Co.", text: $companyName)
                }
                card {
                    VStack(alignment: .leading, spacing: 12) {
                        fieldLabel("LOGO  (OPTIONAL)")
                        Text("Shown on the home screen — not the app icon.")
                            .font(.system(size: 12)).foregroundColor(.secondary)
                        HStack(spacing: 14) {
                            if let d = logoData, let img = UIImage(data: d) {
                                Image(uiImage: img).resizable().scaledToFit()
                                    .frame(width: 74, height: 74)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                VStack(alignment: .leading, spacing: 6) {
                                    PhotosPicker(selection: $logoItem, matching: .images) {
                                        Text("Change").foregroundColor(.blue).font(.system(size: 14, weight: .semibold))
                                    }
                                    Button("Remove") { logoData = nil }
                                        .foregroundColor(.red).font(.system(size: 14))
                                }
                            } else {
                                RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray5))
                                    .frame(width: 74, height: 74)
                                    .overlay(Image(systemName: "photo").foregroundColor(.secondary))
                                PhotosPicker(selection: $logoItem, matching: .images) {
                                    Text("Upload Logo").foregroundColor(.blue).font(.system(size: 15, weight: .semibold))
                                }
                            }
                        }
                        .onChange(of: logoItem) { _, item in
                            Task {
                                if let raw = try? await item?.loadTransferable(type: Data.self),
                                   let img = UIImage(data: raw),
                                   let jpeg = img.jpegData(compressionQuality: 0.75) { logoData = jpeg }
                            }
                        }
                    }
                }
                card {
                    wizardField("APP TAGLINE  (shown under company name)", placeholder: "e.g. Workforce Shift Manager", text: $appTagline)
                }
                navRow(canAdvance: !companyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                    if companyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        errorMessage = "Please enter your company name."
                    } else { advance() }
                }
            }
            .padding(.top, 10).padding(.bottom, 20)
        }
    }

    // ─────────────────────────────────────────────────────────────────────
    // STEP 2 — Role Names
    // ─────────────────────────────────────────────────────────────────────
    private var roleNamesStep: some View {
        ScrollView {
            VStack(spacing: 20) {
                wizardHeader("Role Names", "Rename each role to match your organization. These names appear throughout the app.")
                card {
                    VStack(spacing: 14) {
                        roleNameRow("ADMIN (full control — manages settings, all areas)", name: $adminName, icon: "shield.fill", description: "Full access to everything including settings.")
                        Divider()
                        roleNameRow("SUPERVISOR (posts & manages their area)", name: $supervisorName, icon: "person.badge.key.fill", description: "Can activate \(overtimeTerm.lowercased()), set headcount, and manage their area's list.")
                        Divider()
                        roleNameRow("LEAD (claims + sees full team list)", name: $leadName, icon: "person.2.fill", description: "Can claim slots and see who else is confirmed.")
                        Divider()
                        roleNameRow("WORKER (claims their own slot only)", name: $workerName, icon: "person.fill", description: "Can claim and see their own status only.")
                    }
                }
                navRow(canAdvance: !adminName.isEmpty && !supervisorName.isEmpty && !leadName.isEmpty && !workerName.isEmpty) {
                    advance()
                }
            }
            .padding(.top, 10).padding(.bottom, 20)
        }
    }
    private func roleNameRow(_ label: String, name: Binding<String>, icon: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel(label)
            HStack(spacing: 10) {
                Image(systemName: icon).foregroundColor(ColorTheme.find(selectedThemeID).accent).frame(width: 22)
                TextField("Role name", text: name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(10).background(Color(.systemGray6)).clipShape(RoundedRectangle(cornerRadius: 10))
            }
            Text(description).font(.system(size: 12)).foregroundColor(.secondary)
        }
    }

    // ─────────────────────────────────────────────────────────────────────
    // STEP 3 — Terminology
    // ─────────────────────────────────────────────────────────────────────
    private var terminologyStep: some View {
        ScrollView {
            VStack(spacing: 20) {
                wizardHeader("Your Terminology", "Rename the core concepts to match your industry. A hospital might say 'On-Call' instead of '\(overtimeTerm)'.")
                card {
                    VStack(spacing: 12) {
                        termRow("What do you call extra shift requests?",   examples: "Overtime, On-Call, Coverage, Extra Shift", text: $overtimeTerm)
                        Divider()
                        termRow("What is an open position called?",         examples: "Slot, Opening, Spot, Position", text: $slotTerm)
                        Divider()
                        termRow("What is the backup list called?",          examples: "Waitlist, Standby, Queue, Reserve", text: $waitlistTerm)
                        Divider()
                        termRow("What do members do to sign up?",           examples: "Claim, Sign Up, Volunteer, Accept", text: $claimTerm)
                        Divider()
                        termRow("What are your work areas called?",         examples: "Department, Section, Unit, Zone, Ward", text: $deptTerm)
                        Divider()
                        termRow("What is a work shift called?",             examples: "Shift, Tour, Rotation, Block", text: $shiftTerm)
                        Divider()
                        termRow("What is a job title / position called?",   examples: "Position, Title, Role, Grade", text: $positionTerm)
                    }
                }
                navRow(canAdvance: !overtimeTerm.isEmpty && !slotTerm.isEmpty && !waitlistTerm.isEmpty) {
                    if overtimeTerm.isEmpty || slotTerm.isEmpty || waitlistTerm.isEmpty {
                        errorMessage = "Please fill in the required terms."
                    } else { advance() }
                }
            }
            .padding(.top, 10).padding(.bottom, 20)
        }
    }
    private func termRow(_ question: String, examples: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(question).font(.system(size: 14, weight: .semibold)).foregroundColor(.primary)
            Text("e.g. \(examples)").font(.system(size: 11)).foregroundColor(.secondary)
            TextField("Enter term", text: text)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.black)
                .padding(10).background(Color(.systemGray6)).clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    // ─────────────────────────────────────────────────────────────────────
    // STEP 4 — Departments
    // ─────────────────────────────────────────────────────────────────────
    private var departmentsStep: some View {
        ScrollView {
            VStack(spacing: 20) {
                wizardHeader("Your \(deptTerm)s", "Add the work areas or sections your team uses. You can always add more later.")
                card {
                    VStack(spacing: 0) {
                        if departments.isEmpty {
                            Text("No \(deptTerm.lowercased())s yet — add one below.")
                                .font(.system(size: 14)).foregroundColor(.secondary)
                                .padding(.vertical, 18).frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            ForEach(departments) { dept in
                                HStack(spacing: 12) {
                                    Image(systemName: dept.iconName)
                                        .foregroundColor(ColorTheme.find(selectedThemeID).accent).frame(width: 22)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(dept.name).font(.system(size: 15, weight: .bold))
                                        if !dept.subtitle.isEmpty {
                                            Text(dept.subtitle).font(.system(size: 12)).foregroundColor(.secondary)
                                        }
                                    }
                                    Spacer()
                                    Button { editingDept = dept; showDeptEditor = true } label: {
                                        Image(systemName: "pencil").foregroundColor(.blue)
                                    }
                                    Button {
                                        departments.removeAll { $0.id == dept.id }
                                        supervisorCodes.removeValue(forKey: dept.id)
                                        teamCodes.removeValue(forKey: dept.id)
                                    } label: {
                                        Image(systemName: "trash").foregroundColor(.red.opacity(0.7))
                                    }
                                }
                                .padding(.vertical, 10)
                                if dept.id != departments.last?.id { Divider() }
                            }
                        }
                        Divider().padding(.top, 6)
                        Button {
                            if !PremiumManager.shared.isPremium && departments.count >= kFreeDepartmentLimit {
                                errorMessage = "FREE_LIMIT_DEPARTMENTS"
                            } else {
                                editingDept = nil; showDeptEditor = true
                            }
                        } label: {
                            Label("Add \(deptTerm)", systemImage: "plus.circle.fill")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(ColorTheme.find(selectedThemeID).accent)
                                .frame(maxWidth: .infinity).padding(.top, 12)
                        }
                    }
                }
                if errorMessage == "FREE_LIMIT_DEPARTMENTS" {
                    PremiumNudgeCard(message: "Free accounts include 1 \(deptTerm.lowercased()). Upgrade for unlimited.")
                        .padding(.horizontal, 24)
                }
                navRow(canAdvance: !departments.isEmpty) {
                    if departments.isEmpty { errorMessage = "Add at least one \(deptTerm.lowercased())." }
                    else { errorMessage = ""; advance() }
                }
            }
            .padding(.top, 10).padding(.bottom, 20)
        }
    }

    // ─────────────────────────────────────────────────────────────────────
    // STEP 5 — Member Fields
    // ─────────────────────────────────────────────────────────────────────
    private var memberFieldsStep: some View {
        ScrollView {
            VStack(spacing: 20) {
                wizardHeader("Member Profile Fields", "Choose what information team members provide when signing up and what others can see.")

                card {
                    VStack(alignment: .leading, spacing: 0) {
                        fieldSectionHeader("FREE FIELDS")
                        fieldToggleRow(label: "Phone Number", icon: "phone.fill", on: $showPhone, required: $phoneRequired)
                        Divider().padding(.leading, 36)
                        fieldToggleRow(label: "Employee / Badge ID", icon: "creditcard.fill", on: $showEmpID, required: $empIDRequired)
                    }
                }

                card {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            fieldSectionHeader("PREMIUM FIELDS")
                            Spacer()
                            premiumBadge
                        }
                        PremiumManager.shared.isPremium ? AnyView(EmptyView()) : AnyView(
                            Text("Upgrade to collect shift, position, and department profile info.")
                                .font(.system(size: 12)).foregroundColor(.secondary).padding(.bottom, 10)
                        )
                        fieldToggleRow(label: "\(shiftTerm) (Day / Night / etc.)", icon: "moon.fill",
                                       on: $showShift, required: .constant(false),
                                       locked: !PremiumManager.shared.isPremium)
                        Divider().padding(.leading, 36)
                        fieldToggleRow(label: "\(positionTerm) / Job Title", icon: "briefcase.fill",
                                       on: $showPosition, required: .constant(false),
                                       locked: !PremiumManager.shared.isPremium)
                    }
                }

                card {
                    VStack(alignment: .leading, spacing: 14) {
                        fieldSectionHeader("VISIBILITY PERMISSIONS")
                        Toggle(isOn: $workerSeesNames) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(workerName)s can see confirmed team names")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("If off, workers only see the count, not the names.")
                                    .font(.system(size: 12)).foregroundColor(.secondary)
                            }
                        }
                        .tint(ColorTheme.find(selectedThemeID).accent)
                        Divider()
                        Toggle(isOn: $leadSeesPhone) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(leadName)s can see phone numbers")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("If off, only \(supervisorName.lowercased())s and \(adminName.lowercased())s see contact info.")
                                    .font(.system(size: 12)).foregroundColor(.secondary)
                            }
                        }
                        .tint(ColorTheme.find(selectedThemeID).accent)
                    }
                }
                navRow(canAdvance: true) { advance() }
            }
            .padding(.top, 10).padding(.bottom, 20)
        }
    }
    private func fieldSectionHeader(_ t: String) -> some View {
        Text(t).font(.system(size: 11, weight: .bold)).foregroundColor(.secondary)
            .padding(.bottom, 10)
    }
    @ViewBuilder
    private func fieldToggleRow(label: String, icon: String, on: Binding<Bool>, required: Binding<Bool>, locked: Bool = false) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundColor(locked ? .gray : ColorTheme.find(selectedThemeID).accent).frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.system(size: 14, weight: .semibold)).foregroundColor(locked ? .secondary : .primary)
                if on.wrappedValue && !locked {
                    Toggle("Required", isOn: required)
                        .font(.system(size: 12)).foregroundColor(.secondary)
                        .tint(ColorTheme.find(selectedThemeID).accent)
                }
            }
            Spacer()
            if locked {
                Image(systemName: "lock.fill").foregroundColor(.secondary).font(.system(size: 13))
            } else {
                Toggle("", isOn: on).tint(ColorTheme.find(selectedThemeID).accent).labelsHidden()
            }
        }
        .padding(.vertical, 10)
    }
    private var premiumBadge: some View {
        Text("PREMIUM").font(.system(size: 9, weight: .bold)).foregroundColor(.white)
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(Color.orange).clipShape(RoundedRectangle(cornerRadius: 5))
    }

    // ─────────────────────────────────────────────────────────────────────
    // STEP 6 — Color Theme
    // ─────────────────────────────────────────────────────────────────────
    private var colorThemeStep: some View {
        ScrollView {
            VStack(spacing: 20) {
                wizardHeader("Brand Colors", "Pick a theme that matches your company. Free accounts get 3 themes. Upgrade for all 15.")
                let cols = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
                card {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("FREE THEMES").font(.system(size: 11, weight: .bold)).foregroundColor(.secondary)
                        LazyVGrid(columns: cols, spacing: 12) {
                            ForEach(ColorTheme.all.filter { !$0.isPremium }) { t in themeCell(t) }
                        }
                        Divider()
                        HStack { Text("PREMIUM THEMES").font(.system(size: 11, weight: .bold)).foregroundColor(.secondary); Spacer(); premiumBadge }
                        LazyVGrid(columns: cols, spacing: 12) {
                            ForEach(ColorTheme.all.filter { $0.isPremium }) { t in themeCell(t) }
                        }
                    }
                }
                navRow(canAdvance: true) { advance() }
            }
            .padding(.top, 10).padding(.bottom, 20)
        }
    }
    private func themeCell(_ t: ColorTheme) -> some View {
        let canUse = PremiumManager.shared.canUseTheme(t)
        let isSelected = selectedThemeID == t.id
        return Button {
            if canUse { selectedThemeID = t.id }
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    LinearGradient(colors: [t.primary, t.accent],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                        .frame(height: 52).clipShape(RoundedRectangle(cornerRadius: 10))
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white).font(.system(size: 20))
                    }
                    if !canUse {
                        RoundedRectangle(cornerRadius: 10).fill(.black.opacity(0.35))
                        Image(systemName: "lock.fill").foregroundColor(.white.opacity(0.8))
                    }
                }
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(isSelected ? ColorTheme.find(selectedThemeID).accent : Color.clear, lineWidth: 2.5))
                Text(t.name).font(.system(size: 9, weight: .semibold))
                    .foregroundColor(canUse ? .primary : .secondary).multilineTextAlignment(.center).lineLimit(2)
            }
        }
        .disabled(!canUse)
    }

    // ─────────────────────────────────────────────────────────────────────
    // STEP 7 — Access Codes
    // ─────────────────────────────────────────────────────────────────────
    private var accessCodesStep: some View {
        ScrollView {
            VStack(spacing: 20) {
                wizardHeader("Access Codes", "Each \(deptTerm.lowercased()) gets two codes — one for \(supervisorName.lowercased())s, one for \(workerName.lowercased())s. Edit or regenerate anytime.")
                ForEach(departments) { dept in
                    card {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack(spacing: 8) {
                                Image(systemName: dept.iconName).foregroundColor(ColorTheme.find(selectedThemeID).accent)
                                Text(dept.name).font(.system(size: 16, weight: .bold))
                            }
                            codeRow("\(supervisorName.uppercased()) CODE",
                                    code: Binding(get: { supervisorCodes[dept.id] ?? "" }, set: { supervisorCodes[dept.id] = $0 }),
                                    regen: { supervisorCodes[dept.id] = CustomDepartment.generateCode() })
                            codeRow("\(workerName.uppercased()) CODE",
                                    code: Binding(get: { teamCodes[dept.id] ?? "" }, set: { teamCodes[dept.id] = $0 }),
                                    regen: { teamCodes[dept.id] = CustomDepartment.generateCode() })
                        }
                    }
                }
                card {
                    HStack(spacing: 10) {
                        Image(systemName: "info.circle.fill").foregroundColor(ColorTheme.find(selectedThemeID).accent)
                        Text("Save these before continuing. Share \(supervisorName.lowercased()) codes to your supervisors and \(workerName.lowercased()) codes to your team.")
                            .font(.system(size: 12)).foregroundColor(.secondary)
                    }
                }
                navRow(canAdvance: codesValid) {
                    if !codesValid { errorMessage = "All codes must be at least 4 characters." }
                    else { advance() }
                }
            }
            .padding(.top, 10).padding(.bottom, 20)
        }
    }
    private var codesValid: Bool {
        departments.allSatisfy {
            (supervisorCodes[$0.id] ?? "").count >= 4 &&
            (teamCodes[$0.id] ?? "").count >= 4
        }
    }
    private func codeRow(_ label: String, code: Binding<String>, regen: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label).font(.system(size: 10, weight: .bold)).foregroundColor(.secondary)
            HStack(spacing: 7) {
                TextField("Code", text: code)
                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
                    .foregroundColor(.black)
                    .textInputAutocapitalization(.characters).autocorrectionDisabled()
                    .padding(9).background(Color(.systemGray6)).clipShape(RoundedRectangle(cornerRadius: 9))
                Button { UIPasteboard.general.string = code.wrappedValue } label: {
                    Image(systemName: "doc.on.doc").foregroundColor(ColorTheme.find(selectedThemeID).accent)
                        .padding(9).background(Color(.systemGray6)).clipShape(RoundedRectangle(cornerRadius: 9))
                }
                Button(action: regen) {
                    Image(systemName: "arrow.clockwise").foregroundColor(ColorTheme.find(selectedThemeID).accent)
                        .padding(9).background(Color(.systemGray6)).clipShape(RoundedRectangle(cornerRadius: 9))
                }
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────
    // STEP 8 — Admin Code
    // ─────────────────────────────────────────────────────────────────────
    private var adminCodeStep: some View {
        ScrollView {
            VStack(spacing: 20) {
                wizardHeader("Admin Code", "Set a private code to protect your settings. You'll need it to change anything in the app later.")
                card {
                    VStack(spacing: 14) {
                        wizardField("\(adminName.uppercased()) CODE  (min 4 characters)", placeholder: "Choose a code", text: $adminCode, secure: true)
                        wizardField("CONFIRM CODE", placeholder: "Re-enter your code", text: $adminCodeConfirm, secure: true)
                        if !adminCode.isEmpty && !adminCodeConfirm.isEmpty && adminCode != adminCodeConfirm {
                            Text("Codes don't match.").font(.system(size: 13, weight: .semibold)).foregroundColor(.red)
                        }
                    }
                }
                navRow(canAdvance: adminCode.count >= 4 && adminCode == adminCodeConfirm, nextLabel: "Complete Setup →") {
                    if adminCode.count < 4 { errorMessage = "Code must be at least 4 characters." }
                    else if adminCode != adminCodeConfirm { errorMessage = "The codes don't match." }
                    else { advance() }
                }
            }
            .padding(.top, 10).padding(.bottom, 20)
        }
    }

    // ─────────────────────────────────────────────────────────────────────
    // STEP 9 — Complete
    // ─────────────────────────────────────────────────────────────────────
    private var completeStep: some View {
        VStack(spacing: 0) {
            Spacer()
            Image(systemName: "checkmark.seal.fill").font(.system(size: 72)).foregroundColor(.white).padding(.bottom, 22)
            Text("You're All Set!").font(.system(size: 32, weight: .bold)).foregroundColor(.white)
            Text("Everything is configured and ready.").font(.system(size: 15)).foregroundColor(.white.opacity(0.9)).padding(.top, 6)
            VStack(alignment: .leading, spacing: 12) {
                summaryRow("building.2.fill",        companyName)
                summaryRow("person.3.fill",          "Roles: \(adminName), \(supervisorName), \(leadName), \(workerName)")
                summaryRow("textformat",             "\(overtimeTerm) · \(slotTerm) · \(waitlistTerm)")
                summaryRow("rectangle.3.group.fill", "\(departments.count) \(deptTerm.lowercased())\(departments.count == 1 ? "" : "s"): \(departments.map { $0.name }.joined(separator: ", "))")
                summaryRow("paintpalette.fill",      ColorTheme.find(selectedThemeID).name)
                summaryRow("key.fill",               "Access codes ready to share")
            }
            .padding(20).background(Color.white.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 20)).padding(.horizontal, 24).padding(.top, 26)
            Spacer()
            Button {
                var cfg = CompanyConfig()
                cfg.companyName = companyName.trimmingCharacters(in: .whitespacesAndNewlines)
                cfg.departments = departments
                cfg.supervisorCodes = supervisorCodes
                cfg.teamMemberCodes = teamCodes
                cfg.adminCode = adminCode
                cfg.selectedThemeID = selectedThemeID
                cfg.isSetupComplete = true
                cfg.labels = CustomLabels(
                    adminName: adminName, supervisorName: supervisorName,
                    leadName: leadName, workerName: workerName,
                    overtimeTerm: overtimeTerm, slotTerm: slotTerm,
                    waitlistTerm: waitlistTerm, claimTerm: claimTerm,
                    departmentTerm: deptTerm, shiftTerm: shiftTerm,
                    positionTerm: positionTerm, employeeTerm: "Employee ID",
                    leadershipLabel: "\(supervisorName) Access",
                    teamMemberLabel: workerName,
                    dashboardTitle: "Dashboard",
                    postRequestLabel: "Post Request",
                    claimSlotLabel: "\(claimTerm) \(slotTerm)",
                    joinWaitlistLabel: "Join \(waitlistTerm)",
                    confirmedLabel: "Confirmed",
                    activeLabel: "Active", notActiveLabel: "Not Active",
                    remainingOpenLabel: "Remaining Open",
                    filledLabel: "Filled", requestedLabel: "Requested",
                    skillsNotesLabel: "\(positionTerm) / Notes",
                    staffingReqLabel: "Staffing Requirement",
                    howManyNeededLabel: "How many people are needed?",
                    removeLabel: "Remove Me", signOutLabel: "Sign Out",
                    notificationsLabel: "Notifications",
                    workAreasLabel: "\(deptTerm)s",
                    appTagline: appTagline,
                    selectAccessLabel: "Select your access path"
                )
                cfg.fieldConfig = MemberFieldConfig(
                    showPhone: showPhone, phoneRequired: phoneRequired,
                    showEmployeeID: showEmpID, employeeIDRequired: empIDRequired,
                    showShift: showShift && PremiumManager.shared.isPremium,
                    shiftRequired: false,
                    showPosition: showPosition && PremiumManager.shared.isPremium,
                    positionRequired: false,
                    showDeptOnProfile: false,
                    leadCanSeePhone: leadSeesPhone,
                    workerCanSeeOthersNames: workerSeesNames
                )
                appStore.completeSetup(config: cfg, logoData: logoData)
            } label: {
                Text("Launch App →")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(ColorTheme.find(selectedThemeID).primary)
                    .frame(maxWidth: .infinity).padding()
                    .background(Color.white).clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal, 24).padding(.bottom, 48)
        }
    }
    private func summaryRow(_ icon: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon).foregroundColor(.white).frame(width: 20)
            Text(text).font(.system(size: 13, weight: .medium)).foregroundColor(.white.opacity(0.95))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - Welcome Screen
// ═══════════════════════════════════════════════════════════════════════════

struct WelcomeView: View {
    @EnvironmentObject var appStore: ShiftStore
    @State private var showAdminGate = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(colors: [appStore.theme.primary, appStore.theme.accent],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                    .overlay(LinearGradient(colors: [.black.opacity(0.5), .black.opacity(0.25), .black.opacity(0.65)],
                                           startPoint: .top, endPoint: .bottom))
                    .ignoresSafeArea()

                VStack {
                    HStack {
                        Button { showAdminGate = true } label: {
                            Image(systemName: "gearshape").font(.system(size: 19)).foregroundColor(.white.opacity(0.8)).padding(16)
                        }
                        Spacer()
                    }
                    .padding(.top, 44)

                    Spacer()

                    VStack(spacing: 14) {
                        if let data = appStore.logoImageData, let img = UIImage(data: data) {
                            Image(uiImage: img).resizable().scaledToFit().frame(height: 86)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        Text(appStore.config.companyName)
                            .font(.system(size: 30, weight: .bold)).foregroundColor(.white).multilineTextAlignment(.center)
                        Text(appStore.labels.appTagline)
                            .font(.system(size: 17, weight: .semibold)).foregroundColor(.white.opacity(0.92))
                        Text(appStore.labels.selectAccessLabel)
                            .font(.system(size: 14)).foregroundColor(.white.opacity(0.85))
                    }
                    .padding(.horizontal, 24)

                    Spacer()

                    VStack(spacing: 14) {
                        NavigationLink { LeadershipAccessView() } label: {
                            WelcomeCard(title: appStore.labels.leadershipLabel,
                                        subtitle: "\(appStore.labels.supervisorName) and \(appStore.labels.adminName) tools, staffing control, and visibility")
                        }
                        .buttonStyle(.plain)

                        NavigationLink { MemberAuthView() } label: {
                            WelcomeCard(title: appStore.labels.teamMemberLabel,
                                        subtitle: "Secure login, \(appStore.labels.overtimeTerm.lowercased()) visibility, \(appStore.labels.claimTerm.lowercased()) status, and \(appStore.labels.waitlistTerm.lowercased())")
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: 500).padding(.horizontal, 20)

                    Spacer(minLength: 40)
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showAdminGate) {
            AdminGateView().environmentObject(appStore)
        }
    }
}

struct WelcomeCard: View {
    let title: String; let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.system(size: 20, weight: .bold)).foregroundColor(.white)
            Text(subtitle).font(.system(size: 13)).foregroundColor(.white.opacity(0.92))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(18)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.16))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.3), lineWidth: 1)))
        .shadow(radius: 7)
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - Admin Gate
// ═══════════════════════════════════════════════════════════════════════════

struct AdminGateView: View {
    @EnvironmentObject var appStore: ShiftStore
    @Environment(\.dismiss) private var dismiss
    @State private var code = ""
    @State private var showError = false
    @State private var goToSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [appStore.theme.primary, appStore.theme.accent],
                               startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
                LinearGradient(colors: [.black.opacity(0.25), .black.opacity(0.10), .black.opacity(0.30)],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                VStack(spacing: 24) {
                    Spacer(minLength: 40)
                    Image(systemName: "gearshape.2.fill").font(.system(size: 48)).foregroundColor(.white)
                    Text("\(appStore.labels.adminName) Settings").font(.system(size: 28, weight: .bold)).foregroundColor(.white)
                    Text("Enter your \(appStore.labels.adminName.lowercased()) code to manage company settings.")
                        .font(.system(size: 14)).foregroundColor(.white.opacity(0.92))
                        .multilineTextAlignment(.center).padding(.horizontal, 32)
                    SecureField("\(appStore.labels.adminName) Code", text: $code)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                        .foregroundColor(.black)
                        .padding().background(Color.white).clipShape(RoundedRectangle(cornerRadius: 14))
                        .environment(\.colorScheme, .light)
                        .padding(.horizontal, 24)
                    Button {
                        if appStore.verifyAdminCode(code) { showError = false; goToSettings = true }
                        else { showError = true }
                    } label: {
                        Text("Enter Settings")
                            .font(.system(size: 17, weight: .bold)).foregroundColor(appStore.theme.primary)
                            .frame(maxWidth: .infinity).padding().background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal, 24)
                    if showError {
                        Text("Incorrect code.")
                            .font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                            .padding(.vertical, 8).padding(.horizontal, 16)
                            .background(Color.red.opacity(0.88))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.foregroundColor(.white) } }
            .navigationDestination(isPresented: $goToSettings) { AdminSettingsView().environmentObject(appStore) }
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - Admin Settings
// ═══════════════════════════════════════════════════════════════════════════

struct AdminSettingsView: View {
    @EnvironmentObject var appStore: ShiftStore
    @State private var companyName = ""
    @State private var logoData: Data? = nil
    @State private var logoItem: PhotosPickerItem? = nil
    @State private var showDeptEditor = false
    @State private var editingDept: CustomDepartment? = nil
    @State private var deptError = ""
    @State private var showLabelEditor = false
    @State private var showFieldEditor = false
    @State private var showThemePicker = false
    @State private var showAdminCodeChange = false
    @State private var newCode = ""
    @State private var newCodeConfirm = ""
    @State private var codeError = ""
    @State private var showResetConfirm = false
    @State private var showPremium = false

    var body: some View {
        Form {
            // ── Company ──
            Section("Company Info") {
                HStack {
                    Text("Name")
                    Spacer()
                    TextField("Name", text: $companyName)
                        .multilineTextAlignment(.trailing).foregroundColor(.secondary)
                        .onChange(of: companyName) { _, v in appStore.updateCompanyInfo(name: v, logoData: logoData) }
                }
                logoRow
            }
            // ── Plan ──
            Section("Plan") {
                HStack {
                    Image(systemName: PremiumManager.shared.isPremium ? "crown.fill" : "lock.fill")
                        .foregroundColor(PremiumManager.shared.isPremium ? .yellow : .secondary)
                    Text(PremiumManager.shared.isPremium ? "Premium" : "Free")
                    Spacer()
                    if !PremiumManager.shared.isPremium {
                        Button("Upgrade →") { showPremium = true }.foregroundColor(appStore.theme.accent)
                    }
                }
            }
            // ── Departments ──
            Section {
                if !deptError.isEmpty { Text(deptError).foregroundColor(.red).font(.system(size: 13)) }
                ForEach(appStore.config.departments) { dept in
                    deptRow(dept)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) { attemptDelete(dept.id) } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
                Button { editingDept = nil; showDeptEditor = true } label: {
                    Label("Add \(appStore.labels.departmentTerm)", systemImage: "plus.circle.fill")
                        .foregroundColor(appStore.theme.accent)
                }
            } header: {
                Text("\(appStore.labels.departmentTerm)s")
            } footer: {
                Text("\(appStore.labels.departmentTerm)s with active \(appStore.labels.overtimeTerm.lowercased()) or claims cannot be deleted.")
            }
            // ── Access Codes ──
            Section {
                ForEach(appStore.config.departments) { dept in
                    DisclosureGroup(dept.name) {
                        settingsCodeRow("\(appStore.labels.supervisorName) Code",
                                        code: appStore.config.supervisorCodes[dept.id] ?? "",
                                        regen: { appStore.regenerateSupervisorCode(for: dept.id) })
                        settingsCodeRow("\(appStore.labels.workerName) Code",
                                        code: appStore.config.teamMemberCodes[dept.id] ?? "",
                                        regen: { appStore.regenerateTeamCode(for: dept.id) })
                    }
                }
            } header: { Text("Access Codes") }
              footer: { Text("Tap copy to share. Tap ↺ to regenerate — existing users won't be affected.") }

            // ── Customize ──
            Section("Customize") {
                Button("Edit Labels & Terminology") { showLabelEditor = true }.foregroundColor(appStore.theme.accent)
                Button("Edit Member Fields") { showFieldEditor = true }.foregroundColor(appStore.theme.accent)
                Button("Change Color Theme") { showThemePicker = true }.foregroundColor(appStore.theme.accent)
            }
            // ── Admin Code ──
            Section("Admin Code") {
                Button("Change Admin Code") { showAdminCodeChange = true }.foregroundColor(appStore.theme.accent)
            }
            // ── Danger ──
            Section {
                Button("Reset App — Erase All Data", role: .destructive) { showResetConfirm = true }
            } header: { Text("Danger Zone") }
              footer: { Text("Permanently deletes everything. The setup wizard will restart.") }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { companyName = appStore.config.companyName; logoData = appStore.logoImageData }
        .sheet(isPresented: $showDeptEditor) {
            DepartmentEditorSheet(department: editingDept) { appStore.updateDepartment($0); editingDept = nil }
        }
        .sheet(isPresented: $showLabelEditor) { LabelEditorView().environmentObject(appStore) }
        .sheet(isPresented: $showFieldEditor) { FieldEditorView().environmentObject(appStore) }
        .sheet(isPresented: $showThemePicker) { ThemePickerView().environmentObject(appStore) }
        .sheet(isPresented: $showPremium) { PremiumUpgradeView().environmentObject(appStore) }
        .alert("Change Admin Code", isPresented: $showAdminCodeChange) {
            SecureField("New code", text: $newCode)
            SecureField("Confirm", text: $newCodeConfirm)
            Button("Save") {
                if newCode.count < 4 { codeError = "Min 4 characters." }
                else if newCode != newCodeConfirm { codeError = "Codes don't match." }
                else { appStore.updateAdminCode(newCode); newCode = ""; newCodeConfirm = "" }
            }
            Button("Cancel", role: .cancel) {}
        } message: { Text(codeError.isEmpty ? "Set a new admin code." : codeError) }
        .alert("Reset Everything?", isPresented: $showResetConfirm) {
            Button("Reset App", role: .destructive) { appStore.resetApp() }
            Button("Cancel", role: .cancel) {}
        } message: { Text("This permanently erases all data and cannot be undone.") }
    }

    private var logoRow: some View {
        HStack(spacing: 12) {
            if let d = logoData, let img = UIImage(data: d) {
                Image(uiImage: img).resizable().scaledToFit().frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 9))
            } else {
                RoundedRectangle(cornerRadius: 9).fill(Color(.systemGray5)).frame(width: 44, height: 44)
                    .overlay(Image(systemName: "photo").foregroundColor(.secondary))
            }
            VStack(alignment: .leading, spacing: 3) {
                PhotosPicker(selection: $logoItem, matching: .images) {
                    Text("Change Logo").foregroundColor(appStore.theme.accent).font(.system(size: 14))
                }
                .onChange(of: logoItem) { _, item in
                    Task {
                        if let raw = try? await item?.loadTransferable(type: Data.self),
                           let img = UIImage(data: raw), let jpeg = img.jpegData(compressionQuality: 0.75) {
                            logoData = jpeg
                            appStore.updateCompanyInfo(name: companyName, logoData: logoData)
                        }
                    }
                }
                if logoData != nil {
                    Button("Remove") { logoData = nil; appStore.updateCompanyInfo(name: companyName, logoData: nil) }
                        .foregroundColor(.red).font(.system(size: 13))
                }
            }
        }
    }

    private func deptRow(_ dept: CustomDepartment) -> some View {
        HStack(spacing: 10) {
            Image(systemName: dept.iconName).foregroundColor(appStore.theme.accent).frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(dept.name).font(.system(size: 14, weight: .semibold))
                if !dept.subtitle.isEmpty { Text(dept.subtitle).font(.system(size: 12)).foregroundColor(.secondary) }
            }
            Spacer()
            Button { editingDept = dept; showDeptEditor = true } label: {
                Image(systemName: "pencil").foregroundColor(appStore.theme.accent)
            }
        }
    }

    private func settingsCodeRow(_ label: String, code: String, regen: @escaping () -> Void) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.system(size: 11, weight: .semibold)).foregroundColor(.secondary)
                Text(code).font(.system(size: 14, weight: .semibold, design: .monospaced))
            }
            Spacer()
            Button { UIPasteboard.general.string = code } label: {
                Image(systemName: "doc.on.doc").foregroundColor(appStore.theme.accent)
            }.padding(.trailing, 8)
            Button(action: regen) {
                Image(systemName: "arrow.clockwise").foregroundColor(appStore.theme.accent)
            }
        }.padding(.vertical, 4)
    }

    private func attemptDelete(_ id: String) {
        if !appStore.canDeleteDepartment(id) {
            let name = appStore.config.departments.first(where: { $0.id == id })?.name ?? "this area"
            deptError = "'\(name)' has active \(appStore.labels.overtimeTerm.lowercased()) or claims. Clear it first."
        } else {
            deptError = ""
            _ = appStore.deleteDepartment(id)
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────
// Label Editor
// ─────────────────────────────────────────────────────────────────────────
struct LabelEditorView: View {
    @EnvironmentObject var appStore: ShiftStore
    @Environment(\.dismiss) private var dismiss
    @State private var labels: CustomLabels = CustomLabels()

    var body: some View {
        NavigationStack {
            Form {
                Section("Role Names") {
                    labelField("Admin role",      text: $labels.adminName)
                    labelField("Supervisor role", text: $labels.supervisorName)
                    labelField("Lead role",       text: $labels.leadName)
                    labelField("Worker role",     text: $labels.workerName)
                }
                Section("Core Terms") {
                    labelField("Overtime term  (e.g. On-Call)",   text: $labels.overtimeTerm)
                    labelField("Slot term  (e.g. Opening)",       text: $labels.slotTerm)
                    labelField("Waitlist term  (e.g. Standby)",   text: $labels.waitlistTerm)
                    labelField("Claim term  (e.g. Sign Up)",      text: $labels.claimTerm)
                    labelField("Department term  (e.g. Unit)",    text: $labels.departmentTerm)
                    labelField("Shift term  (e.g. Tour)",         text: $labels.shiftTerm)
                    labelField("Position term  (e.g. Title)",     text: $labels.positionTerm)
                }
                Section("App Labels") {
                    labelField("App tagline",            text: $labels.appTagline)
                    labelField("Leadership button",      text: $labels.leadershipLabel)
                    labelField("Team member button",     text: $labels.teamMemberLabel)
                    labelField("Dashboard title",        text: $labels.dashboardTitle)
                    labelField("Work areas heading",     text: $labels.workAreasLabel)
                    labelField("Confirmed label",        text: $labels.confirmedLabel)
                    labelField("Active label",           text: $labels.activeLabel)
                    labelField("Not active label",       text: $labels.notActiveLabel)
                    labelField("Claim slot button",      text: $labels.claimSlotLabel)
                    labelField("Join waitlist button",   text: $labels.joinWaitlistLabel)
                    labelField("Remove me button",       text: $labels.removeLabel)
                    labelField("Notifications label",    text: $labels.notificationsLabel)
                    labelField("Sign out button",        text: $labels.signOutLabel)
                    labelField("Select access label",    text: $labels.selectAccessLabel)
                }
            }
            .navigationTitle("Edit Labels")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { appStore.updateLabels(labels); dismiss() }.fontWeight(.bold)
                }
            }
            .onAppear { labels = appStore.config.labels }
        }
    }
    private func labelField(_ title: String, text: Binding<String>) -> some View {
        HStack {
            Text(title).font(.system(size: 13)).foregroundColor(.secondary)
            Spacer()
            TextField("", text: text).multilineTextAlignment(.trailing).font(.system(size: 14, weight: .semibold))
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────
// Field Editor
// ─────────────────────────────────────────────────────────────────────────
struct FieldEditorView: View {
    @EnvironmentObject var appStore: ShiftStore
    @Environment(\.dismiss) private var dismiss
    @State private var fc: MemberFieldConfig = MemberFieldConfig()

    var body: some View {
        NavigationStack {
            Form {
                Section("Free Fields") {
                    Toggle("Phone Number", isOn: $fc.showPhone).tint(appStore.theme.accent)
                    if fc.showPhone { Toggle("Required", isOn: $fc.phoneRequired).tint(appStore.theme.accent) }
                    Toggle("Employee / Badge ID", isOn: $fc.showEmployeeID).tint(appStore.theme.accent)
                    if fc.showEmployeeID { Toggle("Required", isOn: $fc.employeeIDRequired).tint(appStore.theme.accent) }
                }
                Section {
                    if PremiumManager.shared.isPremium {
                        Toggle("\(appStore.labels.shiftTerm)", isOn: $fc.showShift).tint(appStore.theme.accent)
                        Toggle("\(appStore.labels.positionTerm) / Title", isOn: $fc.showPosition).tint(appStore.theme.accent)
                    } else {
                        HStack { Text("\(appStore.labels.shiftTerm)"); Spacer(); Image(systemName: "lock.fill").foregroundColor(.secondary) }
                        HStack { Text("\(appStore.labels.positionTerm) / Title"); Spacer(); Image(systemName: "lock.fill").foregroundColor(.secondary) }
                    }
                } header: { Text("Premium Fields") }
                  footer: { if !PremiumManager.shared.isPremium { Text("Upgrade to unlock shift, position, and title fields.") } }
                Section("Visibility") {
                    Toggle("\(appStore.labels.workerName)s see confirmed names", isOn: $fc.workerCanSeeOthersNames).tint(appStore.theme.accent)
                    Toggle("\(appStore.labels.leadName)s see phone numbers", isOn: $fc.leadCanSeePhone).tint(appStore.theme.accent)
                }
            }
            .navigationTitle("Member Fields")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { appStore.updateFieldConfig(fc); dismiss() }.fontWeight(.bold)
                }
            }
            .onAppear { fc = appStore.config.fieldConfig }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────
// Theme Picker
// ─────────────────────────────────────────────────────────────────────────
struct ThemePickerView: View {
    @EnvironmentObject var appStore: ShiftStore
    @Environment(\.dismiss) private var dismiss
    @State private var selectedID: String = ""
    @State private var showPremium = false
    private let cols = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Free Themes").font(.system(size: 14, weight: .bold)).foregroundColor(.secondary)
                        LazyVGrid(columns: cols, spacing: 12) {
                            ForEach(ColorTheme.all.filter { !$0.isPremium }) { t in themeCell(t) }
                        }
                    }
                    .padding(18).background(Color(.systemGray6)).clipShape(RoundedRectangle(cornerRadius: 16))

                    VStack(alignment: .leading, spacing: 14) {
                        HStack { Text("Premium Themes").font(.system(size: 14, weight: .bold)).foregroundColor(.secondary); Spacer()
                            if !PremiumManager.shared.isPremium {
                                Button("Unlock →") { showPremium = true }.font(.system(size: 13, weight: .semibold)).foregroundColor(.orange)
                            }
                        }
                        LazyVGrid(columns: cols, spacing: 12) {
                            ForEach(ColorTheme.all.filter { $0.isPremium }) { t in themeCell(t) }
                        }
                    }
                    .padding(18).background(Color(.systemGray6)).clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(20)
            }
            .navigationTitle("Color Theme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") { appStore.updateTheme(selectedID); dismiss() }.fontWeight(.bold)
                }
            }
            .onAppear { selectedID = appStore.config.selectedThemeID }
            .sheet(isPresented: $showPremium) { PremiumUpgradeView().environmentObject(appStore) }
        }
    }
    private func themeCell(_ t: ColorTheme) -> some View {
        let canUse = PremiumManager.shared.canUseTheme(t)
        let isSelected = selectedID == t.id
        return Button { if canUse { selectedID = t.id } } label: {
            VStack(spacing: 6) {
                ZStack {
                    LinearGradient(colors: [t.primary, t.accent], startPoint: .topLeading, endPoint: .bottomTrailing)
                        .frame(height: 52).clipShape(RoundedRectangle(cornerRadius: 10))
                    if isSelected { Image(systemName: "checkmark.circle.fill").foregroundColor(.white).font(.system(size: 20)) }
                    if !canUse { RoundedRectangle(cornerRadius: 10).fill(.black.opacity(0.35)); Image(systemName: "lock.fill").foregroundColor(.white.opacity(0.8)) }
                }
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(isSelected ? t.accent : Color.clear, lineWidth: 2.5))
                Text(t.name).font(.system(size: 9, weight: .semibold)).foregroundColor(canUse ? .primary : .secondary)
                    .multilineTextAlignment(.center).lineLimit(2)
            }
        }.disabled(!canUse)
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - Premium Upgrade View
// ═══════════════════════════════════════════════════════════════════════════

struct PremiumUpgradeView: View {
    @EnvironmentObject var appStore: ShiftStore
    @Environment(\.dismiss) private var dismiss
    @StateObject private var pm = PremiumManager.shared
    @State private var isPurchasing = false
    @State private var message = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    ZStack {
                        LinearGradient(colors: [appStore.theme.primary, appStore.theme.accent],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                        VStack(spacing: 12) {
                            Image(systemName: "crown.fill").font(.system(size: 52)).foregroundColor(.white)
                            Text("Go Premium").font(.system(size: 30, weight: .bold)).foregroundColor(.white)
                            Text("Everything unlocked. No limits.").font(.system(size: 15)).foregroundColor(.white.opacity(0.9))
                        }
                        .padding(.vertical, 36)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal, 20)

                    // Feature list
                    VStack(alignment: .leading, spacing: 14) {
                        featureRow("building.2.fill",        "Unlimited \(appStore.labels.departmentTerm.lowercased())s",         "Free: 1")
                        featureRow("person.3.fill",          "Unlimited team members",          "Free: 10")
                        featureRow("paintpalette.fill",      "15 color themes",                 "Free: 3")
                        featureRow("person.crop.square",     "\(appStore.labels.shiftTerm) & \(appStore.labels.positionTerm) fields", "Locked")
                        featureRow("icloud.fill",            "Real-time cloud sync",            "Local only")
                        featureRow("bell.badge.fill",        "True push notifications",         "Local only")
                    }
                    .padding(20).background(Color(.systemGray6)).clipShape(RoundedRectangle(cornerRadius: 18))
                    .padding(.horizontal, 20)

                    // Purchase buttons
                    VStack(spacing: 14) {
                        if let monthly = pm.monthlyProduct {
                            PurchaseButton(title: "Monthly — \(monthly.displayPrice)/month",
                                           subtitle: "Cancel anytime",
                                           color: appStore.theme.accent) {
                                Task { isPurchasing = true; _ = await pm.purchase(monthly); isPurchasing = false }
                            }
                        } else {
                            PurchaseButton(title: "Monthly — $4.99/month", subtitle: "Cancel anytime", color: appStore.theme.accent) {}
                                .opacity(0.5)
                        }

                        if let lifetime = pm.lifetimeProduct {
                            PurchaseButton(title: "Lifetime — \(lifetime.displayPrice) one-time",
                                           subtitle: "Best value — pay once, use forever",
                                           color: appStore.theme.primary) {
                                Task { isPurchasing = true; _ = await pm.purchase(lifetime); isPurchasing = false }
                            }
                        } else {
                            PurchaseButton(title: "Lifetime — $29.99 one-time", subtitle: "Best value — pay once, use forever",
                                           color: appStore.theme.primary) {}
                                .opacity(0.5)
                        }

                        Button { Task { await pm.restorePurchases() } } label: {
                            Text("Restore Purchases").font(.system(size: 14)).foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 20)

                    if !message.isEmpty {
                        Text(message).font(.system(size: 13, weight: .semibold))
                            .foregroundColor(appStore.theme.accent).multilineTextAlignment(.center)
                    }

                    Text("Payment charged to your Apple ID account. Subscription automatically renews unless cancelled at least 24 hours before the end of the current period.")
                        .font(.system(size: 11)).foregroundColor(.secondary).multilineTextAlignment(.center).padding(.horizontal, 24)
                }
                .padding(.bottom, 40)
            }
            .navigationTitle("Upgrade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
            .overlay { if isPurchasing { ProgressView().scaleEffect(1.5) } }
            .onChange(of: pm.isPremium) { _, val in if val { message = "Premium activated! ✓"; DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { dismiss() } } }
        }
    }
    private func featureRow(_ icon: String, _ feature: String, _ freeLimit: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundColor(appStore.theme.accent).frame(width: 22)
            Text(feature).font(.system(size: 14, weight: .semibold))
            Spacer()
            Text(freeLimit).font(.system(size: 12)).foregroundColor(.secondary)
                .strikethrough(true, color: .secondary)
            Image(systemName: "checkmark.circle.fill").foregroundColor(appStore.theme.accent).font(.system(size: 16))
        }
    }
}

struct PurchaseButton: View {
    let title: String; let subtitle: String; let color: Color; let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Text(title).font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                Text(subtitle).font(.system(size: 12)).foregroundColor(.white.opacity(0.85))
            }
            .frame(maxWidth: .infinity).padding(16)
            .background(color).clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - Leadership Access View
// ═══════════════════════════════════════════════════════════════════════════

struct LeadershipAccessView: View {
    @EnvironmentObject var appStore: ShiftStore
    @State private var selectedDeptID = ""
    @State private var code = ""
    @State private var isAuthenticated = false
    @State private var showError = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [appStore.theme.primary, appStore.theme.accent],
                           startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            LinearGradient(colors: [.black.opacity(0.25), .black.opacity(0.10), .black.opacity(0.30)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 22) {
                Spacer(minLength: 40)
                Image(systemName: "person.badge.key.fill").font(.system(size: 46)).foregroundColor(.white)
                Text(appStore.labels.leadershipLabel).font(.system(size: 26, weight: .bold)).foregroundColor(.white)
                Text("Select your \(appStore.labels.departmentTerm.lowercased()) and enter your code.")
                    .font(.system(size: 14)).foregroundColor(.white.opacity(0.92)).multilineTextAlignment(.center).padding(.horizontal, 28)

                if !appStore.config.departments.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Your \(appStore.labels.departmentTerm)")
                            .font(.system(size: 13, weight: .semibold)).foregroundColor(.white.opacity(0.92)).padding(.leading, 24)
                        Picker("", selection: $selectedDeptID) {
                            ForEach(appStore.config.departments) { d in
                                Text("\(d.name)\(d.subtitle.isEmpty ? "" : " — \(d.subtitle)")").tag(d.id)
                            }
                        }
                        .pickerStyle(.menu).tint(appStore.theme.accent)
                        .padding().frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white).clipShape(RoundedRectangle(cornerRadius: 14))
                        .environment(\.colorScheme, .light)
                        .padding(.horizontal, 24)
                    }
                }

                SecureField("\(appStore.labels.supervisorName) Code", text: $code)
                    .textInputAutocapitalization(.never).autocorrectionDisabled()
                    .foregroundColor(.black)
                    .padding().background(Color.white).clipShape(RoundedRectangle(cornerRadius: 14))
                    .environment(\.colorScheme, .light)
                    .padding(.horizontal, 24)

                Button {
                    let result = appStore.signInSupervisor(departmentID: selectedDeptID, code: code)
                    switch result {
                    case .success: showError = false; isAuthenticated = true
                    case .failure: showError = true
                    }
                } label: {
                    Text("Enter \(appStore.labels.dashboardTitle)")
                        .font(.system(size: 17, weight: .bold)).foregroundColor(appStore.theme.primary)
                        .frame(maxWidth: .infinity).padding().background(Color.white).clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, 24)

                if showError {
                    let name = appStore.config.departments.first(where: { $0.id == selectedDeptID })?.name ?? ""
                    Text("Incorrect code\(name.isEmpty ? "" : " for \(name)").")
                        .font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 8).padding(.horizontal, 16)
                        .background(Color.red.opacity(0.88))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.horizontal, 24)
                }
                Spacer()
            }
        }
        .navigationDestination(isPresented: $isAuthenticated) { LeadershipDashboardView() }
        .onAppear {
            if let current = appStore.currentSupervisorDeptID,
               appStore.config.departments.contains(where: { $0.id == current }) {
                selectedDeptID = current; isAuthenticated = true
            } else { selectedDeptID = appStore.config.departments.first?.id ?? "" }
        }
        .onChange(of: appStore.currentSupervisorDeptID) { _, v in if v == nil { isAuthenticated = false } }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - Leadership Dashboard (Admin + Supervisor)
// ═══════════════════════════════════════════════════════════════════════════

struct LeadershipDashboardView: View {
    @EnvironmentObject var appStore: ShiftStore
    @State private var currentTime = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(appStore.labels.dashboardTitle).font(.system(size: 28, weight: .bold)).foregroundColor(.primary)
                    if let dept = appStore.currentSupervisorDept {
                        Text("Signed in: \(dept.name) \(appStore.labels.supervisorName)").font(.system(size: 13, weight: .semibold)).foregroundColor(appStore.theme.accent)
                    }
                    Text("Manage \(appStore.labels.overtimeTerm.lowercased()) in real time").font(.system(size: 14)).foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Live clock
                VStack(alignment: .leading, spacing: 8) {
                    Label("Live Date & Time", systemImage: "clock.badge.checkmark.fill").font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                    Text(currentTime.displayDateTime).font(.system(size: 21, weight: .semibold)).foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading).padding(18)
                .background(LinearGradient(colors: [appStore.theme.primary, appStore.theme.accent], startPoint: .topLeading, endPoint: .bottomTrailing))
                .clipShape(RoundedRectangle(cornerRadius: 20))

                Text(appStore.labels.workAreasLabel).font(.system(size: 19, weight: .bold)).frame(maxWidth: .infinity, alignment: .leading)

                ForEach(appStore.config.departments) { dept in
                    NavigationLink { DepartmentManageView(department: dept) } label: {
                        DeptSummaryCard(dept: dept, state: appStore.departmentState(for: dept.id),
                                        isOwn: appStore.currentSupervisorDeptID == dept.id)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20).padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(appStore.labels.dashboardTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button(appStore.labels.signOutLabel) { appStore.signOutSupervisor() } } }
        .onReceive(timer) { t in currentTime = t }
    }
}

struct DeptSummaryCard: View {
    @EnvironmentObject var appStore: ShiftStore
    let dept: CustomDepartment; let state: DepartmentOvertimeState; var isOwn: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 13).fill(isOwn ? appStore.theme.accent : appStore.theme.accent.opacity(0.12)).frame(width: 52, height: 52)
                Image(systemName: dept.iconName).font(.system(size: 22, weight: .semibold)).foregroundColor(isOwn ? .white : appStore.theme.accent)
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 7) {
                    Text(dept.name).font(.system(size: 20, weight: .bold))
                    if isOwn {
                        Text("YOURS").font(.system(size: 9, weight: .bold)).foregroundColor(.white)
                            .padding(.horizontal, 5).padding(.vertical, 2).background(appStore.theme.accent).clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
                if !dept.subtitle.isEmpty { Text(dept.subtitle).font(.system(size: 12)).foregroundColor(.secondary) }
                Text(state.overtimeNeeded ? "\(state.remainingOpenSlots) \(appStore.labels.slotTerm.lowercased())(s) open" : appStore.labels.notActiveLabel)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(state.overtimeNeeded ? .red : .secondary)
            }
            Spacer()
            if state.overtimeNeeded {
                Text("\(state.remainingOpenSlots)").font(.system(size: 13, weight: .bold)).foregroundColor(.white)
                    .frame(width: 28, height: 28).background(Circle().fill(.red))
            }
            Image(systemName: "chevron.right").font(.system(size: 14, weight: .bold)).foregroundColor(appStore.theme.accent)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color(.systemBackground))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(isOwn ? appStore.theme.accent : Color(.systemGray4), lineWidth: isOwn ? 2 : 1)))
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - Department Management View (Supervisor / Admin)
// ═══════════════════════════════════════════════════════════════════════════

struct DepartmentManageView: View {
    @EnvironmentObject var appStore: ShiftStore
    let department: CustomDepartment

    var body: some View {
        let state = appStore.departmentState(for: department.id)
        ScrollView {
            VStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(department.name).font(.system(size: 30, weight: .bold))
                    if !department.subtitle.isEmpty { Text(department.subtitle).font(.system(size: 14)).foregroundColor(.secondary) }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Toggle
                infoCard {
                    Toggle(isOn: Binding(get: { state.overtimeNeeded }, set: { appStore.setOvertimeNeeded(for: department.id, needed: $0) })) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("\(appStore.labels.overtimeTerm) Active").font(.system(size: 15, weight: .semibold))
                            Text(state.overtimeNeeded ? appStore.labels.activeLabel : appStore.labels.notActiveLabel)
                                .font(.system(size: 13)).foregroundColor(state.overtimeNeeded ? .green : .secondary)
                        }
                    }
                    .tint(appStore.theme.accent)
                }

                if state.overtimeNeeded {
                    // Headcount
                    infoCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(appStore.labels.staffingReqLabel).font(.system(size: 16, weight: .bold))
                            Text(appStore.labels.howManyNeededLabel).font(.system(size: 13)).foregroundColor(.secondary)
                            Picker("", selection: Binding(get: { state.peopleNeeded }, set: { appStore.setPeopleNeeded(for: department.id, count: $0) })) {
                                ForEach(1...20, id: \.self) { n in Text("\(n)").tag(n) }
                            }
                            .pickerStyle(.menu).padding(10).background(Color(.systemGray6)).clipShape(RoundedRectangle(cornerRadius: 10))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    // Notes
                    infoCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(appStore.labels.skillsNotesLabel).font(.system(size: 16, weight: .bold))
                            TextField("Certifications, requirements, special tasks...",
                                      text: Binding(get: { state.comments }, set: { appStore.setComments(for: department.id, comments: $0) }),
                                      axis: .vertical)
                            .textFieldStyle(.plain).padding(10).frame(minHeight: 90, alignment: .topLeading)
                            .background(Color(.systemGray6)).clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    // Summary
                    summaryCard(state: state)
                    // Confirmed list
                    claimsCard("Confirmed \(appStore.labels.workerName)s", state.confirmedClaims, emptyText: "None yet.", remove: { appStore.removeClaimFromConfirmed(deptID: department.id, claimID: $0) })
                    // Waitlist
                    claimsCard(appStore.labels.waitlistTerm, state.waitlistClaims, emptyText: "Empty.", remove: { appStore.removeClaimFromWaitlist(deptID: department.id, claimID: $0) })
                } else {
                    infoCard {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("No Active Request").font(.system(size: 16, weight: .bold))
                            Text("Toggle \(appStore.labels.overtimeTerm.lowercased()) on when this area needs additional coverage.").font(.system(size: 13)).foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(20).padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(department.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func infoCard<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 0) { content() }
            .padding(16).background(Color(.systemBackground)).clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(.systemGray4), lineWidth: 1))
    }

    private func summaryCard(state: DepartmentOvertimeState) -> some View {
        infoCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Summary").font(.system(size: 16, weight: .bold))
                summaryRow(appStore.labels.requestedLabel, "\(state.peopleNeeded)")
                summaryRow(appStore.labels.filledLabel, "\(state.confirmedClaims.count)")
                summaryRow(appStore.labels.remainingOpenLabel, "\(state.remainingOpenSlots)", .red)
                summaryRow("\(appStore.labels.waitlistTerm) Count", "\(state.waitlistClaims.count)")
                if !state.comments.isEmpty {
                    Text("Notes: \(state.comments)").font(.system(size: 12)).foregroundColor(.secondary).fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func summaryRow(_ label: String, _ value: String, _ color: Color = .primary) -> some View {
        HStack { Text(label).font(.system(size: 13, weight: .semibold)).foregroundColor(.secondary)
            Spacer(); Text(value).font(.system(size: 14, weight: .bold)).foregroundColor(color) }
    }

    private func claimsCard(_ title: String, _ rows: [ClaimRecord], emptyText: String, remove: @escaping (String) -> Void) -> some View {
        infoCard {
            VStack(alignment: .leading, spacing: 10) {
                Text(title).font(.system(size: 16, weight: .bold))
                if rows.isEmpty {
                    Text(emptyText).font(.system(size: 13)).foregroundColor(.secondary)
                } else {
                    ForEach(rows) { row in
                        HStack(alignment: .top, spacing: 10) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(row.displayName).font(.system(size: 14, weight: .bold))
                                Text(row.email).font(.system(size: 12)).foregroundColor(.secondary)
                                if !row.phone.isEmpty { Text(row.phone).font(.system(size: 12)).foregroundColor(.secondary) }
                                Text(row.timestamp.displayDateTime).font(.system(size: 11)).foregroundColor(.secondary)
                            }
                            Spacer()
                            Button(role: .destructive) { remove(row.id) } label: {
                                Image(systemName: "trash").foregroundColor(.red)
                            }
                        }
                        if row.id != rows.last?.id { Divider() }
                    }
                }
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - Member Auth View
// ═══════════════════════════════════════════════════════════════════════════

struct MemberAuthView: View {
    @EnvironmentObject var appStore: ShiftStore
    @State private var isCreateMode = false
    @State private var selectedDeptID = ""
    @State private var code = ""; @State private var firstName = ""; @State private var lastName = ""
    @State private var email = ""; @State private var password = ""; @State private var phone = ""
    @State private var employeeID = ""; @State private var shift = ""; @State private var position = ""
    @State private var signInEmail = ""; @State private var signInPassword = ""
    @State private var message = ""; @State private var showError = false
    @State private var navigateToHome = false; @State private var showFaceIDPrompt = false
    @State private var showPremium = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Picker("", selection: $isCreateMode) {
                    Text("Sign In").tag(false)
                    Text("Create Account").tag(true)
                }
                .pickerStyle(.segmented)

                if isCreateMode { createForm } else { signInForm }

                if showError {
                    Group {
                        if message == "FREE_LIMIT_MEMBERS" {
                            PremiumNudgeCard(message: "Free accounts support up to \(kFreeMemberLimit) members. Upgrade for unlimited.")
                            Button("Upgrade to Premium") { showPremium = true }
                                .font(.system(size: 15, weight: .bold)).foregroundColor(appStore.theme.accent)
                        } else {
                            Text(message).foregroundColor(.red).font(.system(size: 13, weight: .semibold)).multilineTextAlignment(.center)
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(appStore.labels.teamMemberLabel)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToHome) { MemberHomeView() }
        .alert("Enable Face ID?", isPresented: $showFaceIDPrompt) {
            Button("Enable") { enableFaceID() }
            Button("Not Now", role: .cancel) { navigateToHome = true }
        } message: { Text("Use Face ID for faster sign in.") }
        .sheet(isPresented: $showPremium) { PremiumUpgradeView().environmentObject(appStore) }
        .onAppear {
            if selectedDeptID.isEmpty { selectedDeptID = appStore.config.departments.first?.id ?? "" }
            if appStore.currentMemberID != nil { navigateToHome = true }
        }
        .onChange(of: appStore.currentMemberID) { _, v in if v == nil { navigateToHome = false } }
    }

    // ── Create form ────────────────────────────────────────────────────────
    private var createForm: some View {
        VStack(spacing: 14) {
            authDeptPicker
            authSecureField("Access Code for \(appStore.config.departments.first(where: { $0.id == selectedDeptID })?.name ?? appStore.labels.departmentTerm)", text: $code)
            authField("First Name", text: $firstName)
            authField("Last Name",  text: $lastName)
            authField("Email",      text: $email, keyboard: .emailAddress)
            authSecureField("Password", text: $password)
            if appStore.fields.showPhone { authField("Phone Number\(appStore.fields.phoneRequired ? " *" : "")", text: $phone, keyboard: .phonePad) }
            if appStore.fields.showEmployeeID { authField("\(appStore.labels.employeeTerm)\(appStore.fields.employeeIDRequired ? " *" : "")", text: $employeeID) }
            if appStore.fields.showShift && PremiumManager.shared.isPremium { authField(appStore.labels.shiftTerm, text: $shift) }
            if appStore.fields.showPosition && PremiumManager.shared.isPremium { authField(appStore.labels.positionTerm, text: $position) }

            Button {
                let r = appStore.createMember(departmentID: selectedDeptID, accessCode: code,
                    firstName: firstName, lastName: lastName, email: email, password: password,
                    phone: phone, employeeID: employeeID, shift: shift, position: position)
                switch r {
                case .success: showError = false; showFaceIDPrompt = true
                case .failure(let e): showError = true; message = e.message
                }
            } label: { authButton("Create Account") }
        }
    }

    // ── Sign in form ───────────────────────────────────────────────────────
    private var signInForm: some View {
        VStack(spacing: 14) {
            authField("Email", text: $signInEmail, keyboard: .emailAddress)
            authSecureField("Password", text: $signInPassword)
            Button {
                let r = appStore.signIn(email: signInEmail, password: signInPassword)
                switch r {
                case .success(let a): showError = false; if a.faceIDEnabled { navigateToHome = true } else { showFaceIDPrompt = true }
                case .failure(let e): showError = true; message = e.message
                }
            } label: { authButton("Sign In") }
            if appStore.canUseFaceID {
                Button { authenticateWithFaceID() } label: {
                    Label("Use Face ID", systemImage: "faceid")
                        .font(.system(size: 15, weight: .bold)).foregroundColor(appStore.theme.accent)
                        .frame(maxWidth: .infinity).padding().background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(.systemGray4), lineWidth: 1))
                }
            }
        }
    }

    private var authDeptPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Your \(appStore.labels.departmentTerm)").font(.system(size: 13, weight: .semibold)).foregroundColor(.secondary)
            Picker("", selection: $selectedDeptID) {
                ForEach(appStore.config.departments) { d in
                    Text("\(d.name)\(d.subtitle.isEmpty ? "" : " — \(d.subtitle)")").tag(d.id)
                }
            }
            .pickerStyle(.menu).tint(appStore.theme.accent)
            .padding().frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground)).clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(.systemGray4), lineWidth: 1))
        }
    }

    private func authField(_ title: String, text: Binding<String>, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.system(size: 12, weight: .semibold)).foregroundColor(.secondary)
            TextField(title, text: text).keyboardType(keyboard).textInputAutocapitalization(.never).autocorrectionDisabled()
                .padding(12).background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12)).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.systemGray4), lineWidth: 1))
        }
    }
    private func authSecureField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.system(size: 12, weight: .semibold)).foregroundColor(.secondary)
            SecureField(title, text: text).textInputAutocapitalization(.never).autocorrectionDisabled()
                .padding(12).background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12)).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.systemGray4), lineWidth: 1))
        }
    }
    private func authButton(_ t: String) -> some View {
        Text(t).font(.system(size: 17, weight: .bold)).foregroundColor(.white)
            .frame(maxWidth: .infinity).padding().background(appStore.theme.accent).clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func enableFaceID() {
        let ctx = LAContext(); var err: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err) else { navigateToHome = true; return }
        ctx.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Enable Face ID for faster sign in") { ok, _ in
            DispatchQueue.main.async { if ok { appStore.enableFaceID() }; navigateToHome = true }
        }
    }
    private func authenticateWithFaceID() {
        let ctx = LAContext(); var err: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err) else {
            showError = true; message = "Face ID is not available."; return
        }
        ctx.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Sign in with Face ID") { ok, _ in
            DispatchQueue.main.async {
                if ok {
                    switch appStore.signInWithFaceID() {
                    case .success: showError = false; navigateToHome = true
                    case .failure(let e): showError = true; message = e.message
                    }
                } else { showError = true; message = "Face ID cancelled or failed." }
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - Member Home (role-aware)
// ═══════════════════════════════════════════════════════════════════════════

struct MemberHomeView: View {
    @EnvironmentObject var appStore: ShiftStore
    @State private var expanded: Set<String> = []
    @State private var actionMessage = ""
    @State private var showDeleteConfirmation = false
    @State private var showAccountMenu = false

    var role: AppRole { appStore.currentMemberRole }

    var body: some View {
        Group {
            if appStore.currentMemberID == nil { MemberAuthView() }
            else { mainContent }
        }
        .navigationTitle(appStore.labels.teamMemberLabel)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 14) {
                memberHeaderCard
                ForEach(appStore.config.departments) { dept in
                    let state = appStore.departmentState(for: dept.id)
                    deptRow(dept: dept, state: state)
                }
                if !actionMessage.isEmpty {
                    Text(actionMessage).font(.system(size: 13, weight: .semibold)).multilineTextAlignment(.center)
                        .padding().frame(maxWidth: .infinity).background(appStore.theme.accent.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(20).padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(appStore.labels.signOutLabel, systemImage: "rectangle.portrait.and.arrow.right") {
                        appStore.signOutMember()
                        actionMessage = ""
                    }
                    Divider()
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete My Account", systemImage: "person.crop.circle.badge.minus")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 17))
                }
            }
        }
        .alert("Delete Account?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                appStore.deleteCurrentMember()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete your account, remove you from any claimed slots, and erase all your data. This cannot be undone.")
        }
        .onChange(of: appStore.currentMemberID) { _, v in if v == nil { actionMessage = ""; expanded.removeAll() } }
    }

    private var memberHeaderCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Welcome, \(appStore.currentMemberDisplayName)").font(.system(size: 21, weight: .bold))
                    if let member = appStore.currentMember,
                       let dept = appStore.config.departments.first(where: { $0.id == member.departmentID }) {
                        Text("\(dept.name)  ·  \(roleLabel)").font(.system(size: 12, weight: .semibold)).foregroundColor(appStore.theme.accent)
                    }
                    if let member = appStore.currentMember {
                        if appStore.fields.showPosition && !member.position.isEmpty {
                            Text(member.position).font(.system(size: 12)).foregroundColor(.secondary)
                        }
                        if appStore.fields.showShift && !member.shift.isEmpty {
                            Text("\(appStore.labels.shiftTerm): \(member.shift)").font(.system(size: 12)).foregroundColor(.secondary)
                        }
                    }
                }
                Spacer()
                Image(systemName: roleIcon).font(.system(size: 28)).foregroundColor(appStore.theme.accent)
            }
            Toggle(appStore.labels.notificationsLabel, isOn: Binding(
                get: { appStore.currentMemberNotificationsEnabled },
                set: { val in appStore.setNotifications(val); if val { UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in } } }
            )).tint(appStore.theme.accent).font(.system(size: 14, weight: .semibold))
        }
        .padding(16).background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16)).overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(.systemGray4), lineWidth: 1))
    }

    private var roleLabel: String {
        switch role {
        case .admin:      return appStore.labels.adminName
        case .supervisor: return appStore.labels.supervisorName
        case .lead:       return appStore.labels.leadName
        case .worker:     return appStore.labels.workerName
        }
    }
    private var roleIcon: String {
        switch role {
        case .admin:      return "shield.fill"
        case .supervisor: return "person.badge.key.fill"
        case .lead:       return "person.2.fill"
        case .worker:     return "person.fill"
        }
    }

    private func deptRow(dept: CustomDepartment, state: DepartmentOvertimeState) -> some View {
        DisclosureGroup(
            isExpanded: Binding(get: { expanded.contains(dept.id) }, set: { v in if v { expanded.insert(dept.id) } else { expanded.remove(dept.id) } })
        ) {
            VStack(alignment: .leading, spacing: 12) {
                if state.overtimeNeeded {
                    // Info rows (everyone sees)
                    infoRow(appStore.labels.requestedLabel, "\(state.peopleNeeded)")
                    infoRow(appStore.labels.filledLabel,    "\(state.confirmedClaims.count)")
                    infoRow(appStore.labels.remainingOpenLabel, "\(state.remainingOpenSlots)")
                    infoRow("\(appStore.labels.waitlistTerm) Count", "\(state.waitlistClaims.count)")
                    if !state.comments.isEmpty { infoRow("Notes", state.comments) }

                    // Confirmed names (lead sees full list; worker sees names if permission; otherwise just count)
                    if !state.confirmedClaims.isEmpty {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("\(appStore.labels.confirmedLabel) \(appStore.labels.workerName)s").font(.system(size: 13, weight: .bold))
                            if role == .lead || role == .supervisor || role == .admin {
                                ForEach(state.confirmedClaims) { claim in
                                    HStack(spacing: 6) {
                                        Text(claim.displayName).font(.system(size: 12, weight: .semibold))
                                        Text("·").foregroundColor(.secondary)
                                        Text(claim.timestamp.displayTime).font(.system(size: 12)).foregroundColor(.secondary)
                                        if (role == .lead && appStore.fields.leadCanSeePhone) || role == .supervisor || role == .admin {
                                            if !claim.phone.isEmpty {
                                                Spacer(); Text(claim.phone).font(.system(size: 11)).foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                }
                            } else if appStore.fields.workerCanSeeOthersNames {
                                ForEach(state.confirmedClaims) { claim in
                                    Text(claim.displayName).font(.system(size: 12, weight: .semibold))
                                }
                            } else {
                                Text("\(state.confirmedClaims.count) confirmed").font(.system(size: 12)).foregroundColor(.secondary)
                            }
                        }
                    }

                    // Waitlist (lead+ sees names, workers see count only)
                    if !state.waitlistClaims.isEmpty && (role == .lead || role == .supervisor || role == .admin) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(appStore.labels.waitlistTerm).font(.system(size: 13, weight: .bold))
                            ForEach(Array(state.waitlistClaims.enumerated()), id: \.element.id) { idx, claim in
                                Text("#\(idx+1) \(claim.displayName)").font(.system(size: 12)).foregroundColor(.secondary)
                            }
                        }
                    }

                    // Action buttons
                    memberActionArea(dept: dept, state: state)
                } else {
                    Text("No \(appStore.labels.overtimeTerm.lowercased()) posted.").font(.system(size: 13)).foregroundColor(.secondary)
                }
            }
            .padding(.top, 10)
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 11).fill(appStore.theme.accent.opacity(0.12)).frame(width: 44, height: 44)
                    Image(systemName: dept.iconName).foregroundColor(appStore.theme.accent).font(.system(size: 19, weight: .bold))
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(dept.name).font(.system(size: 18, weight: .bold))
                    if !dept.subtitle.isEmpty { Text(dept.subtitle).font(.system(size: 12)).foregroundColor(.secondary) }
                }
                Spacer()
                if state.overtimeNeeded {
                    Text("\(state.remainingOpenSlots)").font(.system(size: 12, weight: .bold)).foregroundColor(.white)
                        .frame(width: 25, height: 25).background(Circle().fill(.red))
                }
            }
        }
        .padding(16).background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16)).overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(.systemGray4), lineWidth: 1))
    }

    private func infoRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(title).font(.system(size: 13, weight: .bold)).foregroundColor(.secondary)
            Spacer(); Text(value).font(.system(size: 13)).foregroundColor(.primary).multilineTextAlignment(.trailing)
        }
    }

    private func memberActionArea(dept: CustomDepartment, state: DepartmentOvertimeState) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            guard let memberID = appStore.currentMemberID else { return AnyView(EmptyView()) }
            if let status = appStore.claimStatus(memberID: memberID, in: dept.id) {
                return AnyView(VStack(alignment: .leading, spacing: 8) {
                    Text(status).font(.system(size: 13, weight: .semibold)).foregroundColor(appStore.theme.accent)
                    Button { actionMessage = appStore.removeMemberFromDept(memberID: memberID, deptID: dept.id).message } label: {
                        Text(appStore.labels.removeLabel).font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding(12).background(.red).clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                })
            } else {
                return AnyView(VStack(alignment: .leading, spacing: 6) {
                    Button {
                        actionMessage = appStore.claimSlot(memberID: memberID, in: dept.id).message
                    } label: {
                        Text(state.remainingOpenSlots > 0 ? appStore.labels.claimSlotLabel : appStore.labels.joinWaitlistLabel)
                            .font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding(12).background(appStore.theme.accent).clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    if let block = appStore.globalClaimBlockMessage(for: dept.id, memberID: memberID) {
                        Text(block).font(.system(size: 12, weight: .semibold)).foregroundColor(.red)
                    }
                })
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - Shared Components
// ═══════════════════════════════════════════════════════════════════════════

struct PremiumNudgeCard: View {
    @EnvironmentObject var appStore: ShiftStore
    let message: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "crown.fill").foregroundColor(.orange).font(.system(size: 18))
            Text(message).font(.system(size: 13, weight: .semibold)).foregroundColor(.black.opacity(0.8)).fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.orange.opacity(0.55), lineWidth: 1.5))
        .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
    }
}

struct DepartmentEditorSheet: View {
    let department: CustomDepartment?
    let onSave: (CustomDepartment) -> Void
    @State private var name = ""; @State private var subtitle = ""; @State private var iconName = "building.2.fill"
    @State private var showIconPicker = false; @State private var errorMessage = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") { TextField("e.g. Warehouse, ICU, Assembly", text: $name) }
                Section("Subtitle") { TextField("Brief description (optional)", text: $subtitle) }
                Section("Icon") {
                    Button { showIconPicker = true } label: {
                        HStack {
                            Image(systemName: iconName).foregroundColor(.blue).frame(width: 26)
                            Text("Change Icon").foregroundColor(.primary); Spacer()
                            Image(systemName: "chevron.right").foregroundColor(.secondary).font(.system(size: 13))
                        }
                    }
                }
                if !errorMessage.isEmpty { Section { Text(errorMessage).foregroundColor(.red).font(.system(size: 13)) } }
            }
            .navigationTitle(department == nil ? "Add Area" : "Edit Area")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { errorMessage = "Name is required."; return }
                        onSave(CustomDepartment(id: department?.id ?? UUID().uuidString,
                                               name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                                               subtitle: subtitle.trimmingCharacters(in: .whitespacesAndNewlines),
                                               iconName: iconName))
                        dismiss()
                    }.fontWeight(.bold)
                }
            }
            .sheet(isPresented: $showIconPicker) { IconPickerSheet(selectedIcon: $iconName) }
            .onAppear { if let d = department { name = d.name; subtitle = d.subtitle; iconName = d.iconName } }
        }
    }
}

struct IconPickerSheet: View {
    @Binding var selectedIcon: String
    @Environment(\.dismiss) private var dismiss
    private let cols = Array(repeating: GridItem(.flexible()), count: 5)

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: cols, spacing: 12) {
                    ForEach(CustomDepartment.availableIcons, id: \.self) { icon in
                        Button { selectedIcon = icon; dismiss() } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedIcon == icon ? Color.blue : Color(.systemGray5)).frame(width: 56, height: 56)
                                Image(systemName: icon).font(.system(size: 22))
                                    .foregroundColor(selectedIcon == icon ? .white : .primary)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Icon").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - Helpers
// ═══════════════════════════════════════════════════════════════════════════

extension Date {
    var displayDateTime: String { Self.dtf.string(from: self) }
    var displayTime: String     { Self.tf.string(from: self)  }
    private static let dtf: DateFormatter = { let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .short; return f }()
    private static let tf:  DateFormatter = { let f = DateFormatter(); f.dateStyle = .none;   f.timeStyle = .short; return f }()
}

// ═══════════════════════════════════════════════════════════════════════════

#Preview { ContentView() }

