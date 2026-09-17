/*
    Project: Sales Plan Calculation
    File: 01_demo_data.sql

    Демонстрационные данные для портфолио.
    Все сотрудники, подразделения и значения являются вымышленными.
*/

-- =========================================================
-- 1. Сотрудники
-- =========================================================

CREATE TABLE demo_employees (
    employee_id     INT PRIMARY KEY,
    employee_name   NVARCHAR(100),
    department      NVARCHAR(100),
    position_name   NVARCHAR(100),
    hire_date       DATE,
    dismissal_date  DATE NULL
);

INSERT INTO demo_employees
(
    employee_id,
    employee_name,
    department,
    position_name,
    hire_date,
    dismissal_date
)
VALUES
(1, N'Сотрудник 001', N'Отдел продаж 1', N'Менеджер',     '2024-03-15', NULL),
(2, N'Сотрудник 002', N'Отдел продаж 1', N'Менеджер',     '2023-08-01', NULL),
(3, N'Сотрудник 003', N'Отдел продаж 1', N'Руководитель', '2022-05-10', '2026-02-16'),
(4, N'Сотрудник 004', N'Отдел продаж 2', N'Менеджер',     '2025-06-20', NULL),
(5, N'Сотрудник 005', N'Отдел продаж 2', N'Руководитель', '2021-11-01', NULL);


-- =========================================================
-- 2. Периоды отсутствия
-- =========================================================

CREATE TABLE demo_absences (
    absence_id      INT PRIMARY KEY,
    employee_id     INT,
    absence_type    NVARCHAR(50),
    absence_start   DATE,
    absence_end     DATE
);

INSERT INTO demo_absences
(
    absence_id,
    employee_id,
    absence_type,
    absence_start,
    absence_end
)
VALUES
(1, 1, N'Отпуск',     '2026-01-20', '2026-02-10'),
(2, 2, N'Больничный', '2026-02-09', '2026-02-13'),
(3, 4, N'Отпуск',     '2026-02-16', '2026-02-20');


-- =========================================================
-- 3. Производственный календарь
-- =========================================================

CREATE TABLE demo_calendar (
    calendar_date   DATE PRIMARY KEY,
    is_working_day  BIT
);

DECLARE @date DATE = '2026-01-01';

WHILE @date <= '2026-03-31'
BEGIN

    INSERT INTO demo_calendar
    (
        calendar_date,
        is_working_day
    )
    VALUES
    (
        @date,
        CASE
            WHEN DATEPART(WEEKDAY, @date) IN (1, 7)
                THEN 0
            ELSE 1
        END
    );

    SET @date = DATEADD(DAY, 1, @date);

END;


/*
    В реальном проекте производственный календарь
    является отдельным источником данных и учитывает
    официальные рабочие и нерабочие дни.
*/
