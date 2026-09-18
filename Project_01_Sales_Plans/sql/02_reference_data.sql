USE PortfolioSalesPlans;
GO


/* ============================================================
   02_reference_data.sql

   Демонстрационные справочники для расчета плана.
   Все значения вымышлены.
   ============================================================ */


/* ============================================================
   1. Удаляем старые версии справочников
   ============================================================ */

DROP TABLE IF EXISTS dbo.ref_base_plan;
DROP TABLE IF EXISTS dbo.ref_tenure_coefficient;
DROP TABLE IF EXISTS dbo.ref_department_coefficient;
DROP TABLE IF EXISTS dbo.ref_absence_type;
GO


/* ============================================================
   2. Создаем справочники
   ============================================================ */


/* Базовый план в зависимости от должности */

CREATE TABLE dbo.ref_base_plan
(
    position_name VARCHAR(50),
    base_plan     DECIMAL(18,2)
);


/* Коэффициент в зависимости от стажа сотрудника */

CREATE TABLE dbo.ref_tenure_coefficient
(
    min_months   INT,
    max_months   INT,
    coefficient  DECIMAL(5,2)
);


/* Коэффициент подразделения */

CREATE TABLE dbo.ref_department_coefficient
(
    department   VARCHAR(50),
    coefficient  DECIMAL(5,2)
);


/* Какие виды отсутствий уменьшают план */

CREATE TABLE dbo.ref_absence_type
(
    absence_type        VARCHAR(50),
    affects_sales_plan  INT
);
GO


/* ============================================================
   3. Заполняем справочники
   ============================================================ */


/* Базовый план */

INSERT INTO dbo.ref_base_plan
(
    position_name,
    base_plan
)
VALUES
    ('Manager', 1000000),
    ('Leader',  1500000);


/* Коэффициент стажа */

INSERT INTO dbo.ref_tenure_coefficient
(
    min_months,
    max_months,
    coefficient
)
VALUES
    (0,  2,    0.50),
    (3,  5,    0.70),
    (6,  11,   0.85),
    (12, NULL, 1.00);


/* Коэффициент подразделения */

INSERT INTO dbo.ref_department_coefficient
(
    department,
    coefficient
)
VALUES
    ('Department 1', 1.00),
    ('Department 2', 1.10);


/* Виды отсутствий */

INSERT INTO dbo.ref_absence_type
(
    absence_type,
    affects_sales_plan
)
VALUES
    ('Vacation', 1),
    ('Sick',     1),
    ('Training', 0);
GO


/* ============================================================
   4. Проверяем данные
   ============================================================ */

SELECT *
FROM dbo.ref_base_plan;

SELECT *
FROM dbo.ref_tenure_coefficient;

SELECT *
FROM dbo.ref_department_coefficient;

SELECT *
FROM dbo.ref_absence_type;
GO
