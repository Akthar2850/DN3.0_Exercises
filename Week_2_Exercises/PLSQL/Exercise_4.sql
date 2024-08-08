-- Enable server output
SET SERVEROUTPUT ON;

-- Create tables
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

-- ErrorLogs table for capturing error details
CREATE TABLE ErrorLogs (
    ErrorID INT PRIMARY KEY,
    ErrorMessage VARCHAR2(255),
    ErrorDate DATE
);

-- Insert sample data into tables
INSERT INTO Customers (CustomerID, Name, DOB, Balance, LastModified)
VALUES (1, 'John Doe', TO_DATE('1963-05-15', 'YYYY-MM-DD'), 1000, SYSDATE);

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

INSERT INTO Loans (LoanID, CustomerID, LoanAmount, InterestRate, StartDate, EndDate)
VALUES (2, 2, 10000, 5, SYSDATE, SYSDATE+25);

INSERT INTO Employees (EmployeeID, Name, Position, Salary, Department, HireDate)
VALUES (1, 'Alice Johnson', 'Manager', 70000, 'HR', TO_DATE('2015-06-15', 'YYYY-MM-DD'));

INSERT INTO Employees (EmployeeID, Name, Position, Salary, Department, HireDate)
VALUES (2, 'Bob Brown', 'Developer', 60000, 'IT', TO_DATE('2017-03-20', 'YYYY-MM-DD'));

-- Function to Determine Customer's Age
CREATE OR REPLACE FUNCTION DetermineCustomerAge(dob DATE)
RETURN NUMBER
IS
    age NUMBER;
BEGIN
    -- Calculate age based on the provided date of birth
    SELECT FLOOR((SYSDATE - dob) / 365)
    INTO age
    FROM dual;

    RETURN age;
END DetermineCustomerAge;
/
SHOW ERRORS FUNCTION DetermineCustomerAge;

-- Function to Calculate Monthly Loan Payment
CREATE OR REPLACE FUNCTION ComputeMonthlyLoanPayment(
    loanAmount NUMBER,
    annualRate NUMBER,
    loanTermYears NUMBER
)
RETURN NUMBER
IS
    monthlyRate NUMBER;
    totalPayments NUMBER;
    installment NUMBER;
BEGIN
    -- Determine the monthly interest rate
    monthlyRate := annualRate / 100 / 12;

    -- Calculate the number of payments
    totalPayments := loanTermYears * 12;

    -- Compute the monthly payment using the formula
    installment := loanAmount * (monthlyRate * POWER(1 + monthlyRate, totalPayments)) / (POWER(1 + monthlyRate, totalPayments) - 1);

    RETURN installment;
END ComputeMonthlyLoanPayment;
/
SHOW ERRORS FUNCTION ComputeMonthlyLoanPayment;

-- Function to Verify Account Balance
CREATE OR REPLACE FUNCTION VerifyAccountBalance(
    accountID NUMBER,
    requiredAmount NUMBER
)
RETURN BOOLEAN
IS
    currentBalance NUMBER;
BEGIN
    -- Retrieve the current balance of the specified account
    SELECT Balance INTO currentBalance
    FROM Accounts
    WHERE AccountID = accountID AND ROWNUM = 1;

    -- Determine if the balance meets or exceeds the required amount
    IF currentBalance >= requiredAmount THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END VerifyAccountBalance;
/
SHOW ERRORS FUNCTION VerifyAccountBalance;

-- Anonymous block to test the functions
DECLARE
    customerAge NUMBER;
    monthlyPayment NUMBER;
    isBalanceSufficient BOOLEAN;
BEGIN
    -- Test DetermineCustomerAge function
    customerAge := DetermineCustomerAge(TO_DATE('1980-01-01', 'YYYY-MM-DD'));
    DBMS_OUTPUT.PUT_LINE('Customer Age: ' || customerAge);

    -- Test ComputeMonthlyLoanPayment function
    monthlyPayment := ComputeMonthlyLoanPayment(10000, 5, 10);
    DBMS_OUTPUT.PUT_LINE('Monthly Loan Payment: ' || monthlyPayment);

    -- Test VerifyAccountBalance function
    isBalanceSufficient := VerifyAccountBalance(1, 500);
    IF isBalanceSufficient THEN
        DBMS_OUTPUT.PUT_LINE('Balance Sufficient: TRUE');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Balance Sufficient: FALSE');
    END IF;
END;
/
