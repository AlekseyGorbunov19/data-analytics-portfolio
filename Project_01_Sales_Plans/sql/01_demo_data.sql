USE PortfolioSalesPlans;
GO

DROP TABLE IF EXISTS dbo.demo_absences;
DROP TABLE IF EXISTS dbo.demo_calendar;
DROP TABLE IF EXISTS dbo.demo_employees;
GO


CREATE TABLE dbo.demo_employees
(
    employee_id     INT,
    employee_name   VARCHAR(100),
    position_name   VARCHAR(50),
    department      VARCHAR(50),
    hire_date       DATE,
    dismissal_date  DATE
);

CREATE TABLE dbo.demo_absences
(
    employee_id   INT,
    absence_type  VARCHAR(50),
    date_from     DATE,
    date_to       DATE
);

CREATE TABLE dbo.demo_calendar
(
    calendar_date   DATE,
    is_working_day  INT
);
GO


INSERT INTO dbo.demo_employees
(
    employee_id,
    employee_name,
    position_name,
    department,
    hire_date,
    dismissal_date
)
VALUES
    (1, 'Employee 01', 'Manager', 'Department 1', '2024-03-15', NULL),
    (2, 'Employee 02', 'Manager', 'Department 1', '2023-08-01', NULL),
    (3, 'Employee 03', 'Leader',  'Department 1', '2022-05-10', '2026-02-16'),
    (4, 'Employee 04', 'Manager', 'Department 2', '2025-06-20', NULL),
    (5, 'Employee 05', 'Leader',  'Department 2', '2021-11-01', NULL);


INSERT INTO dbo.demo_absences
(
    employee_id,
    absence_type,
    date_from,
    date_to
)
VALUES
    (1, 'Vacation', '2026-01-20', '2026-02-10'),
    (2, 'Sick',     '2026-02-09', '2026-02-13'),
    (4, 'Vacation', '2026-02-16', '2026-02-20');


INSERT INTO dbo.demo_calendar
(
    calendar_date,
    is_working_day
)
VALUES
    ('2026-02-01', 0),
    ('2026-02-02', 1),
    ('2026-02-03', 1),
    ('2026-02-04', 1),
    ('2026-02-05', 1),
    ('2026-02-06', 1),
    ('2026-02-07', 0),
    ('2026-02-08', 0),
    ('2026-02-09', 1),
    ('2026-02-10', 1),
    ('2026-02-11', 1),
    ('2026-02-12', 1),
    ('2026-02-13', 1),
    ('2026-02-14', 0),
    ('2026-02-15', 0),
    ('2026-02-16', 1),
    ('2026-02-17', 1),
    ('2026-02-18', 1),
    ('2026-02-19', 1),
    ('2026-02-20', 1),
    ('2026-02-21', 0),
    ('2026-02-22', 0),
    ('2026-02-23', 1),
    ('2026-02-24', 1),
    ('2026-02-25', 1),
    ('2026-02-26', 1),
    ('2026-02-27', 1),
    ('2026-02-28', 0);
GO


SELECT *
FROM dbo.demo_employees;

SELECT *
FROM dbo.demo_absences;

SELECT *
FROM dbo.demo_calendar
ORDER BY calendar_date;
GO
