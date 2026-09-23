CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  mobile VARCHAR(20) NOT NULL UNIQUE,
  role VARCHAR(20) NOT NULL CHECK (role IN ('CUSTOMER','SHOPKEEPER','ADMIN','SUPER_ADMIN')),
  name VARCHAR(120),
  email VARCHAR(255),
  profile_photo TEXT,
  city_id UUID,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS cities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(120) NOT NULL,
  state VARCHAR(120),
  country VARCHAR(120) NOT NULL DEFAULT 'India',
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(name, state, country)
);

CREATE TABLE IF NOT EXISTS categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(120) NOT NULL UNIQUE,
  description TEXT,
  icon_url TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS shopkeepers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES users(id),
  owner_name VARCHAR(150) NOT NULL,
  business_phone VARCHAR(20),
  email VARCHAR(255),
  verification_status VARCHAR(20) NOT NULL DEFAULT 'PENDING'
    CHECK (verification_status IN ('PENDING','VERIFIED','REJECTED','SUSPENDED')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS businesses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shopkeeper_id UUID NOT NULL REFERENCES shopkeepers(id),
  category_id UUID REFERENCES categories(id),
  city_id UUID REFERENCES cities(id),
  business_name VARCHAR(180) NOT NULL,
  subcategory VARCHAR(120),
  address TEXT NOT NULL,
  pincode VARCHAR(10),
  phone VARCHAR(20),
  whatsapp VARCHAR(20),
  email VARCHAR(255),
  latitude DECIMAL(10,7),
  longitude DECIMAL(10,7),
  description TEXT,
  logo_url TEXT,
  weekly_holiday VARCHAR(30),
  opening_time TIME,
  closing_time TIME,
  images JSONB NOT NULL DEFAULT '[]',
  terms TEXT,
  is_public BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS coupon_campaigns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID NOT NULL REFERENCES businesses(id),
  name VARCHAR(180) NOT NULL,
  selection_mode VARCHAR(30) NOT NULL DEFAULT 'SEQUENTIAL'
    CHECK (selection_mode IN ('SEQUENTIAL','CUSTOMER_SELECT','SHOPKEEPER_CONTROLLED')),
  validity_start TIMESTAMPTZ NOT NULL,
  validity_end TIMESTAMPTZ NOT NULL,
  usage_limit INTEGER,
  min_bill DECIMAL(12,2),
  max_discount DECIMAL(12,2),
  terms TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS coupons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id UUID NOT NULL REFERENCES coupon_campaigns(id),
  coupon_number VARCHAR(80) NOT NULL UNIQUE,
  discount_percent DECIMAL(5,2) NOT NULL CHECK (discount_percent > 0 AND discount_percent <= 100),
  coupon_type VARCHAR(30) NOT NULL DEFAULT 'PERCENTAGE',
  status VARCHAR(20) NOT NULL DEFAULT 'AVAILABLE'
    CHECK (status IN ('AVAILABLE','CLAIMED','USED','EXPIRED','LOCKED')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS coupon_claims (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  coupon_id UUID NOT NULL REFERENCES coupons(id),
  customer_id UUID NOT NULL REFERENCES users(id),
  transaction_id UUID,
  claimed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ,
  status VARCHAR(20) NOT NULL DEFAULT 'CLAIMED'
    CHECK (status IN ('CLAIMED','USED','EXPIRED','CANCELLED')),
  UNIQUE(coupon_id)
);

CREATE TABLE IF NOT EXISTS transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_code VARCHAR(80) NOT NULL UNIQUE,
  coupon_id UUID NOT NULL REFERENCES coupons(id),
  customer_id UUID NOT NULL REFERENCES users(id),
  business_id UUID NOT NULL REFERENCES businesses(id),
  original_bill DECIMAL(12,2) NOT NULL CHECK (original_bill >= 0),
  discount_percent DECIMAL(5,2) NOT NULL,
  discount_amount DECIMAL(12,2) NOT NULL,
  final_amount DECIMAL(12,2) NOT NULL,
  verification_code VARCHAR(20),
  status VARCHAR(20) NOT NULL DEFAULT 'PENDING'
    CHECK (status IN ('PENDING','CONFIRMED','COMPLETED','CANCELLED')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);

ALTER TABLE coupon_claims
  ADD CONSTRAINT fk_claim_transaction
  FOREIGN KEY (transaction_id) REFERENCES transactions(id);

CREATE TABLE IF NOT EXISTS subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  plan_name VARCHAR(120) NOT NULL,
  billing_cycle VARCHAR(20) NOT NULL
    CHECK (billing_cycle IN ('MONTHLY','YEARLY','PROMOTIONAL','TRIAL')),
  amount DECIMAL(12,2) NOT NULL DEFAULT 0,
  status VARCHAR(30) NOT NULL DEFAULT 'TRIAL'
    CHECK (status IN ('ACTIVE','TRIAL','EXPIRING_SOON','EXPIRED','CANCELLED','SUSPENDED')),
  starts_at TIMESTAMPTZ NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  subscription_id UUID REFERENCES subscriptions(id),
  payment_provider VARCHAR(60),
  payment_id VARCHAR(180),
  amount DECIMAL(12,2) NOT NULL,
  status VARCHAR(30) NOT NULL,
  paid_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS favorites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL REFERENCES users(id),
  business_id UUID NOT NULL REFERENCES businesses(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(customer_id, business_id)
);

CREATE TABLE IF NOT EXISTS reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL REFERENCES users(id),
  business_id UUID NOT NULL REFERENCES businesses(id),
  rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
  review_text TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  title VARCHAR(180) NOT NULL,
  message TEXT NOT NULL,
  type VARCHAR(60),
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS admin_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES users(id),
  permissions JSONB NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_business_city ON businesses(city_id);
CREATE INDEX IF NOT EXISTS idx_business_category ON businesses(category_id);
CREATE INDEX IF NOT EXISTS idx_coupon_campaign ON coupons(campaign_id);
CREATE INDEX IF NOT EXISTS idx_coupon_status ON coupons(status);
CREATE INDEX IF NOT EXISTS idx_transactions_customer ON transactions(customer_id);
CREATE INDEX IF NOT EXISTS idx_transactions_business ON transactions(business_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_user ON subscriptions(user_id);

