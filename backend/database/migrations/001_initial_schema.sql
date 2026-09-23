CREATE TABLE users (
    id UUID PRIMARY KEY,
    mobile VARCHAR(20) UNIQUE NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('CUSTOMER','SHOPKEEPER','ADMIN','SUPER_ADMIN')),
    name VARCHAR(120),
    email VARCHAR(180),
    profile_photo TEXT,
    city_id UUID,
    status VARCHAR(30) DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE cities (
    id UUID PRIMARY KEY,
    name VARCHAR(120) NOT NULL,
    state VARCHAR(120),
    country VARCHAR(120) DEFAULT 'India',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE categories (
    id UUID PRIMARY KEY,
    name VARCHAR(120) NOT NULL,
    parent_id UUID,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE businesses (
    id UUID PRIMARY KEY,
    owner_user_id UUID NOT NULL,
    category_id UUID,
    city_id UUID,
    business_name VARCHAR(180) NOT NULL,
    address TEXT,
    pincode VARCHAR(20),
    phone VARCHAR(20),
    whatsapp VARCHAR(20),
    email VARCHAR(180),
    description TEXT,
    logo_url TEXT,
    images JSONB,
    latitude DECIMAL(10,7),
    longitude DECIMAL(10,7),
    opening_time TIME,
    closing_time TIME,
    weekly_holiday VARCHAR(30),
    verification_status VARCHAR(30) DEFAULT 'PENDING',
    is_public BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE coupons (
    id UUID PRIMARY KEY,
    business_id UUID NOT NULL,
    coupon_number VARCHAR(50) NOT NULL,
    discount_percent DECIMAL(5,2) NOT NULL,
    coupon_type VARCHAR(30) NOT NULL,
    valid_from TIMESTAMP NOT NULL,
    valid_until TIMESTAMP NOT NULL,
    usage_limit INTEGER,
    used_count INTEGER DEFAULT 0,
    minimum_bill DECIMAL(12,2),
    maximum_discount DECIMAL(12,2),
    selection_mode VARCHAR(30) DEFAULT 'SEQUENTIAL',
    status VARCHAR(30) DEFAULT 'ACTIVE',
    terms TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE coupon_claims (
    id UUID PRIMARY KEY,
    coupon_id UUID NOT NULL,
    customer_id UUID NOT NULL,
    claim_code VARCHAR(100) UNIQUE NOT NULL,
    transaction_id UUID,
    claimed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    status VARCHAR(30) DEFAULT 'CLAIMED'
);

CREATE TABLE transactions (
    id UUID PRIMARY KEY,
    transaction_code VARCHAR(100) UNIQUE NOT NULL,
    coupon_claim_id UUID,
    customer_id UUID NOT NULL,
    business_id UUID NOT NULL,
    original_bill DECIMAL(12,2) NOT NULL,
    discount_amount DECIMAL(12,2) NOT NULL,
    final_bill DECIMAL(12,2) NOT NULL,
    status VARCHAR(30) DEFAULT 'PENDING',
    customer_confirmed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP
);

CREATE TABLE subscriptions (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL,
    plan_name VARCHAR(120) NOT NULL,
    billing_cycle VARCHAR(20),
    amount DECIMAL(12,2),
    start_date TIMESTAMP,
    expiry_date TIMESTAMP,
    status VARCHAR(30) DEFAULT 'TRIAL',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE payments (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL,
    subscription_id UUID,
    payment_provider VARCHAR(80),
    payment_id VARCHAR(180),
    amount DECIMAL(12,2),
    status VARCHAR(30),
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE reviews (
    id UUID PRIMARY KEY,
    customer_id UUID NOT NULL,
    business_id UUID NOT NULL,
    rating INTEGER CHECK (rating BETWEEN 1 AND 5),
    review_text TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE favorites (
    id UUID PRIMARY KEY,
    customer_id UUID NOT NULL,
    business_id UUID NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(customer_id, business_id)
);

CREATE TABLE notifications (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL,
    title VARCHAR(200),
    message TEXT,
    type VARCHAR(50),
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE otp_requests (
    id UUID PRIMARY KEY,
    mobile VARCHAR(20) NOT NULL,
    otp_hash VARCHAR(255),
    expires_at TIMESTAMP NOT NULL,
    verified_at TIMESTAMP,
    attempts INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_mobile ON users(mobile);
CREATE INDEX idx_business_city ON businesses(city_id);
CREATE INDEX idx_business_category ON businesses(category_id);
CREATE INDEX idx_coupon_business ON coupons(business_id);
CREATE INDEX idx_coupon_status ON coupons(status);
CREATE INDEX idx_claim_customer ON coupon_claims(customer_id);
CREATE INDEX idx_transaction_customer ON transactions(customer_id);
CREATE INDEX idx_transaction_business ON transactions(business_id);
CREATE INDEX idx_subscription_user ON subscriptions(user_id);
