USE PortfolioSalesPlans;
GO


DECLARE @plan_month DATE = '2026-02-01';

DECLARE @month_start DATE =
    DATEFROMPARTS(
        YEAR(@plan_month),
        MONTH(@plan_month),
        1
    );

DECLARE @month_end DATE =
    EOMONTH(@plan_month);


/* ============================================================
   1. Сотрудники, участвующие в расчете
   ============================================================ */

WITH employees AS
(
    SELECT
        employee_id,
        employee_name,
        position_name,
        department,
        hire_date,
        dismissal_date,

        DATEDIFF(
            MONTH,
            hire_date,
            @month_start
        ) AS tenure_months

    FROM dbo.demo_employees

    WHERE hire_date <= @month_end

      AND
      (
          dismissal_date IS NULL
          OR dismissal_date >= @month_start
      )
),


/* ============================================================
   2. Параметры сотрудников
   ============================================================ */

employee_parameters AS
(
    SELECT
        e.employee_id,
        e.employee_name,
        e.position_name,
        e.department,
        e.hire_date,
        e.dismissal_date,
        e.tenure_months,

        bp.base_plan,

        tc.coefficient AS tenure_coefficient,

        dc.coefficient AS department_coefficient

    FROM employees e

    LEFT JOIN dbo.ref_base_plan bp
        ON e.position_name = bp.position_name

    LEFT JOIN dbo.ref_tenure_coefficient tc
        ON e.tenure_months >= tc.min_months
        AND
        (
            e.tenure_months <= tc.max_months
            OR tc.max_months IS NULL
        )

    LEFT JOIN dbo.ref_department_coefficient dc
        ON e.department = dc.department
),


/* ============================================================
   3. Рабочие дни отсутствий
   ============================================================ */

absence_days AS
(
    SELECT
        a.employee_id,

        COUNT(*) AS absence_working_days

    FROM dbo.demo_absences a

    INNER JOIN dbo.demo_calendar c
        ON c.calendar_date
            BETWEEN a.date_from AND a.date_to

    INNER JOIN dbo.ref_absence_type at
        ON a.absence_type = at.absence_type

    WHERE c.is_working_day = 1
      AND at.affects_sales_plan = 1

    GROUP BY
        a.employee_id
),


/* ============================================================
   4. Рабочие дни каждого сотрудника
   ============================================================ */

employee_working_days AS
(
    SELECT
        ep.employee_id,
        ep.employee_name,
        ep.position_name,
        ep.department,
        ep.hire_date,
        ep.dismissal_date,
        ep.tenure_months,
        ep.base_plan,
        ep.tenure_coefficient,
        ep.department_coefficient,

        COUNT(c.calendar_date) AS employee_working_days

    FROM employee_parameters ep

    INNER JOIN dbo.demo_calendar c
        ON c.calendar_date >=
            CASE
                WHEN ep.hire_date > @month_start
                    THEN ep.hire_date
                ELSE @month_start
            END

        AND c.calendar_date <=
            CASE
                WHEN ep.dismissal_date IS NOT NULL
                     AND ep.dismissal_date < @month_end
                    THEN ep.dismissal_date
                ELSE @month_end
            END

        AND c.is_working_day = 1

    GROUP BY
        ep.employee_id,
        ep.employee_name,
        ep.position_name,
        ep.department,
        ep.hire_date,
        ep.dismissal_date,
        ep.tenure_months,
        ep.base_plan,
        ep.tenure_coefficient,
        ep.department_coefficient
),


/* ============================================================
   5. Вычитаем отсутствия
   ============================================================ */

available_days AS
(
    SELECT
        ewd.employee_id,
        ewd.employee_name,
        ewd.position_name,
        ewd.department,
        ewd.hire_date,
        ewd.dismissal_date,
        ewd.tenure_months,

        ewd.base_plan,
        ewd.tenure_coefficient,
        ewd.department_coefficient,

        ewd.employee_working_days,

        COALESCE(
            ad.absence_working_days,
            0
        ) AS absence_working_days,

        ewd.employee_working_days
        -
        COALESCE(
            ad.absence_working_days,
            0
        ) AS actual_working_days

    FROM employee_working_days ewd

    LEFT JOIN absence_days ad
        ON ewd.employee_id = ad.employee_id
),


/* ============================================================
   6. Общее количество рабочих дней месяца
   ============================================================ */

month_working_days AS
(
    SELECT
        COUNT(*) AS working_days

    FROM dbo.demo_calendar

    WHERE is_working_day = 1
),


/* ============================================================
   7. Расчет итогового плана сотрудника
   ============================================================ */

calculated_plan AS
(
    SELECT
        ad.employee_id,
        ad.employee_name,
        ad.position_name,
        ad.department,

        ad.base_plan,
        ad.tenure_months,
        ad.tenure_coefficient,
        ad.department_coefficient,

        mwd.working_days AS month_working_days,

        ad.employee_working_days,
        ad.absence_working_days,
        ad.actual_working_days,

        CAST(
            ad.actual_working_days * 1.0
            / NULLIF(mwd.working_days, 0)

            AS DECIMAL(5,2)
        ) AS working_day_coefficient,

        CAST(
            ad.base_plan
            * ad.tenure_coefficient
            * ad.department_coefficient
            * ad.actual_working_days
            / NULLIF(mwd.working_days, 0)

            AS DECIMAL(18,2)
        ) AS calculated_plan

    FROM available_days ad

    CROSS JOIN month_working_days mwd
),


/* ============================================================
   8. Итоговые показатели по подразделению
   ============================================================ */

final_result AS
(
    SELECT
        employee_id,
        employee_name,
        position_name,
        department,

        base_plan,
        tenure_months,
        tenure_coefficient,
        department_coefficient,

        month_working_days,
        employee_working_days,
        absence_working_days,
        actual_working_days,
        working_day_coefficient,

        calculated_plan,


        /* Общий план подразделения */

        SUM(calculated_plan) OVER
        (
            PARTITION BY department
        ) AS department_total_plan,


        /* Средний план сотрудника внутри подразделения */

        CAST(
            AVG(calculated_plan) OVER
            (
                PARTITION BY department
            )
            AS DECIMAL(18,2)
        ) AS department_avg_plan

    FROM calculated_plan
)


SELECT *
FROM final_result
ORDER BY
    department
