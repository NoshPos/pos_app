# POS Admin Dashboard - Complete Meta-Prompt

> **Copy everything below this line to start building your website**

---

Build a modern, responsive admin dashboard website for a POS (Point of Sale) system. This website allows business owners/admins to manage data that syncs with a Flutter mobile app via Supabase.

## Tech Stack

- **Framework:** Next.js 14+ (App Router) with TypeScript
- **Styling:** Tailwind CSS + shadcn/ui components
- **State Management:** TanStack Query (React Query) for server state
- **Forms:** React Hook Form + Zod validation
- **Authentication:** Supabase Auth (Email OTP, Phone OTP, Google OAuth)
- **Database:** Supabase (PostgreSQL)
- **Charts:** Recharts for analytics
- **Icons:** Lucide React
- **Date Handling:** date-fns

## Theme & Design System (MUST MATCH MOBILE APP)

```css
:root {
  --primary: #1290ff;
  --primary-light: #4ba9ff;
  --primary-dark: #0a6fcc;
  --primary-foreground: #ffffff;
  --background: #ffffff;
  --surface: #f8fafc;
  --surface-variant: #f1f5f9;
  --on-surface: #0f172a;
  --on-surface-variant: #475569;
  --muted: #94a3b8;
  --border: #e2e8f0;
  --success: #22c55e;
  --warning: #f59e0b;
  --error: #ef4444;
  --info: #3b82f6;
}

[data-theme="dark"] {
  --background: #0f172a;
  --surface: #1e293b;
  --surface-variant: #334155;
  --on-surface: #f8fafc;
  --on-surface-variant: #cbd5e1;
  --border: #334155;
}
```

Font Family: Inter (Google Fonts), Semi-bold headings, 8px spacing grid, 8-12px border radius.

## Supabase Database Schema

```sql
CREATE TABLE stores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  address TEXT,
  phone VARCHAR(20),
  email VARCHAR(255),
  logo_url TEXT,
  gst_number VARCHAR(50),
  store_type VARCHAR(50) DEFAULT 'restaurant',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id UUID REFERENCES stores(id),
  name VARCHAR(255) NOT NULL,
  description TEXT,
  price DECIMAL(10,2) NOT NULL,
  category_id UUID,
  image_url TEXT,
  is_available BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id UUID REFERENCES stores(id),
  name VARCHAR(255) NOT NULL,
  description TEXT,
  sort_order INT DEFAULT 0,
  is_active BOOLEAN DEFAULT true
);

CREATE TABLE orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id UUID REFERENCES stores(id) NOT NULL,
  order_number VARCHAR(50) NOT NULL,
  customer_id UUID,
  customer_name VARCHAR(255),
  table_id UUID,
  table_name VARCHAR(50),
  status VARCHAR(20) DEFAULT 'pending',
  order_type VARCHAR(20) DEFAULT 'dine_in',
  platform_order_id VARCHAR(100),
  subtotal DECIMAL(10,2) DEFAULT 0,
  tax_amount DECIMAL(10,2) DEFAULT 0,
  discount_amount DECIMAL(10,2) DEFAULT 0,
  total_amount DECIMAL(10,2) DEFAULT 0,
  payment_method VARCHAR(20),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);

CREATE TABLE order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id),
  product_name VARCHAR(255),
  variant_id UUID,
  variant_name VARCHAR(255),
  quantity INT DEFAULT 1,
  unit_price DECIMAL(10,2),
  total_price DECIMAL(10,2),
  notes TEXT
);

CREATE TABLE customers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id UUID REFERENCES stores(id),
  name VARCHAR(255) NOT NULL,
  phone VARCHAR(20),
  email VARCHAR(255),
  address TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Order status values: pending, confirmed, preparing, ready, completed, cancelled
-- Order type values: dine_in, takeaway, delivery, swiggy, zomato, foodpanda, uber_eats
-- Payment methods: cash, card, upi, online
```

## Required RPC Functions (Create in Supabase SQL Editor)

```sql
CREATE OR REPLACE FUNCTION get_dashboard_stats(p_store_id UUID, p_date DATE)
RETURNS JSON AS $$
  SELECT json_build_object(
    'total_sales', COALESCE(SUM(total_amount), 0),
    'net_sales', COALESCE(SUM(total_amount - tax_amount), 0),
    'total_orders', COUNT(*),
    'completed_orders', COUNT(*) FILTER (WHERE status = 'completed'),
    'pending_orders', COUNT(*) FILTER (WHERE status = 'pending'),
    'cancelled_orders', COUNT(*) FILTER (WHERE status = 'cancelled'),
    'average_order_value', COALESCE(AVG(total_amount), 0),
    'cash_sales', COALESCE(SUM(total_amount) FILTER (WHERE payment_method = 'cash'), 0),
    'card_sales', COALESCE(SUM(total_amount) FILTER (WHERE payment_method = 'card'), 0),
    'upi_sales', COALESCE(SUM(total_amount) FILTER (WHERE payment_method = 'upi'), 0),
    'online_sales', COALESCE(SUM(total_amount) FILTER (WHERE payment_method = 'online'), 0)
  )
  FROM orders
  WHERE store_id = p_store_id AND DATE(created_at) = p_date;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_dashboard_stats_all(p_date DATE)
RETURNS JSON AS $$
  SELECT json_build_object(
    'total_sales', COALESCE(SUM(total_amount), 0),
    'net_sales', COALESCE(SUM(total_amount - tax_amount), 0),
    'total_orders', COUNT(*),
    'completed_orders', COUNT(*) FILTER (WHERE status = 'completed'),
    'pending_orders', COUNT(*) FILTER (WHERE status = 'pending'),
    'cancelled_orders', COUNT(*) FILTER (WHERE status = 'cancelled'),
    'average_order_value', COALESCE(AVG(total_amount), 0),
    'cash_sales', COALESCE(SUM(total_amount) FILTER (WHERE payment_method = 'cash'), 0),
    'card_sales', COALESCE(SUM(total_amount) FILTER (WHERE payment_method = 'card'), 0),
    'upi_sales', COALESCE(SUM(total_amount) FILTER (WHERE payment_method = 'upi'), 0),
    'online_sales', COALESCE(SUM(total_amount) FILTER (WHERE payment_method = 'online'), 0)
  )
  FROM orders
  WHERE DATE(created_at) = p_date;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_outlet_stats(p_date DATE)
RETURNS JSON AS $$
  SELECT json_agg(row_to_json(t))
  FROM (
    SELECT
      s.id as store_id,
      s.name as store_name,
      COALESCE(SUM(o.total_amount), 0) as total_sales,
      COUNT(o.id) as total_orders,
      COALESCE(SUM(o.total_amount - o.tax_amount), 0) as net_sales
    FROM stores s
    LEFT JOIN orders o ON s.id = o.store_id AND DATE(o.created_at) = p_date
    WHERE s.is_active = true
    GROUP BY s.id, s.name
    ORDER BY s.name
  ) t;
$$ LANGUAGE SQL;
```

## Project Structure

```
pos-admin-web/
├── app/
│   ├── (auth)/
│   │   ├── login/page.tsx
│   │   └── layout.tsx
│   ├── (dashboard)/
│   │   ├── layout.tsx
│   │   ├── page.tsx
│   │   ├── stores/
│   │   │   ├── page.tsx
│   │   │   ├── [id]/page.tsx
│   │   │   └── new/page.tsx
│   │   ├── products/
│   │   │   ├── page.tsx
│   │   │   ├── [id]/page.tsx
│   │   │   └── new/page.tsx
│   │   ├── orders/
│   │   │   ├── page.tsx
│   │   │   ├── [id]/page.tsx
│   │   │   └── running/page.tsx
│   │   ├── reports/
│   │   │   └── page.tsx
│   │   └── settings/
│   │       └── page.tsx
│   ├── layout.tsx
│   └── globals.css
├── components/
│   ├── ui/ (shadcn components)
│   ├── dashboard/
│   │   ├── stats-card.tsx
│   │   ├── sales-chart.tsx
│   │   └── outlet-table.tsx
│   ├── forms/
│   │   ├── store-form.tsx
│   │   ├── product-form.tsx
│   │   └── order-form.tsx
│   ├── layout/
│   │   ├── sidebar.tsx
│   │   ├── header.tsx
│   │   └── mobile-nav.tsx
│   └── shared/
│       ├── data-table.tsx
│       ├── date-picker.tsx
│       └── store-selector.tsx
├── lib/
│   ├── supabase/
│   │   ├── client.ts
│   │   ├── server.ts
│   │   └── middleware.ts
│   ├── hooks/
│   │   ├── use-stores.ts
│   │   ├── use-products.ts
│   │   ├── use-orders.ts
│   │   └── use-dashboard.ts
│   ├── utils.ts
│   └── validations/
│       ├── store.ts
│       ├── product.ts
│       └── order.ts
├── types/
│   └── database.ts
├── .env.local
├── tailwind.config.ts
├── next.config.js
└── package.json
```

## Core Features to Implement

### 1. Authentication

- Login page with Email/Phone input that sends OTP
- Google OAuth button
- OTP verification modal/sheet
- Session persistence with Supabase
- Protected route middleware
- Logout functionality

### 2. Dashboard Page (/)

- Welcome header with current date
- Store/Outlet dropdown selector (filters all data)
- Date picker to select reporting date
- Stats cards grid showing: Total Sales, Net Sales, Total Orders, Completed Orders, Pending Orders, Cancelled Orders, Average Order Value
- Payment breakdown cards: Cash, Card, UPI, Online sales
- Outlet statistics table showing per-store performance
- Auto-refresh every 30 seconds or use real-time subscriptions

### 3. Stores Management (/stores)

- Data table listing all stores with columns: Name, Address, Phone, Type, Status, Actions
- Search and filter functionality
- "Add Store" button opening form page
- Edit store page with all fields
- Toggle store active/inactive status
- Delete store (soft delete)

### 4. Products Management (/products)

- Data table with columns: Name, Category, Price, Store, Availability, Actions
- Filter by store, category, availability
- Search by name
- "Add Product" form with: name, description, price, category dropdown, store dropdown, image upload, variants
- Edit product page
- Toggle availability (mark out of stock)
- Bulk actions: delete, mark unavailable

### 5. Orders Management (/orders)

- Data table with columns: Order #, Store, Customer, Type, Status, Total, Date, Actions
- Filter by: status (pending/confirmed/preparing/ready/completed/cancelled), order type (dine_in/takeaway/delivery/swiggy/zomato), date range, store
- Order detail page showing: order info, customer info, items list, totals breakdown
- Update order status dropdown
- Running orders page (/orders/running) showing only active orders with real-time updates

### 6. Reports (/reports)

- Date range selector
- Store filter
- Sales summary cards
- Line chart showing sales over time
- Bar chart showing sales by payment method
- Table showing daily breakdown
- Export to CSV button

### 7. Settings (/settings)

- Business profile form
- Tax configuration
- Default store settings

## Environment Variables (.env.local)

```
NEXT_PUBLIC_SUPABASE_URL=your_supabase_project_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
```

## Key Implementation Code Snippets

### Supabase Client (lib/supabase/client.ts)

```typescript
import { createBrowserClient } from "@supabase/ssr";

export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
  );
}
```

### Real-time Subscriptions Example

```typescript
useEffect(() => {
  const supabase = createClient();
  const channel = supabase
    .channel("orders-changes")
    .on(
      "postgres_changes",
      {
        event: "*",
        schema: "public",
        table: "orders",
        filter: `store_id=eq.${storeId}`,
      },
      (payload) => {
        queryClient.invalidateQueries({ queryKey: ["orders"] });
      },
    )
    .subscribe();

  return () => {
    supabase.removeChannel(channel);
  };
}, [storeId]);
```

### Dashboard Stats Hook Example

```typescript
export function useDashboardStats(storeId: string | null, date: Date) {
  const supabase = createClient();

  return useQuery({
    queryKey: ["dashboard-stats", storeId, date.toISOString()],
    queryFn: async () => {
      const rpc = storeId
        ? supabase.rpc("get_dashboard_stats", {
            p_store_id: storeId,
            p_date: date.toISOString().split("T")[0],
          })
        : supabase.rpc("get_dashboard_stats_all", {
            p_date: date.toISOString().split("T")[0],
          });

      const { data, error } = await rpc;
      if (error) throw error;
      return data;
    },
  });
}
```

## Responsive Breakpoints

- Mobile: < 640px (single column, bottom nav)
- Tablet: 640px - 1024px (collapsible sidebar)
- Desktop: > 1024px (full sidebar)

## Deliverables

1. Complete Next.js 14 application with all pages
2. Full CRUD for stores, products, orders
3. Dashboard with charts and real-time data
4. Authentication with OTP and Google OAuth
5. Responsive design matching the mobile app theme (primary color #1290FF)
6. TypeScript types for all database tables
7. Form validation with Zod
8. Loading states and error handling

Start by setting up the Next.js project with: `npx create-next-app@latest pos-admin-web --typescript --tailwind --eslint --app --src-dir=false`

Then install dependencies: `npm install @supabase/supabase-js @supabase/ssr @tanstack/react-query react-hook-form @hookform/resolvers zod recharts date-fns lucide-react`

Then set up shadcn/ui: `npx shadcn@latest init` and add components as needed.
