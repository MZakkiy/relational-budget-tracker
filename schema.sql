-- In this SQL file, write (and comment!) the schema of your database, including the CREATE TABLE, CREATE INDEX, CREATE VIEW, etc. statements that compose it

DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS accounts;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS transactions;
DROP TABLE IF EXISTS budget;

DROP VIEW IF EXISTS transaction_history;
DROP VIEW IF EXISTS spending_by_category;

DROP INDEX IF EXISTS idx_transactions_date;
DROP INDEX IF EXISTS idx_transactions_account_id;
DROP INDEX IF EXISTS idx_transactions_category_id;
DROP INDEX IF EXISTS idx_accounts_user_id;

-- 1. Users Table: Stores the people using the finance app
CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL
);

-- 2. Accounts Table: Stores bank accounts, credit cards, or cash wallets
CREATE TABLE accounts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    account_name TEXT NOT NULL, -- e.g., "Chase Checking", "Emergency Fund"
    account_type TEXT NOT NULL, -- e.g., "Checking", "Savings", "Credit"
    balance REAL DEFAULT 0.00,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- 3. Categories Table: Organizes transactions for budgeting
CREATE TABLE categories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL, -- e.g., "Groceries", "Rent", "Salary"
    type TEXT NOT NULL -- 'Income' or 'Expense'
);

-- 4. Transactions Table: The core ledger tracking money moving in and out
CREATE TABLE transactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    account_id INTEGER NOT NULL,
    category_id INTEGER NOT NULL,
    amount REAL NOT NULL,
    transaction_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    description TEXT,
    FOREIGN KEY (account_id) REFERENCES accounts(id),
    FOREIGN KEY (category_id) REFERENCES categories(id)
);

-- 5. Budgets Table: Sets monthly spending limits per category
CREATE TABLE budgets (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    category_id INTEGER NOT NULL,
    target_amount REAL NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (category_id) REFERENCES categories(id)
);

CREATE VIEW transaction_history AS
SELECT
    transactions.transaction_date,
    accounts.account_name,
    categories.name AS category,
    transactions.amount,
    transactions.description
FROM transactions
JOIN accounts ON transactions.account_id = accounts.id
JOIN categories ON transactions.category_id = categories.id;

CREATE VIEW spending_by_category AS
SELECT
    categories.name AS category,
    SUM(transactions.amount) AS total_spent
FROM transactions
JOIN categories ON transactions.category_id = categories.id
WHERE categories.type = 'Expense'
GROUP BY categories.name;

-- 1. Index for filtering by dates
CREATE INDEX idx_transactions_date ON transactions(transaction_date);

-- 2. Indexes for faster JOIN operations on the transactions table
CREATE INDEX idx_transactions_account_id ON transactions(account_id);
CREATE INDEX idx_transactions_category_id ON transactions(category_id);

-- 3. Index to quickly pull up a specific user's accounts
CREATE INDEX idx_accounts_user_id ON accounts(user_id);

-- 1. Create our dummy user
-- Since id is AUTOINCREMENT, we don't need to specify it. Jane will be id 1.
INSERT INTO users (first_name, last_name, email)
VALUES ('Jane', 'Doe', 'jane.doe@example.com');

-- 2. Set up Jane's bank accounts
-- Linking to user_id 1 (Jane). Notice the credit card has a negative balance to represent debt.
INSERT INTO accounts (user_id, account_name, account_type, balance)
VALUES
(1, 'Chase Checking', 'Checking', 2500.00),
(1, 'High Yield Savings', 'Savings', 10000.00),
(1, 'Rewards Credit Card', 'Credit', -450.50);

-- 3. Define our spending and income categories
-- These will be IDs 1, 2, 3, and 4 respectively.
INSERT INTO categories (name, type)
VALUES
('Salary', 'Income'),
('Groceries', 'Expense'),
('Rent', 'Expense'),
('Dining Out', 'Expense');

-- 4. Log some realistic transactions
-- Using negative amounts for expenses and positive for income.
INSERT INTO transactions (account_id, category_id, amount, transaction_date, description)
VALUES
(1, 1, 3000.00, '2026-04-01 09:00:00', 'April Paycheck'),               -- Income deposited to Checking
(1, 3, -1500.00, '2026-04-01 10:00:00', 'April Rent Payment'),          -- Rent paid from Checking
(3, 2, -120.50, '2026-04-02 14:30:00', 'Weekly Groceries'),             -- Groceries put on Credit Card
(3, 4, -45.00, '2026-04-02 19:00:00', 'Pizza Delivery');                -- Dinner put on Credit Card

-- 5. Establish monthly budgets for Jane
-- Setting limits for April 2026 for Groceries (category_id 2) and Dining Out (category_id 4)
INSERT INTO budgets (user_id, category_id, target_amount, start_date, end_date)
VALUES
(1, 2, 400.00, '2026-04-01', '2026-04-30'), -- $400 limit for Groceries
(1, 4, 150.00, '2026-04-01', '2026-04-30'); -- $150 limit for Dining Out
