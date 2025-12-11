CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    iin CHAR(12) UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    phone TEXT,
    email TEXT,
    status VARCHAR(10) CHECK (status IN ('active','blocked','frozen')),
    created_at TIMESTAMP DEFAULT NOW(),
    daily_limit_kzt NUMERIC(18,2)
);

CREATE TABLE accounts (
    account_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customers(customer_id),
    account_number TEXT UNIQUE NOT NULL,
    currency VARCHAR(3) CHECK(currency IN ('KZT','USD','EUR','RUB')),
    balance NUMERIC(18,2),
    is_active BOOLEAN DEFAULT TRUE,
    opened_at TIMESTAMP DEFAULT NOW(),
    closed_at TIMESTAMP
);

CREATE TABLE transactions (
    transaction_id SERIAL PRIMARY KEY,
    from_account_id INT REFERENCES accounts(account_id),
    to_account_id INT REFERENCES accounts(account_id),
    amount NUMERIC(18,2),
    currency VARCHAR(3),
    exchange_rate NUMERIC(18,6),
    amount_kzt NUMERIC(18,2),
    type VARCHAR(20),
    status VARCHAR(20),
    created_at TIMESTAMP DEFAULT NOW(),
    completed_at TIMESTAMP,
    description TEXT
);

CREATE TABLE exchange_rates (
    rate_id SERIAL PRIMARY KEY,
    from_currency VARCHAR(3),
    to_currency VARCHAR(3),
    rate NUMERIC(18,6),
    valid_from TIMESTAMP,
    valid_to TIMESTAMP
);

CREATE TABLE audit_log (
    log_id SERIAL PRIMARY KEY,
    table_name TEXT,
    record_id INT,
    action VARCHAR(10),
    old_values JSONB,
    new_values JSONB,
    changed_by TEXT,
    changed_at TIMESTAMP DEFAULT NOW(),
    ip_address TEXT
);

INSERT INTO customers(iin,full_name,status,daily_limit_kzt)
VALUES
('990101123456','User1','active',1000000),
('990202123457','User2','active',500000),
('990303123458','User3','blocked',200000),
('990404123459','User4','active',700000),
('990505123450','User5','frozen',250000),
('990606123451','User6','active',300000),
('990707123452','User7','active',400000),
('990808123453','User8','active',350000),
('990909123454','User9','active',600000),
('991010123455','User10','active',800000);

INSERT INTO accounts(customer_id,account_number,currency,balance)
VALUES
(1,'ACC1','KZT',200000),
(1,'ACC2','USD',1000),
(2,'ACC3','KZT',150000),
(2,'ACC4','EUR',500),
(3,'ACC5','USD',100),
(4,'ACC6','KZT',450000),
(5,'ACC7','KZT',30000),
(6,'ACC8','RUB',20000),
(7,'ACC9','EUR',300),
(8,'ACC10','KZT',800000);

INSERT INTO exchange_rates(from_currency,to_currency,rate,valid_from,valid_to)
VALUES
('USD','KZT',500,NOW(),NOW()+INTERVAL '30 days'),
('EUR','KZT',550,NOW(),NOW()+INTERVAL '30 days'),
('RUB','KZT',5,NOW(),NOW()+INTERVAL '30 days'),
('KZT','USD',0.002,NOW(),NOW()+INTERVAL '30 days'),
('KZT','EUR',0.0018,NOW(),NOW()+INTERVAL '30 days');

--1
CREATE OR REPLACE FUNCTION process_transfer(
    p_from_acc TEXT,
    p_to_acc TEXT,
    p_amount NUMERIC,
    p_currency VARCHAR(3),
    p_description TEXT
)
RETURNS TEXT AS $$
DECLARE
    v_from_id INT;
    v_to_id INT;
    v_customer_id INT;
    v_customer_status TEXT;
    v_rate NUMERIC;
    v_amount_kzt NUMERIC;
    v_today NUMERIC;
    v_limit NUMERIC;
BEGIN
    SELECT account_id, customer_id INTO v_from_id, v_customer_id
    FROM accounts WHERE account_number=p_from_acc AND is_active=TRUE;

    IF v_from_id IS NULL THEN
        RAISE EXCEPTION 'Account not found';
    END IF;

    SELECT status, daily_limit_kzt INTO v_customer_status, v_limit
    FROM customers WHERE customer_id=v_customer_id;

    IF v_customer_status <> 'active' THEN
        RAISE EXCEPTION 'Customer is not active';
    END IF;

    SELECT account_id INTO v_to_id
    FROM accounts WHERE account_number=p_to_acc AND is_active=TRUE;

    IF v_to_id IS NULL THEN
        RAISE EXCEPTION 'Destination account not found';
    END IF;

    PERFORM 1 FROM accounts WHERE account_id=v_from_id FOR UPDATE;
    PERFORM 1 FROM accounts WHERE account_id=v_to_id FOR UPDATE;

    IF (SELECT balance FROM accounts WHERE account_id=v_from_id) < p_amount THEN
        RAISE EXCEPTION 'Insufficient balance';
    END IF;

    SELECT COALESCE(SUM(amount_kzt),0) INTO v_today
    FROM transactions
    WHERE from_account_id=v_from_id AND created_at::date=NOW()::date;

    SELECT rate INTO v_rate
    FROM exchange_rates
    WHERE from_currency=p_currency AND to_currency='KZT'
    ORDER BY valid_from DESC LIMIT 1;

    v_amount_kzt := p_amount * v_rate;

    IF v_today + v_amount_kzt > v_limit THEN
        RAISE EXCEPTION 'Daily limit exceeded';
    END IF;

    UPDATE accounts SET balance = balance - p_amount WHERE account_id=v_from_id;
    UPDATE accounts SET balance = balance + p_amount WHERE account_id=v_to_id;

    INSERT INTO transactions(from_account_id,to_account_id,amount,currency,
        exchange_rate,amount_kzt,type,status,completed_at,description)
    VALUES(v_from_id,v_to_id,p_amount,p_currency,v_rate,v_amount_kzt,
        'transfer','completed',NOW(),p_description);

    RETURN 'OK';
END;
$$ LANGUAGE plpgsql;

--2
-- View 1
CREATE VIEW customer_balance_summary AS
SELECT
    c.customer_id,
    c.full_name,
    a.account_number,
    a.currency,
    a.balance,
    a.balance * r.rate AS balance_kzt,
    SUM(a.balance*r.rate) OVER(PARTITION BY c.customer_id) AS total_balance_kzt,
    ROUND(
        (SUM(a.balance*r.rate) OVER(PARTITION BY c.customer_id) / c.daily_limit_kzt)*100,
        2
    ) AS daily_limit_percent,
    RANK() OVER(ORDER BY SUM(a.balance*r.rate)
                OVER(PARTITION BY c.customer_id) DESC)
FROM customers c
JOIN accounts a ON a.customer_id=c.customer_id
LEFT JOIN exchange_rates r ON r.from_currency=a.currency AND r.to_currency='KZT';

-- View 2
CREATE VIEW daily_transaction_report AS
SELECT
    created_at::date AS date,
    type,
    COUNT(*) AS tx_count,
    SUM(amount_kzt) AS total_volume,
    AVG(amount_kzt) AS avg_amount,
    SUM(SUM(amount_kzt)) OVER(ORDER BY created_at::date) AS running_total,
    LAG(SUM(amount_kzt)) OVER(ORDER BY created_at::date) AS prev_day,
    CASE
        WHEN LAG(SUM(amount_kzt)) OVER(ORDER BY created_at::date) IS NULL THEN NULL
        ELSE ROUND(
            (SUM(amount_kzt)-LAG(SUM(amount_kzt))
             OVER(ORDER BY created_at::date))
            / LAG(SUM(amount_kzt))
              OVER(ORDER BY created_at::date) * 100, 2)
    END AS growth
FROM transactions
GROUP BY created_at::date, type;

-- View 3
CREATE VIEW suspicious_activity_view
WITH (security_barrier = true) AS
SELECT t.*
FROM transactions t
WHERE t.amount_kzt > 5000000
   OR (
        SELECT COUNT(*) FROM transactions t2
        WHERE t2.from_account_id=t.from_account_id
          AND t2.created_at BETWEEN t.created_at - INTERVAL '1 hour'
                                AND t.created_at
      ) > 10
   OR EXISTS (
        SELECT 1 FROM transactions t3
        WHERE t3.from_account_id=t.from_account_id
          AND t3.created_at > t.created_at - INTERVAL '1 minute'
      );

--3
CREATE INDEX idx_accounts_active ON accounts(account_number) WHERE is_active=TRUE;
CREATE INDEX idx_email_lower ON customers(LOWER(email));
CREATE INDEX idx_audit_gin ON audit_log USING GIN(new_values);
CREATE INDEX idx_acc_customer_currency ON accounts(customer_id, currency);
CREATE INDEX idx_tx_cover ON transactions(from_account_id, created_at, amount_kzt);

--4
CREATE OR REPLACE FUNCTION process_salary_batch(
    p_company_acc TEXT,
    p_payments JSONB
)
RETURNS JSONB AS $$
DECLARE
    v_company_acc_id INT;
    v_company_balance NUMERIC;
    v_item JSONB;
    v_to_acc INT;
    v_amount NUMERIC;
    v_success INT := 0;
    v_fail INT := 0;
    v_failed JSONB := '[]';
BEGIN
    SELECT account_id, balance
    INTO v_company_acc_id, v_company_balance
    FROM accounts
    WHERE account_number = p_company_acc;
    IF v_company_acc_id IS NULL THEN
        RAISE EXCEPTION 'Company account not found';
    END IF;
    IF v_company_balance < (
        SELECT SUM((elem->>'amount')::NUMERIC)
        FROM jsonb_array_elements(p_payments) AS elem
    ) THEN
        RAISE EXCEPTION 'Insufficient company balance for batch';
    END IF;
    PERFORM pg_advisory_lock(hashtext(p_company_acc));
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_payments)
    LOOP
        v_amount := (v_item->>'amount')::NUMERIC;
        SELECT a.account_id INTO v_to_acc
        FROM accounts a
        JOIN customers c ON a.customer_id = c.customer_id
        WHERE c.iin = v_item->>'iin'
          AND a.is_active = TRUE
        LIMIT 1;
        IF v_to_acc IS NULL THEN
            v_fail := v_fail + 1;
            v_failed := v_failed ||
                        jsonb_build_object('iin', v_item->>'iin', 'error', 'Account not found');
            CONTINUE;
        END IF;
        SAVEPOINT sp_transfer;
        BEGIN
            UPDATE accounts
            SET balance = balance - v_amount
            WHERE account_id = v_company_acc_id;
            UPDATE accounts
            SET balance = balance + v_amount
            WHERE account_id = v_to_acc;
            INSERT INTO transactions(
                from_account_id, to_account_id, amount,
                currency, amount_kzt, type,
                status, completed_at, description
            )
            VALUES (
                v_company_acc_id, v_to_acc, v_amount,
                'KZT', v_amount, 'salary',
                'completed', NOW(), v_item->>'description'
            );
            v_success := v_success + 1;
        EXCEPTION WHEN OTHERS THEN
            ROLLBACK TO sp_transfer;
            v_fail := v_fail + 1;
            v_failed := v_failed ||
                        jsonb_build_object('iin', v_item->>'iin', 'error', 'Transfer failed');
        END;
    END LOOP;
    PERFORM pg_advisory_unlock(hashtext(p_company_acc));
    RETURN jsonb_build_object(
        'successful', v_success,
        'failed', v_fail,
        'failed_details', v_failed
    );
END;
$$ LANGUAGE plpgsql;
