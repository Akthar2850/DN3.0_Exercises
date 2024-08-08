-- Enable server output
SET SERVEROUTPUT ON;

-- Create tables for the system
CREATE TABLE CustomerDetails (
    CustomerID INT PRIMARY KEY,
    FullName VARCHAR2(100),
    DateOfBirth DATE,
    AccountBalance INT,
    LastUpdated DATE,
    VIPStatus CHAR(1)
);

CREATE TABLE AccountDetails (
    AccountID INT PRIMARY KEY,
    CustomerID INT,
    TypeOfAccount VARCHAR2(20),
    AccountBalance INT,
    LastUpdated DATE,
    FOREIGN KEY (CustomerID) REFERENCES CustomerDetails(CustomerID)
);

CREATE TABLE AccountTransactions (
    TransactionID INT PRIMARY KEY,
    AccountID INT,
    DateOfTransaction DATE,
    TransactionAmount INT,
    TypeOfTransaction VARCHAR2(10),
    FOREIGN KEY (AccountID) REFERENCES AccountDetails(AccountID)
);

CREATE TABLE LoanDetails (
    LoanID INT PRIMARY KEY,
    CustomerID INT,
    PrincipalAmount INT,
    RateOfInterest INT,
    LoanStartDate DATE,
    LoanEndDate DATE,
    FOREIGN KEY (CustomerID) REFERENCES CustomerDetails(CustomerID)
);

CREATE TABLE Staff (
    EmployeeID INT PRIMARY KEY,
    FullName VARCHAR2(100),
    JobTitle VARCHAR2(50),
    MonthlySalary INT,
    DepartmentName VARCHAR2(50),
    DepartmentID INT,
    DateOfHire DATE
);

-- Create a table for logging errors
CREATE TABLE ErrorRecords (
    ErrorID INT PRIMARY KEY,
    ErrorDescription VARCHAR2(255),
    DateOfError DATE
);

-- Sample data insertion into tables
INSERT INTO CustomerDetails (CustomerID, FullName, DateOfBirth, AccountBalance, LastUpdated)
VALUES (1, 'John Doe', TO_DATE('1963-05-15', 'YYYY-MM-DD'), 1000, SYSDATE);

INSERT INTO CustomerDetails (CustomerID, FullName, DateOfBirth, AccountBalance, LastUpdated)
VALUES (2, 'Jane Smith', TO_DATE('1990-07-20', 'YYYY-MM-DD'), 1500, SYSDATE);

INSERT INTO AccountDetails (AccountID, CustomerID, TypeOfAccount, AccountBalance, LastUpdated)
VALUES (1, 1, 'Savings', 1000, SYSDATE);

INSERT INTO AccountDetails (AccountID, CustomerID, TypeOfAccount, AccountBalance, LastUpdated)
VALUES (2, 2, 'Checking', 1500, SYSDATE);

INSERT INTO AccountTransactions (TransactionID, AccountID, DateOfTransaction, TransactionAmount, TypeOfTransaction)
VALUES (1, 1, SYSDATE, 200, 'Deposit');

INSERT INTO AccountTransactions (TransactionID, AccountID, DateOfTransaction, TransactionAmount, TypeOfTransaction)
VALUES (2, 2, SYSDATE, 300, 'Withdrawal');

INSERT INTO LoanDetails (LoanID, CustomerID, PrincipalAmount, RateOfInterest, LoanStartDate, LoanEndDate)
VALUES (1, 1, 5000, 5, SYSDATE, ADD_MONTHS(SYSDATE, 60));

INSERT INTO LoanDetails (LoanID, CustomerID, PrincipalAmount, RateOfInterest, LoanStartDate, LoanEndDate)
VALUES (2, 2, 10000, 5, SYSDATE, SYSDATE+25);

INSERT INTO Staff (EmployeeID, FullName, JobTitle, MonthlySalary, DepartmentName, DateOfHire)
VALUES (1, 'Alice Johnson', 'Manager', 70000, 'HR', TO_DATE('2015-06-15', 'YYYY-MM-DD'));

INSERT INTO Staff (EmployeeID, FullName, JobTitle, MonthlySalary, DepartmentName, DateOfHire)
VALUES (2, 'Bob Brown', 'Developer', 60000, 'IT', TO_DATE('2017-03-20', 'YYYY-MM-DD'));

-- SCENARIO - 1
-- Procedure to Calculate Monthly Interest for Savings Accounts
CREATE OR REPLACE PROCEDURE ApplyMonthlyInterest IS
    -- Variable to store the count of affected rows
    affectedRows NUMBER;
BEGIN
    -- Increase balance for all savings accounts by 1% interest
    UPDATE AccountDetails
    SET AccountBalance = AccountBalance * 1.01
    WHERE TypeOfAccount = 'Savings';

    -- Retrieve the number of rows affected
    affectedRows := SQL%ROWCOUNT;

    -- Display the count of updated rows
    DBMS_OUTPUT.PUT_LINE('Updated account count: ' || affectedRows);
END ApplyMonthlyInterest;
/

-- SCENARIO - 2
-- Procedure to Adjust Bonus for Employees Based on Department
CREATE OR REPLACE PROCEDURE AdjustEmployeeBonus(
    deptID IN INT,
    bonusRate IN DECIMAL
) IS
BEGIN
    -- Increase salary for employees in the given department by the specified bonus rate
    UPDATE Staff
    SET MonthlySalary = MonthlySalary + (MonthlySalary * (bonusRate / 100))
    WHERE DepartmentID = deptID;
END AdjustEmployeeBonus;
/

-- SCENARIO - 3
-- Procedure for Transferring Funds Between Accounts
CREATE OR REPLACE PROCEDURE TransferFundsBetweenAccounts(
    sourceAccountID IN INT,
    destinationAccountID IN INT,
    transferAmount IN DECIMAL
) IS
BEGIN
    DECLARE
        insufficientBalance EXCEPTION;
        PRAGMA EXCEPTION_INIT(insufficientBalance, -20001);

    BEGIN
        -- Start transaction
        SAVEPOINT transferStart;

        -- Check if the source account has sufficient funds
        DECLARE
            sourceBalance INT;
        BEGIN
            SELECT AccountBalance INTO sourceBalance
            FROM AccountDetails
            WHERE AccountID = sourceAccountID;
            
            IF sourceBalance < transferAmount THEN
                RAISE insufficientBalance;
            END IF;
        END;

        -- Deduct the amount from the source account
        UPDATE AccountDetails
        SET AccountBalance = AccountBalance - transferAmount
        WHERE AccountID = sourceAccountID;

        -- Add the amount to the destination account
        UPDATE AccountDetails
        SET AccountBalance = AccountBalance + transferAmount
        WHERE AccountID = destinationAccountID;

        -- Commit the transaction
        COMMIT;
    EXCEPTION
        WHEN insufficientBalance THEN
            INSERT INTO ErrorRecords (ErrorDescription, DateOfError)
            VALUES ('Insufficient funds for transfer from AccountID: ' || sourceAccountID, SYSDATE);
            ROLLBACK TO transferStart;
        WHEN OTHERS THEN
            INSERT INTO ErrorRecords (ErrorDescription, DateOfError)
            VALUES ('Error occurred during fund transfer from AccountID: ' || sourceAccountID || ' to AccountID: ' || destinationAccountID, SYSDATE);
            ROLLBACK TO transferStart;
    END;
END TransferFundsBetweenAccounts;
/

-- Example procedure calls
BEGIN
    ApplyMonthlyInterest;
END;
/

BEGIN
    AdjustEmployeeBonus(1, 10.00);
END;
/

BEGIN
    TransferFundsBetweenAccounts(1, 2, 100.00);
END;
/ 
