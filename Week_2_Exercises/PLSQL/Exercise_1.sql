BEGIN
  -- Create Customers table
  EXECUTE IMMEDIATE '
    CREATE TABLE Customers (
      CustomerID INT PRIMARY KEY,
      Name VARCHAR(100),
      DOB DATE,
      Balance INT,
      LastModified DATE,
      IsVIP NUMBER(1)
    )';

  -- Create Accounts table
  EXECUTE IMMEDIATE '
    CREATE TABLE Accounts (
      AccountID INT PRIMARY KEY,
      CustomerID INT,
      AccountType VARCHAR(20),
      Balance INT,
      LastModified DATE,
      FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
    )';

  -- Create Transactions table
  EXECUTE IMMEDIATE '
    CREATE TABLE Transactions (
      TransactionID INT PRIMARY KEY,
      AccountID INT,
      TransactionDate DATE,
      Amount INT,
      TransactionType VARCHAR(10),
      FOREIGN KEY (AccountID) REFERENCES Accounts(AccountID)
    )';

  -- Create Loans table
  EXECUTE IMMEDIATE '
    CREATE TABLE Loans (
      LoanID INT PRIMARY KEY,
      CustomerID INT,
      LoanAmount INT,
      InterestRate INT,
      StartDate DATE,
      EndDate DATE,
      FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
    )';

  -- Create Employees table
  EXECUTE IMMEDIATE '
    CREATE TABLE Employees (
      EmployeeID INT PRIMARY KEY,
      Name VARCHAR(100),
      Position VARCHAR(50),
      Salary INT,
      Department VARCHAR(50),
      HireDate DATE
    )';

  -- Insert data into Customers table
  EXECUTE IMMEDIATE '
    INSERT INTO Customers (CustomerID, Name, DOB, Balance, LastModified, IsVIP)
    VALUES (1, ''John Doe'', TO_DATE(''1985-05-15'', ''YYYY-MM-DD''), 1000, SYSDATE, 0)';

  EXECUTE IMMEDIATE '
    INSERT INTO Customers (CustomerID, Name, DOB, Balance, LastModified, IsVIP)
    VALUES (2, ''Jane Smith'', TO_DATE(''1990-07-20'', ''YYYY-MM-DD''), 1500, SYSDATE, 0)';

  -- Insert data into Accounts table
  EXECUTE IMMEDIATE '
    INSERT INTO Accounts (AccountID, CustomerID, AccountType, Balance, LastModified)
    VALUES (1, 1, ''Savings'', 1000, SYSDATE)';

  EXECUTE IMMEDIATE '
    INSERT INTO Accounts (AccountID, CustomerID, AccountType, Balance, LastModified)
    VALUES (2, 2, ''Checking'', 1500, SYSDATE)';

  -- Insert data into Transactions table
  EXECUTE IMMEDIATE '
    INSERT INTO Transactions (TransactionID, AccountID, TransactionDate, Amount, TransactionType)
    VALUES (1, 1, SYSDATE, 200, ''Deposit'')';

  EXECUTE IMMEDIATE '
    INSERT INTO Transactions (TransactionID, AccountID, TransactionDate, Amount, TransactionType)
    VALUES (2, 2, SYSDATE, 300, ''Withdrawal'')';

  -- Insert data into Loans table
  EXECUTE IMMEDIATE '
    INSERT INTO Loans (LoanID, CustomerID, LoanAmount, InterestRate, StartDate, EndDate)
    VALUES (1, 1, 5000, 5, SYSDATE, ADD_MONTHS(SYSDATE, 60))';

  -- Insert data into Employees table
  EXECUTE IMMEDIATE '
    INSERT INTO Employees (EmployeeID, Name, Position, Salary, Department, HireDate)
    VALUES (1, ''Alice Johnson'', ''Manager'', 70000, ''HR'', TO_DATE(''2015-06-15'', ''YYYY-MM-DD''))';

  EXECUTE IMMEDIATE '
    INSERT INTO Employees (EmployeeID, Name, Position, Salary, Department, HireDate)
    VALUES (2, ''Bob Brown'', ''Developer'', 60000, ''IT'', TO_DATE(''2017-03-20'', ''YYYY-MM-DD''))';

  DBMS_OUTPUT.PUT_LINE('Tables created and data inserted successfully.');
END;
/

-- Procedure to Apply Interest Discount to Customers Above 60 Years Old
CREATE OR REPLACE PROCEDURE ApplyInterestDiscount IS
    CURSOR cur IS SELECT CustomerID, DOB FROM Customers;
    cur_CustomerID Customers.CustomerID%TYPE;
    cur_DOB Customers.DOB%TYPE;
    currentDATE DATE := SYSDATE;
BEGIN
    FOR rec IN cur LOOP
        IF EXTRACT(YEAR FROM currentDATE) - EXTRACT(YEAR FROM rec.DOB) > 60 THEN
            UPDATE Loans
            SET InterestRate = InterestRate * 0.99
            WHERE CustomerID = rec.CustomerID;
            DBMS_OUTPUT.PUT_LINE('Applied interest discount for CustomerID: ' || rec.CustomerID);
        END IF;
    END LOOP;
END ApplyInterestDiscount;
/

-- Procedure to Promote Customers to VIP Status Based on Balance
CREATE OR REPLACE PROCEDURE PromoteToVIP IS
    CURSOR cur IS SELECT CustomerID, Balance FROM Accounts;
    cur_CustomerID Accounts.CustomerID%TYPE;
    cur_Balance Accounts.Balance%TYPE;
BEGIN
    FOR rec IN cur LOOP
        IF rec.Balance > 10000 THEN
            UPDATE Customers
            SET IsVIP = 1
            WHERE CustomerID = rec.CustomerID;
            DBMS_OUTPUT.PUT_LINE('Promoted CustomerID: ' || rec.CustomerID || ' to VIP status.');
        END IF;
    END LOOP;
END PromoteToVIP;
/

-- Procedure to Send Loan Reminders for Loans Due Within the Next 30 Days
CREATE OR REPLACE PROCEDURE SendLoanReminders IS
    CURSOR cur IS SELECT CustomerID, EndDate FROM Loans WHERE EndDate BETWEEN SYSDATE AND SYSDATE + 30;
    cur_CustomerID Loans.CustomerID%TYPE;
    cur_EndDate Loans.EndDate%TYPE;
BEGIN
    FOR rec IN cur LOOP
        DBMS_OUTPUT.PUT_LINE('Reminder: Loan due on ' || rec.EndDate || ' for CustomerID: ' || rec.CustomerID);
    END LOOP;
END SendLoanReminders;
/

-- Execute the procedures
BEGIN
    DBMS_OUTPUT.PUT_LINE('Executing ApplyInterestDiscount procedure...');
    ApplyInterestDiscount;

    DBMS_OUTPUT.PUT_LINE('Executing PromoteToVIP procedure...');
    PromoteToVIP;

    DBMS_OUTPUT.PUT_LINE('Executing SendLoanReminders procedure...');
    SendLoanReminders;
END;
/
