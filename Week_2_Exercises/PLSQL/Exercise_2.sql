-- Enable server output for debugging
SET SERVEROUTPUT ON;

-- Create tables for the system
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
    HireDate DATE
);

-- Create table to log errors
CREATE TABLE ErrorLogs (
    ErrorID INT PRIMARY KEY,
    ErrorMessage VARCHAR2(255),
    ErrorDate DATE
);

-- Insert initial data into tables
INSERT INTO Customers (CustomerID, Name, DOB, Balance, LastModified)
VALUES (1, 'John Doe', TO_DATE('1985-05-15', 'YYYY-MM-DD'), 1000, SYSDATE);

INSERT INTO Customers (CustomerID, Name, DOB, Balance, LastModified)
VALUES (2, 'Jane Smith', TO_DATE('1990-07-20', 'YYYY-MM-DD'), 1500, SYSDATE);

INSERT INTO Accounts (AccountID, CustomerID, AccountType, Balance, LastModified)
VALUES (1, 1, 'Savings', 1000, SYSDATE);

INSERT INTO Accounts (AccountID, CustomerID, AccountType, Balance, LastModified)
VALUES (2, 2, 'Checking', 1500, SYSDATE);

INSERT INTO Transactions (TransactionID, AccountID, TransactionDate, Amount, TransactionType)
VALUES (1, 1, SYSDATE, 200, 'Deposit');

INSERT INTO Transactions (TransactionID, AccountID, TransactionDate, Amount, TransactionType)
VALUES (2, 2, SYSDATE, 300, 'Withdrawal');

INSERT INTO Loans (LoanID, CustomerID, LoanAmount, InterestRate, StartDate, EndDate)
VALUES (1, 1, 5000, 5, SYSDATE, ADD_MONTHS(SYSDATE, 60));

INSERT INTO Employees (EmployeeID, Name, Position, Salary, Department, HireDate)
VALUES (1, 'Alice Johnson', 'Manager', 70000, 'HR', TO_DATE('2015-06-15', 'YYYY-MM-DD'));

INSERT INTO Employees (EmployeeID, Name, Position, Salary, Department, HireDate)
VALUES (2, 'Bob Brown', 'Developer', 60000, 'IT', TO_DATE('2017-03-20', 'YYYY-MM-DD'));

-- Procedure to Adjust Interest Rates for Senior Customers
CREATE OR REPLACE PROCEDURE AdjustInterestRates IS
    CURSOR customer_cursor IS
        SELECT CustomerID, DOB FROM Customers;
    
    customer_id Customers.CustomerID%TYPE;
    customer_dob Customers.DOB%TYPE;
    today DATE := SYSDATE;
BEGIN
    FOR customer_record IN customer_cursor LOOP
        IF MONTHS_BETWEEN(today, customer_record.DOB) / 12 > 60 THEN
            UPDATE Loans
            SET InterestRate = InterestRate * 0.99
            WHERE CustomerID = customer_record.CustomerID;
        END IF;
    END LOOP;
END AdjustInterestRates;
/

-- Procedure to Update VIP Status Based on Account Balance
CREATE OR REPLACE PROCEDURE UpdateVIPStatus IS
    CURSOR account_cursor IS
        SELECT CustomerID, Balance FROM Accounts;
    
    account_id Accounts.CustomerID%TYPE;
    account_balance Accounts.Balance%TYPE;
BEGIN
    FOR account_record IN account_cursor LOOP
        IF account_record.Balance > 10000 THEN
            UPDATE Customers
            SET IsVIP = 'Y'
            WHERE CustomerID = account_record.CustomerID;
        ELSE
            UPDATE Customers
            SET IsVIP = 'N'
            WHERE CustomerID = account_record.CustomerID;
        END IF;
    END LOOP;
END UpdateVIPStatus;
/

-- Procedure to Issue Loan Due Reminders
CREATE OR REPLACE PROCEDURE IssueLoanReminders IS
    CURSOR loan_cursor IS
        SELECT CustomerID, EndDate 
        FROM Loans 
        WHERE EndDate BETWEEN SYSDATE AND SYSDATE + 30;
    
    loan_customer_id Loans.CustomerID%TYPE;
    loan_end_date Loans.EndDate%TYPE;
BEGIN
    FOR loan_record IN loan_cursor LOOP
        DBMS_OUTPUT.PUT_LINE('Reminder: Loan due on ' || TO_CHAR(loan_record.EndDate, 'YYYY-MM-DD') || ' for CustomerID: ' || loan_record.CustomerID);
    END LOOP;
END IssueLoanReminders;
/

-- Procedure for Secure Fund Transfers Between Accounts
CREATE OR REPLACE PROCEDURE TransferFunds(
    fromAccountID IN INT,
    toAccountID IN INT,
    amount IN DECIMAL
) IS
BEGIN
    DECLARE
        insufficientFunds EXCEPTION;
        PRAGMA EXCEPTION_INIT(insufficientFunds, -20001);

    BEGIN
        -- Begin transaction
        SAVEPOINT transfer_start;

        -- Verify sufficient balance in source account
        DECLARE
            source_balance INT;
        BEGIN
            SELECT Balance INTO source_balance
            FROM Accounts
            WHERE AccountID = fromAccountID;
            
            IF source_balance < amount THEN
                DBMS_OUTPUT.PUT_LINE('Insufficient Funds');
                RAISE insufficientFunds;
            END IF;
        END;

        -- Deduct amount from source account
        UPDATE Accounts
        SET Balance = Balance - amount
        WHERE AccountID = fromAccountID;

        -- Credit amount to target account
        UPDATE Accounts
        SET Balance = Balance + amount
        WHERE AccountID = toAccountID;
        DBMS_OUTPUT.PUT_LINE('Funds transferred successfully.');
        -- Commit transaction
        COMMIT;
    EXCEPTION
        WHEN insufficientFunds THEN
            INSERT INTO ErrorLogs (ErrorMessage, ErrorDate)
            VALUES ('Insufficient funds for transfer from AccountID: ' || fromAccountID, SYSDATE);
            ROLLBACK TO transfer_start;
        WHEN OTHERS THEN
            INSERT INTO ErrorLogs (ErrorMessage, ErrorDate)
            VALUES ('SQL Error during transfer from AccountID: ' || fromAccountID || ' to AccountID: ' || toAccountID, SYSDATE);
            ROLLBACK TO transfer_start;
    END;
END TransferFunds;
/

-- Procedure to Update Employee Salaries
CREATE OR REPLACE PROCEDURE IncreaseSalary(
    empID IN INT,
    increasePercentage IN DECIMAL
) IS
BEGIN
    DECLARE
        employeeNotFound EXCEPTION;
        PRAGMA EXCEPTION_INIT(employeeNotFound, -20001);

    BEGIN
        -- Begin transaction
        SAVEPOINT salary_update;

        -- Update employee salary
        UPDATE Employees 
        SET Salary = Salary + (Salary * (increasePercentage / 100))
        WHERE EmployeeID = empID;
        DBMS_OUTPUT.PUT_LINE('Salary increased by ' || increasePercentage || '%');
        -- Verify if update was successful
        IF SQL%ROWCOUNT = 0 THEN
            RAISE employeeNotFound;
        END IF;
        
        -- Commit transaction
        COMMIT;
    EXCEPTION
        WHEN employeeNotFound THEN
            INSERT INTO ErrorLogs (ErrorMessage, ErrorDate)
            VALUES ('Employee ID does not exist: ' || empID, SYSDATE);
            DBMS_OUTPUT.PUT_LINE('Employee ID does not exist!');
            ROLLBACK TO salary_update;
        WHEN OTHERS THEN
            INSERT INTO ErrorLogs (ErrorMessage, ErrorDate)
            VALUES ('Error updating salary for EmployeeID: ' || empID, SYSDATE);
            ROLLBACK TO salary_update;
    END;
END IncreaseSalary;
/

-- Procedure to Add a New Customer with Validation
CREATE OR REPLACE PROCEDURE RegisterCustomer(
    CusID IN NUMBER,
    CusName IN VARCHAR2,
    CusDOB IN DATE,
    CusBalance IN NUMBER,
    CusLastModified IN DATE
)
IS
  DuplicateCustomerID EXCEPTION;
  existingCustomerCount NUMBER;
BEGIN
  SELECT COUNT(*) INTO existingCustomerCount FROM Customers WHERE CustomerID = CusID;
  
  IF existingCustomerCount > 0 THEN
    RAISE DuplicateCustomerID;
  END IF;
  
  INSERT INTO Customers (CustomerID, Name, DOB, Balance, LastModified)
  VALUES (CusID, CusName, CusDOB, CusBalance, CusLastModified);
  
  DBMS_OUTPUT.PUT_LINE('Customer added successfully.');
  
EXCEPTION
  WHEN DuplicateCustomerID THEN
    DBMS_OUTPUT.PUT_LINE('Customer ID already exists.');
END;
/


-- Execute the procedures
BEGIN
    AdjustInterestRates;
END;
/

BEGIN
    UpdateVIPStatus;
END;
/

BEGIN
    IssueLoanReminders;
END;
/

-- Examples of calling procedures for fund transfers, salary updates, and customer registration
BEGIN
    TransferFunds(1, 2, 100.00);
END;
/

BEGIN
    IncreaseSalary(1, 10.00);
END;
/

BEGIN
    RegisterCustomer(CusID => 1, CusName => 'Akthar', CusDOB => SYSDATE, CusBalance => 5000, CusLastModified => SYSDATE);
END;
/ 
