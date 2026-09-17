/*
    Project: Sales Plan Calculation
    File: 02_reference_data.sql

    Демонстрационные справочники для расчёта планов продаж.

    Все коэффициенты и значения являются вымышленными
    и используются исключительно для демонстрации архитектуры решения.
*/


-- =========================================================
-- 1. Базовый план по должности
-- =========================================================

CREATE TABLE ref_base_plan (
    position_name   NVARCHAR(100),
    base_plan       DECIMAL(18,2)
);

INSERT INTO ref_base_plan
(
    position_name,
    base_plan
)
VALUES
(N'Менеджер',     1000000),
(N'Руководитель', 1500000);


-- =========================================================
-- 2. Коэффициент по стажу сотрудника
-- =========================================================

CREATE TABLE ref_tenure_coefficient (
    min_months     INT,
    max_months     INT,
    coefficient    DECIMAL(5,2)
);

INSERT INTO ref_tenure_coefficient
(
    min_months,
    max_months,
    coefficient
)
VALUES
(0,  2,    0.50),
(3,  5,    0.70),
(6,  11,   0.85),
(12, 9999, 1.00);


-- =========================================================
-- 3. Коэффициент по подразделению
-- =========================================================

CREATE TABLE ref_department_coefficient (
    department     NVARCHAR(100),
    coefficient    DECIMAL(5,2)
);

INSERT INTO ref_department_coefficient
(
    department,
    coefficient
)
VALUES
(N'Отдел продаж 1', 1.00),
(N'Отдел продаж 2', 1.10);


-- =========================================================
-- 4. Типы отсутствий
-- =========================================================

CREATE TABLE ref_absence_type (
    absence_type        NVARCHAR(50),
    affects_sales_plan  BIT
);

INSERT INTO ref_absence_type
(
    absence_type,
    affects_sales_plan
)
VALUES
(N'Отпуск',     1),
(N'Больничный', 1),
(N'Декрет',     1),
(N'Обучение',   0);


-- =========================================================
-- 5. Коэффициент корректировки плана
-- =========================================================

CREATE TABLE ref_plan_adjustment (
    adjustment_type   NVARCHAR(100),
    coefficient       DECIMAL(5,2)
);

INSERT INTO ref_plan_adjustment
(
    adjustment_type,
    coefficient
)
VALUES
(N'Стандартный', 1.00),
(N'Повышающий',   1.10),
(N'Понижающий',   0.90);


-- =========================================================
-- 6. Параметры расчёта
-- =========================================================

CREATE TABLE ref_calculation_parameters (
    parameter_name    NVARCHAR(100),
    parameter_value   DECIMAL(18,4)
);

INSERT INTO ref_calculation_parameters
(
    parameter_name,
    parameter_value
)
VALUES
(N'MinWorkingDays', 1),
(N'DefaultCoefficient', 1.00);


-- =========================================================
-- 7. Коэффициент по уровню управления
-- =========================================================

CREATE TABLE ref_management_level (
    position_name    NVARCHAR(100),
    level_name       NVARCHAR(100),
    coefficient      DECIMAL(5,2)
);

INSERT INTO ref_management_level
(
    position_name,
    level_name,
    coefficient
)
VALUES
(N'Менеджер',     N'Сотрудник',     1.00),
(N'Руководитель', N'Руководитель',  1.00);


/*
    В демонстрационной модели используется 7 справочников.

    Основной принцип архитектуры:
    изменяемые бизнес-параметры хранятся отдельно от SQL-кода.

    Например, при изменении:
        - базового плана;
        - коэффициента по стажу;
        - коэффициента подразделения;
        - правил учёта отсутствий;
        - корректирующих коэффициентов;

    не требуется переписывать основную расчётную модель.

    В реальном проекте структура справочников и значения
    отличаются и не публикуются.
*/
