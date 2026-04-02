-- In this SQL file, write (and comment!) the typical SQL queries users will run on your database
-- Add a new user to the database
INSERT INTO users (first_name, last_name, email)
VALUES ('John', 'Smith', 'john.smith@example.com');

-- Create a new savings account for a specific user
INSERT INTO accounts (user_id, account_name, account_type, balance)
VALUES (1, 'Vacation Fund', 'Savings', 500.00);

-- Log a new expense transaction (e.g., buying a coffee on the Credit Card)
-- Assuming account_id 3 is the Credit Card and category_id 4 is Dining Out
INSERT INTO transactions (account_id, category_id, amount, description)
VALUES (3, 4, -5.50, 'Morning Coffee');

-- View the complete, readable transaction history using the view we created
SELECT * FROM transaction_history;

-- Find the total current balance (net worth) across all of a specific user's accounts
SELECT SUM(balance) AS total_net_worth
FROM accounts
WHERE user_id = 1;

-- Check budget progress: Calculate how much was spent on Groceries in April 2026
SELECT SUM(amount) AS total_spent_on_groceries
FROM transactions
JOIN categories ON transactions.category_id = categories.id
WHERE categories.name = 'Groceries'
  AND transaction_date >= '2026-04-01'
  AND transaction_date < '2026-05-01';

-- Identify the highest single expense a user has ever had
SELECT accounts.account_name, categories.name AS category, transactions.amount, transactions.description
FROM transactions
JOIN accounts ON transactions.account_id = accounts.id
JOIN categories ON transactions.category_id = categories.id
WHERE transactions.amount < 0
ORDER BY transactions.amount ASC
LIMIT 1;

-- Update the name of a specific category to be more descriptive
UPDATE categories
SET name = 'Dining & Takeout'
WHERE name = 'Dining Out';

-- Update a budget target amount (e.g., increasing the grocery budget due to inflation)
UPDATE budgets
SET target_amount = 500.00
WHERE user_id = 1 AND category_id = 2;

-- Delete a mistakenly entered transaction using its unique ID
DELETE FROM transactions
WHERE id = 5;

-- Remove an old, unused bank account that has a zero balance
DELETE FROM accounts
WHERE id = 2 AND balance = 0.00;
