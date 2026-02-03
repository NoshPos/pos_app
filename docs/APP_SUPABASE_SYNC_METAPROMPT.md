## 📋 Project Overview

This document serves as the master guide for synchronizing the **Flutter POS App** with **Supabase** database. The app was initially built with reference UI using mock data. Now we need to connect everything to real Supabase data with proper role-based access control.

### System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    SUPABASE DATABASE                        │
│  (Central source of truth - stores all business data)      │
└───────────────────┬─────────────────────┬──────────────────┘
                    │                     │
                    ▼                     ▼
        ┌──────────────────┐  ┌──────────────────────┐
        │  WEBSITE (POS)   │  │   MOBILE APP         │
        │  Data Creator    │  │   Data Viewer        │
        ├──────────────────┤  ├──────────────────────┤
        │ • Billing/Orders │  │ • Dashboard Stats    │
        │ • Inventory Mgmt │  │ • Sales Reports      │
        │ • Product Setup  │  │ • Store Analytics    │
        │ • Staff Actions  │  │ • Performance KPIs   │
        │                  │  │                      │
        │ Used by:         │  │ Used by:             │
        │ Cashiers         │  │ Owners               │
        │ Managers         │  │ Admins               │
        │ Admins           │  │                      │
        │ Owners           │  │                      │
        └──────────────────┘  └──────────────────────┘
```

**Data Flow:**

1. **Website** → Users create orders, manage products → Data saved to **Supabase**
2. **Supabase** → Aggregates data through RPC functions → **App** displays insights
3. **App** → Read-only monitoring/reporting tool for business owners

---

## 🎯 Objectives

### Primary Goals

1. **Remove all mock/hardcoded data** - Replace with real Supabase queries
2. **Implement role-based authentication** - App is for owner/admin ONLY
3. **Store selection functionality** - Allow user to select a store/outlet
4. **Real-time data sync** - Dashboard, sales, and statistics from Supabase
5. **Proper RLS enforcement** - Ensure data security at database level

### Access Control Matrix

| Platform          | Owner | Admin | Manager | Cashier | Kitchen | Waiter |
| ----------------- | ----- | ----- | ------- | ------- | ------- | ------ |
| **Mobile App**    | ✅    | ✅    | ❌      | ❌      | ❌      | ❌     |
| **Website (POS)** | ✅    | ✅    | ✅      | ✅      | ❌      | ❌     |

---

## � Authentication Systems

### Website Authentication (Next.js)

**Location:** `/pos_billing_web/app/(auth)/login/page.tsx`

**First Time Login (All Users):**

```
1. User enters email
2. Supabase sends OTP to email
3. User enters OTP code
4. Supabase verifies and creates session
5. Profile fetched from `profiles` table
6. Role checked (owner, admin, manager, cashier)
7. Redirect to dashboard/POS based on role
```

**Subsequent Login (Cashiers Only - Optional):**

```
1. User enters email
2. If PIN is set → User enters 5-digit PIN
3. PIN verified against `profiles.pin` field
4. Quick login (no OTP needed)
5. Redirect to POS billing page
```

**Technologies:**

- Supabase Auth for email/OTP
- Zustand for state management (`/pos_billing_web/lib/stores/user-store.ts`)
- TanStack Query for data fetching
- PIN stored in `profiles.pin` (nullable, hashed)

**Key Files:**

- `/pos_billing_web/app/(auth)/login/page.tsx` - Login UI
- `/pos_billing_web/lib/stores/user-store.ts` - User state
- `/pos_billing_web/lib/hooks/use-profile.ts` - Profile queries

---

### Mobile App Authentication (Flutter)

**Location:** `/lib/features/auth/viewmodel/auth_viewmodel.dart`

**Email Login Flow:**

```
1. User enters email
2. Supabase sends OTP to email
3. User enters OTP code
4. Supabase verifies OTP
5. App fetches profile from `profiles` table
6. Role validation: ONLY owner/admin allowed
7. If not owner/admin → Show error + auto sign-out
8. If valid → Proceed to dashboard
```

**Phone Login Flow (Firebase):**

```
1. User enters phone number
2. Firebase sends SMS OTP
3. User enters OTP code
4. Firebase verifies OTP
5. Link Firebase user to Supabase
6. Fetch profile and validate role (owner/admin only)
7. Proceed to dashboard or reject
```

**Google Sign-In Flow:**

```
1. User taps "Sign in with Google"
2. Google OAuth flow completes
3. Supabase creates/links user account
4. Fetch profile and validate role (owner/admin only)
5. Proceed to dashboard or reject
```

**Technologies:**

- Supabase Auth for email/OTP
- Firebase Auth for phone/SMS
- Google Sign-In package
- Riverpod for state management
- NO PIN functionality (website-only feature)

**Key Files:**

- `/lib/features/auth/viewmodel/auth_viewmodel.dart` - Auth logic + role validation
- `/lib/features/onboarding/view/pages/login_page.dart` - Login UI
- `/lib/main.dart` - AuthWrapper with role check
- `/lib/core/repositories/profile_repository.dart` - Profile queries

**Critical Difference:**

- ✅ Website: All roles can login (owner, admin, manager, cashier)
- ❌ App: ONLY owner/admin can login (others get "Access Denied")

---

## �🗂️ Current Architecture

### Database Schema (Supabase)

```
Tables:
├── stores              # Business outlets
├── profiles            # User profiles with roles
├── store_users         # User-Store junction (many-to-many)
├── categories          # Product categories
├── products            # Menu items
├── product_variants    # Product variants/sizes
├── customers           # Customer information
├── orders              # Sales orders
├── order_items         # Order line items
├── kitchen_orders      # Kitchen display orders
├── cash_registers      # Cash drawer sessions
├── coupons             # Discount coupons
├── restaurant_tables   # Table management
└── inventory_transactions
```

### Key Profile Fields

```dart
ProfileModel {
  String id;              // UUID from Supabase Auth
  String? fullName;
  String? email;
  String? phone;
  String? role;           // owner, admin, manager, cashier, kitchen, waiter
  String? storeId;        // Primary store assignment
  List<String> accessibleStoreIds;  // Multiple store access
}
```

> **Note:** PIN functionality is handled exclusively on the website for cashiers. The mobile app (owner/admin only) does not use PIN.

### Store Access Priority Logic

```
1. accessible_store_ids (if not empty) → Fetch stores by these IDs
2. store_id (if set) → Fetch single store
3. If role is 'owner' or 'admin' → Fetch all stores (up to limit)
```

---

## �️ Supabase Changes Required

### Migration Applied: `002_app_compatibility.sql`

**Location:** `/pos_billing_web/supabase/migrations/002_app_compatibility.sql`

#### 1. Store-User Junction Table

```sql
CREATE TABLE IF NOT EXISTS public.store_users (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  store_id UUID REFERENCES public.stores(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('owner', 'admin', 'manager', 'cashier', 'kitchen', 'waiter')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, store_id)
);
```

**Purpose:** Many-to-many relationship between users and stores

#### 2. RPC Functions for App

**a) Dashboard Stats for Single Store:**

```sql
CREATE OR REPLACE FUNCTION get_dashboard_stats(
  p_store_id UUID,
  p_date DATE DEFAULT CURRENT_DATE
) RETURNS JSON
```

Returns: total_sales, net_sales, total_orders, completed_orders, pending_orders, cancelled_orders, average_order_value, cash_sales, card_sales, upi_sales, online_sales

**b) Dashboard Stats for All Stores:**

```sql
CREATE OR REPLACE FUNCTION get_dashboard_stats_all(
  p_date DATE DEFAULT CURRENT_DATE
) RETURNS JSON
```

Returns: Aggregated stats across all accessible stores

**c) Outlet Statistics:**

```sql
CREATE OR REPLACE FUNCTION get_outlet_stats(
  p_date DATE DEFAULT CURRENT_DATE
) RETURNS JSON
```

Returns: Per-store breakdown (store_id, store_name, total_sales, total_orders, items_sold, net_sales)

**d) Sales Report:**

```sql
CREATE OR REPLACE FUNCTION get_sales_report(
  p_store_ids UUID[],
  p_start_date DATE,
  p_end_date DATE
) RETURNS JSON
```

Returns: Detailed sales data for date ranges

#### 3. Helper Functions

```sql
-- Check if user is owner/admin for a store
CREATE OR REPLACE FUNCTION is_owner_or_admin_for_store(p_store_id UUID)
RETURNS BOOLEAN

-- Check if user belongs to a store
CREATE OR REPLACE FUNCTION is_user_of_store(p_store_id UUID)
RETURNS BOOLEAN
```

#### 4. Row Level Security (RLS) Policies

**Orders Table:**

```sql
CREATE POLICY "Role-based order viewing"
  ON public.orders FOR SELECT
  USING (
    is_owner_or_admin_for_store(store_id)
    OR
    (is_user_of_store(store_id) AND cashier_id = auth.uid() AND DATE(created_at) = CURRENT_DATE)
  );
```

**Stores Table:**

```sql
CREATE POLICY "Users can view accessible stores"
  ON public.stores FOR SELECT
  USING (
    id IN (
      SELECT store_id FROM public.store_users WHERE user_id = auth.uid()
    )
  );
```

**Products Table:**

```sql
CREATE POLICY "Users can view products of accessible stores"
  ON public.products FOR SELECT
  USING (
    store_id IN (
      SELECT store_id FROM public.store_users WHERE user_id = auth.uid()
    )
  );
```

#### 5. Triggers for Data Sync

```sql
-- Auto-update updated_at timestamp
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_orders_updated_at
  BEFORE UPDATE ON public.orders
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

### Additional Supabase Configuration

**Realtime Subscriptions (Optional):**

```sql
-- Enable realtime for orders table (for live updates in app)
ALTER PUBLICATION supabase_realtime ADD TABLE orders;
ALTER PUBLICATION supabase_realtime ADD TABLE cash_registers;
```

**Indexes for Performance:**

```sql
-- Speed up dashboard queries
CREATE INDEX idx_orders_store_date ON orders(store_id, created_at);
CREATE INDEX idx_orders_cashier ON orders(cashier_id);
CREATE INDEX idx_store_users_lookup ON store_users(user_id, store_id);
```

---

## 📊 Data Display Guidelines for App

### What to Display vs. What to Hide

#### ✅ Display in App (Owner/Admin View)

**Dashboard Metrics:**

- Total Sales (₹)
- Net Sales (₹)
- Total Orders Count
- Completed Orders
- Pending Orders
- Cancelled Orders
- Average Order Value (₹)
- Payment Method Breakdown (Cash, Card, UPI, Online)

**Outlet Statistics:**

- Per-store sales comparison
- Items sold per outlet
- Order count per outlet
- Net sales per outlet

**Sales Reports:**

- Date range filtering
- Store filtering
- Order details (order_id, customer, items, total, payment method)
- Daily/Weekly/Monthly trends

**Store Management:**

- List of accessible stores
- Store names and types (Restaurant, Cafe, QSR, etc.)
- Active/Inactive status

**Profile Information:**

- User's full name
- Email
- Phone number
- Role (owner/admin)
- Accessible stores list

#### ❌ Do NOT Display in App

- PIN setup/management (website-only for cashiers)
- Order creation/editing (website-only)
- Product creation/editing (website-only)
- Inventory management (website-only)
- Kitchen order management (website-only)
- Table management (website-only)
- Cash register operations (website-only)
- Staff management (website-only)

### Display Format Standards

**Currency:**

```dart
// Use Indian Rupee format
₹45,000.50

// Helper function
String formatCurrency(double amount) {
  final formatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );
  return formatter.format(amount);
}
```

**Dates:**

```dart
// Display format: "3 Feb 2026"
String formatDate(DateTime date) {
  return DateFormat('d MMM y').format(date);
}

// Display format with time: "3 Feb 2026, 2:30 PM"
String formatDateTime(DateTime dateTime) {
  return DateFormat('d MMM y, h:mm a').format(dateTime);
}
```

**Numbers:**

```dart
// Orders count: "156 orders"
// Items sold: "450 items"
// Use commas for thousands: "1,234"
```

**Store Names:**

```dart
// Display with type badge
"Main Branch" [Restaurant]
"Express Outlet" [QSR]
```

**Loading States:**

```dart
// Use shimmer effect for cards
Shimmer.fromColors(
  baseColor: Colors.grey[300]!,
  highlightColor: Colors.grey[100]!,
  child: Container(...),
)
```

**Empty States:**

```dart
// When no data available
EmptyState(
  icon: Icons.receipt_long,
  title: "No orders today",
  subtitle: "Orders will appear here once created on the POS",
)
```

**Error States:**

```dart
// Network/API errors
ErrorWidget(
  message: "Failed to load data",
  onRetry: () => viewModel.refresh(),
)
```

---

## 🌐 Website Changes Required

### 1. Profile Table Schema Alignment

**Ensure `profiles` table has:**

```sql
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT,
  email TEXT,
  phone TEXT,
  pin TEXT, -- 5-digit PIN (hashed) - optional for cashiers
  role TEXT CHECK (role IN ('owner', 'admin', 'manager', 'cashier', 'kitchen', 'waiter')),
  store_id UUID REFERENCES public.stores(id),
  accessible_store_ids UUID[], -- Array of store IDs user can access
  is_2fa_enabled BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 2. Website Auth Changes

**File:** `/pos_billing_web/app/(auth)/login/page.tsx`

**Changes Made:**

- ✅ Email + OTP login for all users
- ✅ Optional PIN login for cashiers (after initial email setup)
- ✅ PIN stored in `profiles.pin` (hashed)
- ✅ Role-based redirect after login

**User Flow on Website:**

```typescript
// First time login (ALL users)
email → OTP → verify → fetch profile → redirect based on role

// Cashier subsequent login (optional)
email → PIN (if set) → verify → redirect to POS
```

### 3. User Store Updates

**File:** `/pos_billing_web/lib/stores/user-store.ts`

```typescript
interface UserState {
  user: User | null;
  profile: Profile | null;
  selectedStore: Store | null;
  accessibleStores: Store[];
  role: 'owner' | 'admin' | 'manager' | 'cashier' | null;
}

// Actions
setProfile(profile: Profile)
setSelectedStore(storeId: string)
fetchAccessibleStores()
```

### 4. API Route for Profile

**File:** `/pos_billing_web/app/api/profile/route.ts`

```typescript
// GET /api/profile - Fetch current user profile
export async function GET(request: Request) {
  const supabase = createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  const { data: profile } = await supabase
    .from("profiles")
    .select("*")
    .eq("id", user.id)
    .single();

  return NextResponse.json({ profile });
}

// PATCH /api/profile - Update profile (including PIN)
export async function PATCH(request: Request) {
  const { full_name, phone, pin } = await request.json();
  // Update logic...
}
```

### 5. Middleware for Role-Based Access

**File:** `/pos_billing_web/middleware.ts`

```typescript
export async function middleware(request: NextRequest) {
  const supabase = createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.redirect(new URL("/login", request.url));
  }

  // Fetch role from profile
  const { data: profile } = await supabase
    .from("profiles")
    .select("role")
    .eq("id", user.id)
    .single();

  // Protect admin routes
  if (request.nextUrl.pathname.startsWith("/admin")) {
    if (!["owner", "admin"].includes(profile?.role)) {
      return NextResponse.redirect(new URL("/pos", request.url));
    }
  }

  return NextResponse.next();
}
```

---

## �📁 Files to Modify

### 1. Authentication Layer

#### `/lib/features/auth/viewmodel/auth_viewmodel.dart`

**Changes Required:**

- [ ] After successful login, fetch user profile
- [ ] Check if role is 'owner' or 'admin'
- [ ] If not owner/admin, show error and sign out
- [ ] Store user profile in state for later use

```dart
// After verification success, add role check:
Future<bool> _validateRoleForApp(User user) async {
  final profileResult = await _profileRepo.getProfile();
  return profileResult.fold(
    (failure) => false,
    (profile) {
      if (!profile.isOwnerOrAdmin) {
        state = state.copyWith(
          error: 'Access Denied: This app is only for store owners and administrators.',
        );
        signOut();
        return false;
      }
      return true;
    },
  );
}
```

#### `/lib/features/onboarding/view/pages/login_page.dart`

**Changes Required:**

- [ ] Add role validation after OTP verification
- [ ] Show appropriate error message for non-owner/admin users
- [ ] Update Google sign-in flow with role check

#### `/lib/main.dart`

**Changes Required:**

- [ ] Check role on app startup (AuthWrapper)
- [ ] Redirect to login if role is invalid

---

### 2. Dashboard & Store Selection

#### `/lib/features/dashboard/viewmodel/dashboard_viewmodel.dart`

**Current State:** ✅ Already fetches from Supabase
**Additional Changes:**

- [ ] Add store selection persistence (save selected store to local storage)
- [ ] Add loading states for better UX
- [ ] Add real-time subscription for live updates

#### `/lib/features/dashboard/view/pages/dashboard_page.dart`

**Changes Required:**

- [ ] Ensure outlet dropdown works with real stores
- [ ] Show loading skeleton while data fetches
- [ ] Add pull-to-refresh functionality
- [ ] Handle empty state (no stores)

#### `/lib/core/widgets/common_scaffold.dart`

**Changes Required:**

- [ ] Verify outlet selector dropdown works correctly
- [ ] Persist selected outlet across app navigation
- [ ] Show store name and type in header

---

### 3. Repository Layer

#### `/lib/core/repositories/store_repository.dart`

**Current State:** ✅ Already implemented correctly
**Verification:**

- [ ] Test getAccessibleStores() returns correct stores based on profile
- [ ] Test store filtering works

#### `/lib/core/repositories/dashboard_repository.dart`

**Current State:** ✅ Already calls Supabase RPC functions
**Verification:**

- [ ] Ensure `get_dashboard_stats(p_store_id, p_date)` RPC works
- [ ] Ensure `get_dashboard_stats_all(p_date)` RPC works
- [ ] Ensure `get_outlet_stats(p_date)` RPC works

#### `/lib/core/repositories/sales_report_repository.dart`

**Changes Required:**

- [ ] Verify order query works with new RLS policies
- [ ] Test date range filtering
- [ ] Test store filtering

#### `/lib/core/repositories/profile_repository.dart`

**Current State:** ✅ Has isOwnerOrAdmin check
**Changes Made:**

- [x] Removed PIN-related methods (PIN is website-only for cashiers)
- [x] Test profile fetch works

---

### 4. Providers

#### `/lib/core/providers/repository_providers.dart`

**Changes Required:**

- [ ] Add profile repository provider if not exists
- [ ] Ensure all repository providers are properly initialized

#### `/lib/core/providers/local_storage_provider.dart`

**Changes Required:**

- [ ] Add method to save/get selected store ID
- [ ] Add method to cache user profile

---

### 5. UI Components

#### `/lib/features/dashboard/view/widgets/outlet_statistics_section.dart`

**Changes Required:**

- [ ] Display real outlet data
- [ ] Handle loading and empty states
- [ ] Show proper formatting for currency

#### `/lib/features/dashboard/view/widgets/stats_grid.dart`

**Changes Required:**

- [ ] Ensure stats display correctly from Supabase
- [ ] Add loading placeholders

#### `/lib/features/dashboard/view/widgets/total_sales_card.dart`

**Changes Required:**

- [ ] Display real sales data
- [ ] Handle zero sales gracefully

---

## 🔐 Security Implementation

### Row Level Security (RLS) - Already Applied via Migration

```sql
-- Orders: Role-based viewing
CREATE POLICY "Role-based order viewing"
    ON public.orders FOR SELECT
    USING (
        is_owner_or_admin_for_store(store_id)
        OR
        (is_user_of_store(store_id) AND cashier_id = auth.uid() AND DATE(created_at) = CURRENT_DATE)
    );
```

### App-Side Role Validation

```dart
// In AuthViewModel or AuthRepository
Future<bool> validateAppAccess() async {
  final profile = await getProfile();
  return profile.role == 'owner' || profile.role == 'admin';
}
```

---

## 🔄 Data Flow

### Login Flow

```
1. User enters email/phone
2. OTP sent via Supabase (email) or Firebase (phone)
3. User verifies OTP
4. App fetches user profile from Supabase
5. App checks if role is 'owner' or 'admin'
   - YES: Proceed to Dashboard
   - NO: Show error, sign out
6. App fetches accessible stores
7. Dashboard loads with default/first store
```

### Dashboard Data Flow

```
1. User selects outlet from dropdown (or "All Outlets")
2. DashboardViewModel calls:
   - getDashboardStats(storeId, date)
   - getOutletStats(date)
3. Repository calls Supabase RPC functions
4. RPC functions return aggregated data
5. UI updates with new data
```

### Store Selection Flow

```
1. User taps outlet selector in header
2. Dropdown shows: ["All Outlets", ...stores]
3. User selects a store
4. Selected store ID saved to state & local storage
5. Dashboard refreshes with selected store data
```

---

## 📊 Expected Data Display

### Dashboard Stats (from `get_dashboard_stats`)

```json
{
  "total_sales": 45000.5,
  "net_sales": 42000.0,
  "total_orders": 156,
  "completed_orders": 145,
  "pending_orders": 8,
  "cancelled_orders": 3,
  "average_order_value": 288.46,
  "cash_sales": 25000.0,
  "card_sales": 15000.0,
  "upi_sales": 5000.5,
  "online_sales": 0.0
}
```

### Outlet Stats (from `get_outlet_stats`)

```json
[
  {
    "store_id": "uuid-1",
    "store_name": "Main Branch",
    "total_sales": 30000.0,
    "total_orders": 100,
    "items_sold": 450,
    "net_sales": 28000.0
  },
  {
    "store_id": "uuid-2",
    "store_name": "Express Outlet",
    "total_sales": 15000.5,
    "total_orders": 56,
    "items_sold": 180,
    "net_sales": 14000.0
  }
]
```

---

## ✅ Implementation Checklist

### Phase 1: Authentication & Role Validation ✅ COMPLETED

- [x] Update AuthViewModel with role check after login
- [x] Update login_page.dart to handle role rejection (via AuthViewModel)
- [x] Update AuthWrapper in main.dart for startup role check
- [x] Test: Owner can login ✅
- [x] Test: Admin can login ✅
- [x] Test: Cashier gets rejected with error message ❌

### Phase 2: Store Selection & Persistence ✅ COMPLETED

- [x] Verify store dropdown in CommonScaffold works
- [x] Add store selection persistence to SharedPreferences
- [x] Load last selected store on app startup
- [x] Test: Selecting store updates dashboard ✅

### Phase 3: Dashboard Real Data ✅ COMPLETED

- [x] Verify DashboardRepository RPC calls work
- [x] Test with real data from Supabase
- [x] Add loading states to all widgets
- [x] Add error handling with retry option
- [x] Test: Date picker changes data ✅
- [x] Test: Pull to refresh works ✅

### Phase 4: Sales Reports (if applicable)

- [ ] Verify SalesReportRepository queries work
- [ ] Test store filtering
- [ ] Test date range filtering

### Phase 5: Testing & Polish

- [ ] Test entire flow: Login → Store Select → View Data
- [ ] Test offline behavior
- [ ] Test with multiple stores
- [ ] Test role-based access (try accessing as cashier)

---

## 🚀 Supabase RPC Functions (Already Created)

```sql
-- Get dashboard stats for a specific store
get_dashboard_stats(p_store_id UUID, p_date DATE) → JSON

-- Get dashboard stats for all stores
get_dashboard_stats_all(p_date DATE) → JSON

-- Get outlet statistics
get_outlet_stats(p_date DATE) → JSON

-- Get sales report
get_sales_report(p_store_ids UUID[], p_start_date DATE, p_end_date DATE) → JSON

-- Check if user is owner/admin
is_owner_or_admin_for_store(p_store_id UUID) → BOOLEAN
```

---

## 🔧 Environment Setup

### Required `.env` Variables

```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

### Supabase Dashboard Verification

1. Go to Supabase Dashboard → SQL Editor
2. Run: `SELECT * FROM profiles WHERE role IN ('owner', 'admin');`
3. Verify users exist and have correct roles
4. Run: `SELECT * FROM stores WHERE is_active = true;`
5. Verify stores exist

---

## 📝 Notes for Implementation

1. **No Mock Data**: All data must come from Supabase. Remove any hardcoded strings like store names, amounts, etc.

2. **Error Handling**: Always handle Supabase errors gracefully. Show user-friendly messages.

3. **Loading States**: Show shimmer/skeleton loaders while data is being fetched.

4. **Empty States**: Handle cases where there's no data (no stores, no orders, etc.)

5. **Currency Formatting**: Use consistent currency formatting (₹ or $ based on store settings).

6. **Date Handling**: Always use UTC for database, convert to local time for display.

7. **Real-time Updates**: Consider adding Supabase real-time subscriptions for live order updates.

---

## 🎯 Success Criteria

1. ✅ Only owner/admin can log into the app
2. ✅ Store dropdown shows real stores from Supabase
3. ✅ Selecting a store updates all dashboard data
4. ✅ Dashboard shows real sales data from orders table
5. ✅ Date selection fetches data for that specific date
6. ✅ "All Outlets" aggregates data from all accessible stores
7. ✅ No hardcoded/mock data anywhere in the app
8. ✅ Proper error handling and loading states

---

## 🔗 Related Files

- **Migration**: `/pos_billing_web/supabase/migrations/002_app_compatibility.sql`
- **Schema**: `/pos_billing_web/supabase/schema.sql`
- **Website Login**: `/pos_billing_web/app/(auth)/login/page.tsx`
- **Website User Store**: `/pos_billing_web/lib/stores/user-store.ts`

---

## 🔄 Changes Made (February 3, 2026)

### Files Modified:

#### 1. `/lib/features/auth/viewmodel/auth_viewmodel.dart`

- Added `ProfileModel? profile` and `bool isRoleValid` to AuthState
- Added `ProfileRepository` dependency
- Added `validateAppRole()` method that checks if user is owner/admin
- Updated `verifyEmailOtp()`, `signInWithGoogle()`, `verifyPhoneOtp()` to call role validation
- Auto sign-out if role is not owner/admin

#### 2. `/lib/main.dart`

- Added `_isRoleValid` and `_roleError` state variables
- Added `_validateUserRole()` method that queries `profiles` table
- Updated `_checkAuthState()` to validate role after auth
- Added "Access Denied" UI screen for non-owner/admin users
- Shows clear message directing cashiers to use web POS

#### 3. `/lib/features/dashboard/viewmodel/dashboard_viewmodel.dart`

- Added `LocalStorageService` dependency
- Updated `_loadInitialData()` to restore previously selected outlet
- Updated `setSelectedOutlet()` to persist selection to SharedPreferences

### Files Removed:

#### `/lib/features/more/view/widgets/web_login_pin_section.dart`

- Deleted entire file (433 lines) - PIN is for cashiers on website only

### PIN Removal Changes:

#### `/lib/features/more/view/pages/user_info_page.dart`

- Removed import for `web_login_pin_section.dart`
- Removed `_buildWebLoginPinSection()` method call and definition

#### `/lib/features/more/viewmodel/user_info_viewmodel.dart`

- Removed `isPinLoading` and `webLoginPin` state fields
- Removed `hasWebLoginPinSet` getter
- Removed `saveWebLoginPin()` and `removeWebLoginPin()` methods

#### `/lib/core/repositories/profile_repository.dart`

- Removed `pin` field from `ProfileModel`
- Removed `hasPinSet` getter
- Removed `updatePin()` and `removePin()` methods

Do perfectly!
