# Relational Budget Tracker

## Scope

The purpose of this database is to provide a robust, relational backend for a personal finance management application. It allows users to track their financial health by logging transactions, organizing spending into distinct categories, monitoring account balances, and setting time-bound budgets.

The scope of this database includes:
* **Users:** Basic demographic information to distinguish between different individuals using the application.
* **Accounts:** Financial repositories (e.g., Checking, Savings, Credit Cards) belonging to a specific user.
* **Categories:** Classifications for cash flow, strictly divided into 'Income' or 'Expense'.
* **Transactions:** The core ledger tracking the movement of money in and out of accounts.
* **Budgets:** Target spending limits set for specific categories over a defined timeframe.

Out of scope for this database:
* **Investment Portfolio Tracking:** Real-time stock or cryptocurrency prices, dividend yields, and capital gains tracking are not supported.
* **Multi-Currency Conversion:** The database assumes a single fiat currency and does not track exchange rates.
* **Automatic Bank Syncing:** It relies on manual transaction entry or batch imports, rather than storing API credentials for Plaid or distinct financial institutions.
* **Complex Loan Amortization:** While credit card debt can be represented as a negative balance, the database does not calculate compound interest or loan maturity dates natively.

## Functional Requirements

A user interacting with this database should be able to:
* Register a new profile and create multiple financial accounts under their profile.
* Log income and expense transactions, tying them to specific accounts and categories.
* View a comprehensive, human-readable ledger of their transaction history.
* Calculate total net worth across all active accounts.
* Check their aggregate spending within a specific category against their designated budget for a given month.

Beyond the scope of what a user should be able to do:
* **Transaction Splitting:** A user cannot split a single transaction natively (e.g., logging a $100 Target receipt as $50 "Groceries" and $50 "Home Goods" requires two distinct `INSERT` statements).
* **Joint Accounts:** The current schema strictly ties one account to exactly one user. A user cannot share ownership of a checking account with a spouse in this iteration.

## Representation

### Entities

The database represents the following core entities:

**1. `users`**
* `id` (INTEGER): A surrogate primary key for unique identification.
* `first_name` (TEXT) & `last_name` (TEXT): Basic identifiers, marked `NOT NULL`.
* `email` (TEXT): Used for application login. Constrained with `UNIQUE` to prevent duplicate account creation and `NOT NULL`.

**2. `accounts`**
* `id` (INTEGER): Primary key.
* `user_id` (INTEGER): Foreign key referencing the `users` table.
* `account_name` (TEXT): e.g., "Chase Checking".
* `account_type` (TEXT): e.g., "Credit" or "Savings".
* `balance` (REAL): Used instead of INTEGER to accommodate standard currency decimals. Defaults to `0.00`.

**3. `categories`**
* `id` (INTEGER): Primary key.
* `name` (TEXT): e.g., "Groceries", "Rent".
* `type` (TEXT): Broad classification of either 'Income' or 'Expense'.

**4. `transactions`**
* `id` (INTEGER): Primary key.
* `account_id` (INTEGER): Foreign key referencing `accounts`.
* `category_id` (INTEGER): Foreign key referencing `categories`.
* `amount` (REAL): The transaction value. Negative floats represent expenses, positive floats represent income.
* `transaction_date` (DATETIME): Constrained with `DEFAULT CURRENT_TIMESTAMP` so the application doesn't strictly need to supply the time of entry.
* `description` (TEXT): Optional field for memo notes.

**5. `budgets`**
* `id` (INTEGER): Primary key.
* `user_id` (INTEGER): Foreign key referencing `users`.
* `category_id` (INTEGER): Foreign key referencing `categories`.
* `target_amount` (REAL): The spending limit.
* `start_date` (DATE) & `end_date` (DATE): Defines the temporal boundary of the budget (e.g., a single calendar month).

### Relationships

The database relies heavily on one-to-many relationships to maintain referential integrity:

* **Users to Accounts (1:N):** A user can own multiple bank accounts, but an account belongs to exactly one user.
* **Accounts to Transactions (1:N):** An account can have thousands of transactions, but a single transaction occurs in only one account.
* **Categories to Transactions (1:N):** A category like "Groceries" applies to many transactions, but a single transaction row maps to exactly one category.
* **Users to Budgets (1:N):** A user can set multiple budgets.
* **Categories to Budgets (1:N):** A category can have multiple budget targets set across different timeframes (e.g., April vs. May).

*(Include an image of your Entity Relationship Diagram here if you generated one!)*

## Optimizations

To ensure the database scales efficiently as a user's ledger grows, the following optimizations were implemented:

* **Views:** * `transaction_history`: Created to encapsulate a complex `JOIN` operation across `transactions`, `accounts`, and `categories`. This abstracts away relational complexity for the front-end application, allowing it to simply `SELECT * FROM transaction_history`.
  * `spending_by_category`: Uses the `SUM()` aggregate function and `GROUP BY` to dynamically calculate expense totals, heavily optimizing the process of checking budget utilization.
* **Indexes:**
  * `idx_transactions_date`: Since personal finance relies heavily on temporal filtering (e.g., "show spending for Q1"), indexing `transaction_date` prevents full table scans.
  * `idx_transactions_account_id` & `idx_transactions_category_id`: Because the `transactions` table serves as a junction linking multiple entities, indexing its foreign keys drastically reduces execution time for `JOIN` statements.
  * `idx_accounts_user_id`: Optimizes the `WHERE` clause when fetching a specific user's dashboard upon application login.

## Limitations

The current schema has a few limitations due to its design:
* **Balance Synchronization:** The `balance` column in the `accounts` table is decoupled from the sum of the `transactions` table. If a transaction is added or deleted, the `balance` does not update automatically. To prevent data anomalies, this design relies heavily on application-level logic or future implementation of SQL `TRIGGERS` to ensure the stored balance perfectly matches the transaction ledger.
* **Lack of Sub-Categories:** Categories are completely flat. A user cannot nest "Coffee" and "Fast Food" under a broader "Dining" umbrella.
* **Timezones:** The `CURRENT_TIMESTAMP` relies on the database server's internal clock (typically UTC). If users are distributed globally, the schema lacks a dedicated timezone offset column, which could lead to transactions appearing on the wrong calendar day for a user in a vastly different timezone.
