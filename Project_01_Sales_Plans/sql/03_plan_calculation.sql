/*
    Project: Sales Plan Calculation
    File: 03_plan_calculation.sql

    Демонстрационная модель расчёта индивидуальных планов продаж.

    Все данные, коэффициенты и бизнес-правила являются вымышленными.
    Код создан для демонстрации подхода и технических навыков.
*/

DECLARE @plan_month DATE = '2026-02-01';

DECLARE @month_start DATE = DATEFROMPARTS(
    YEAR(@plan_month),
    MONTH(@plan_month),
    1
);

DECLARE @month_end DATE = EOMONTH(@plan_month);


-- =========================================================
-- 1. Сотрудники, участвующие в расчёте
-- =========================================================

WITH employees AS
(
    SELECT
        e.employee_id,
        e.employee_name,
        e.department,
        e.position_name,
        e.hire_date,
        e.dismissal_date,

        DATEDIFF(
            MONTH,
            e.hire_date,
            @month_start
        ) AS tenure_months

    FROM demo_employees e

    WHERE
        e.hire_date <= @month_end

        AND
        (
            e.dismissal_date IS NULL
            OR e.dismissal_date >= @month_start
        )
),


-- =========================================================
-- 2. Количество рабочих дней в месяце
-- =========================================================

month_working_days AS
(
    SELECT
        COUNT(*) AS working_days

    FROM demo_calendar

    WHERE
        calendar_date BETWEEN @month_start AND @month_end
        AND is_working_day = 1
),


-- =========================================================
-- 3. Рабочие дни сотрудника до даты увольнения
-- =========================================================

employee_working_period AS
(
    SELECT
        e.employee_id,

        COUNT(c.calendar_date) AS employee_available_days

    FROM employees e

    INNER JOIN demo_calendar c
        ON c.calendar_date BETWEEN @month_start
                               AND CASE
                                      WHEN e.dismissal_date IS NOT NULL
                                           AND e.dismissal_date < @month_end
                                      THEN e.dismissal_date
                                      ELSE @month_end
                                   END

        AND c.is_working_day = 1

    GROUP BY
        e.employee_id
),


-- =========================================================
-- 4. Рабочие дни отсутствия
-- =========================================================

absence_days AS
(
    SELECT
        a.employee_id,
        a.absence_type,

        COUNT(c.calendar_date) AS absence_working_days

    FROM demo_absences a

    INNER JOIN demo_calendar c
        ON c.calendar_date BETWEEN

            CASE
                WHEN a.absence_start < @month_start
                    THEN @month_start
                ELSE a.absence_start
            END

            AND

            CASE
                WHEN a.absence_end > @month_end
                    THEN @month_end
                ELSE a.absence_end
            END

        AND c.is_working_day = 1

    INNER JOIN ref_absence_type r
        ON r.absence_type = a.absence_type
        AND r.affects_sales_plan = 1

    WHERE
        a.absence_start <= @month_end
        AND a.absence_end >= @month_start

    GROUP BY
        a.employee_id,
        a.absence_type
),


-- =========================================================
-- 5. Разворот отсутствий по типам
-- =========================================================

absence_summary AS
(
    SELECT
        employee_id,

        SUM(absence_working_days) AS total_absence_days,

        SUM(
            CASE
                WHEN absence_type = N'Отпуск'
                    THEN absence_working_days
                ELSE 0
            END
        ) AS vacation_days,

        SUM(
            CASE
                WHEN absence_type = N'Больничный'
                    THEN absence_working_days
                ELSE 0
            END
        ) AS sick_days,

        SUM(
            CASE
                WHEN absence_type = N'Декрет'
                    THEN absence_working_days
                ELSE 0
            END
        ) AS maternity_days

    FROM absence_days

    GROUP BY
        employee_id
),


-- =========================================================
-- 6. Подключение справочников
-- =========================================================

employee_parameters AS
(
    SELECT
        e.employee_id,
        e.employee_name,
        e.department,
        e.position_name,
        e.hire_date,
        e.dismissal_date,
        e.tenure_months,

        bp.base_plan,

        COALESCE(
            tc.coefficient,
            1.00
        ) AS tenure_coefficient,

        COALESCE(
            dc.coefficient,
            1.00
        ) AS department_coefficient

    FROM employees e

    LEFT JOIN ref_base_plan bp
        ON bp.position_name = e.position_name

    LEFT JOIN ref_tenure_coefficient tc
        ON e.tenure_months
           BETWEEN tc.min_months AND tc.max_months

    LEFT JOIN ref_department_coefficient dc
        ON dc.department = e.department
),


-- =========================================================
-- 7. Подготовка расчётных показателей
-- =========================================================

calculation_base AS
(
    SELECT
        ep.employee_id,
        ep.employee_name,
        ep.department,
        ep.position_name,
        ep.hire_date,
        ep.dismissal_date,
        ep.tenure_months,

        ep.base_plan,
        ep.tenure_coefficient,
        ep.department_coefficient,

        mwd.working_days AS month_working_days,

        COALESCE(
            ewp.employee_available_days,
            0
        ) AS employee_available_days,

        COALESCE(
            abs.total_absence_days,
            0
        ) AS absence_days,

        COALESCE(
            abs.vacation_days,
            0
        ) AS vacation_days,

        COALESCE(
            abs.sick_days,
            0
        ) AS sick_days,

        COALESCE(
            abs.maternity_days,
            0
        ) AS maternity_days

    FROM employee_parameters ep

    CROSS JOIN month_working_days mwd

    LEFT JOIN employee_working_period ewp
        ON ewp.employee_id = ep.employee_id

    LEFT JOIN absence_summary abs
        ON abs.employee_id = ep.employee_id
),


-- =========================================================
-- 8. Расчёт фактически доступных рабочих дней
-- =========================================================

available_days AS
(
    SELECT
        *,

        CASE
            WHEN employee_available_days - absence_days < 0
                THEN 0

            ELSE employee_available_days - absence_days
        END AS actual_working_days

    FROM calculation_base
),


-- =========================================================
-- 9. Расчёт индивидуального плана
-- =========================================================

calculated_plan AS
(
    SELECT
        *,

        CAST(
            CASE
                WHEN month_working_days = 0
                    THEN 0

                ELSE
                    base_plan
                    * tenure_coefficient
                    * department_coefficient
                    * (
                        CAST(actual_working_days AS DECIMAL(18,4))
                        /
                        NULLIF(month_working_days, 0)
                      )
            END

            AS DECIMAL(18,2)
        ) AS calculated_sales_plan

    FROM available_days
),


-- =========================================================
-- 10. Аналитические показатели
-- =========================================================

final_result AS
(
    SELECT
        *,

        SUM(calculated_sales_plan)
            OVER (
                PARTITION BY department
            ) AS department_total_plan,

        AVG(calculated_sales_plan)
            OVER (
                PARTITION BY department
            ) AS department_avg_plan,

        ROW_NUMBER()
            OVER (
                PARTITION BY department
                ORDER BY calculated_sales_plan DESC
            ) AS plan_rank_in_department

    FROM calculated_plan
)


-- =========================================================
-- Финальный результат
-- =========================================================

SELECT
    employee_id,
    employee_name,
    department,
    position_name,

    tenure_months,

    month_working_days,
    employee_available_days,

    vacation_days,
    sick_days,
    maternity_days,
    absence_days,

    actual_working_days,

    base_plan,
    tenure_coefficient,
    department_coefficient,

    calculated_sales_plan,

    department_total_plan,
    department_avg_plan,
    plan_rank_in_department

FROM final_result

ORDER BY
    department,
    plan_rank_in_department;
