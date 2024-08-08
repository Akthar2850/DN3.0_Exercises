-- Enable server output to display messages
SET SERVEROUTPUT ON;

-- Create tables to store customer, account, transaction, loan, and employee details
CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY,
    Name VARCHAR2(100),
    DOB DATE,
    Balance INT,
    LastModified DATE,
    IsVIP CHAR(1)
);

CREATE TABLE Accounts (
    AccountID INT PRIMARY KEY,
    CustomerID INT,
    AccountType VARCHAR2(20),
    Balance INT,
    LastModified DATE,
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);

CREATE TABLE Transactions (
    TransactionID INT PRIMARY KEY,
    AccountID INT,
    TransactionDate DATE,
    Amount INT,
    TransactionType VARCHAR2(10),
    FOREIGN KEY (AccountID) REFERENCES Accounts(AccountID)
);

CREATE TABLE Loans (
    LoanID INT PRIMARY KEY,
    CustomerID INT,
    LoanAmount INT,
    InterestRate INT,
    StartDate DATE,
    EndDate DATE,
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);

CREATE TABLE Employees (
    EmployeeID INT PRIMARY KEY,
    Name VARCHAR2(100),
    Position VARCHAR2(50),
    Salary INT,
    Department VARCHAR2(50),
    DepartmentID INT,
    HireDate DATE
);

-- Create a table to log errors
CREATE TABLE ErrorLogs (
    ErrorID INT PRIMARY KEY,
    ErrorMessage VARCHAR2(255),
    ErrorDate DATE
);

-- Insert sample data into Customers table
INSERT INTO Customers (CustomerID, Name, DOB, Balance, LastModified)
VALUES (1, 'John Doe', TO_DATE('1963-05-15', 'YYYY-MM-DD'), 1000, SYSDATE);

INSERT INTO Customers (CustomerID, Name, DOB, Balance, LastModified)
VALUES (2, 'Jane Smith', TO_DATE('1990-07-20', 'YYYY-MM-DD'), 1500, SYSDATE);

-- Insert sample data into Accounts table
INSERT INTO Accounts (AccountID, CustomerID, AccountType, Balance, LastModified)
VALUES (1, 1, 'Savings', 1000, SYSDATE);

INSERT INTO Accounts (AccountID, CustomerID, AccountType, Balance, LastModified)
VALUES (2, 2, 'Checking', 1500, SYSDATE);

-- Insert sample data into Transactions table
INSERT INTO Transactions (TransactionID, AccountID, TransactionDate, Amount, TransactionType)
VALUES (1, 1, SYSDATE, 200, 'Deposit');

INSERT INTO Transactions (TransactionID, AccountID, TransactionDate, Amount, TransactionType)
VALUES (2, 2, SYSDATE, 300, 'Withdrawal');

-- Insert sample data into Loans table
INSERT INTO Loans (LoanID, CustomerID, LoanAmount, InterestRate, StartDate, EndDate)
VALUES (1, 1, 5000, 5, SYSDATE, ADD_MONTHS(SYSDATE, 60));

INSERT INTO Loans (LoanID, CustomerID, LoanAmount, InterestRate, StartDate, EndDate)
VALUES (2, 2, 10000, 5, SYSDATE, SYSDATE + 25);

-- Insert sample data into Employees table
INSERT INTO Employees (EmployeeID, Name, Position, Salary, Department, HireDate)
VALUES (1, 'Alice Johnson', 'Manager', 70000, 'HR', TO_DATE('2015-06-15', 'YYYY-MM-DD'));

INSERT INTO Employees (EmployeeID, Name, Position, Salary, Department, HireDate)
VALUES (2, 'Bob Brown', 'Developer', 60000, 'IT', TO_DATE('2017-03-20', 'YYYY-MM-DD'));

-- Procedure to generate monthly statements for all customers
CREATE OR REPLACE PROCEDURE GenerateMonthlyStatements AS
    CURSOR c_monthly_statements IS
        SELECT a.CustomerID, t.TransactionDate, t.Amount
        FROM Transactions t
        JOIN Accounts a ON t.AccountID = a.AccountID
        WHERE EXTRACT(MONTH FROM t.TransactionDate) = EXTRACT(MONTH FROM SYSDATE)
          AND EXTRACT(YEAR FROM t.TransactionDate) = EXTRACT(YEAR FROM SYSDATE);
          
    v_customer_id INT;
    v_transaction_date DATE;
    v_amount DECIMAL(10, 2);
BEGIN
    FOR r_monthly_statement IN c_monthly_statements LOOP
        v_customer_id := r_monthly_statement.CustomerID;
        v_transaction_date := r_monthly_statement.TransactionDate;
        v_amount := r_monthly_statement.Amount;
        
        DBMS_OUTPUT.PUT_LINE('CustomerID: ' || v_customer_id || 
                             ', Date: ' || v_transaction_date || 
                             ', Amount: ' || v_amount);
    END LOOP;
END;
/

-- Procedure to apply an annual fee to all accounts
CREATE OR REPLACE PROCEDURE ApplyAnnualFee AS
    CURSOR c_accounts IS
        SELECT AccountID, Balance
        FROM Accounts;

    v_account_id INT;
    v_balance DECIMAL(10, 2);
    v_annual_fee DECIMAL(10, 2) := 50.00;
BEGIN
    FOR r_account IN c_accounts LOOP
        v_account_id := r_account.AccountID;
        v_balance := r_account.Balance;

        UPDATE Accounts
        SET Balance = v_balance - v_annual_fee
        WHERE AccountID = v_account_id;

        DBMS_OUTPUT.PUT_LINE('AccountID: ' || v_account_id || ' - Annual fee applied.');
    END LOOP;
END;
/

-- Procedure to update interest rates for loans based on new policy
CREATE OR REPLACE PROCEDURE UpdateLoanInterestRates AS
    CURSOR c_loans IS
        SELECT LoanID, InterestRate
        FROM Loans;

    v_loan_id INT;
    v_interest_rate DECIMAL(5, 2);
    v_new_interest_rate DECIMAL(5, 2);
BEGIN
    FOR r_loan IN c_loans LOOP
        v_loan_id := r_loan.LoanID;
        v_interest_rate := r_loan.InterestRate;

        v_new_interest_rate := v_interest_rate * 1.05;  -- Increase by 5%

        UPDATE Loans
        SET InterestRate = v_new_interest_rate
        WHERE LoanID = v_loan_id;

        DBMS_OUTPUT.PUT_LINE('LoanID: ' || v_loan_id || ' - Updated interest rate to: ' || v_new_interest_rate);
    END LOOP;
END;
/

-- Execute the procedures
BEGIN
    GenerateMonthlyStatements;
END;
/

BEGIN
    ApplyAnnualFee;
END;
/

BEGIN
    UpdateLoanInterestRates;
END;
/
