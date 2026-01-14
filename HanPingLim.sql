-- Q1
SELECT
    e.first_name,
    e.last_name,
    e.salary,
    e.job_id,
    d.department_name,
    l.city,
    c.country_name
FROM employees e
JOIN departments d
    ON e.department_id = d.department_id
JOIN locations l
    ON d.location_id = l.location_id
JOIN countries c
    ON l.country_id = c.country_id
WHERE e.salary = (
    SELECT MAX(salary)
    FROM employees
);

-- Q2
SELECT
	e.first_name,
    e.last_name,
    e.job_id,
    e.salary,
    e.manager_id
FROM employees e, consultants c
WHERE c.job_id = e.job_id
ORDER BY e.last_name;

-- Q3
SELECT
	c.cust_id,
    c.cust_fname,
    c.cust_lname,
    c.cust_city,
    coalesce(round(MAX(s.sales_amt),2),0) AS largest_sale,
    coalesce(round(SUM(s.sales_amt),2),0) AS total_sales,
    coalesce(round(MAX(s.sales_amt)/NULLIF (SUM(s.sales_amt),0) * 100,2),0) AS percentage,
    coalesce(round(AVG(s.sales_amt),2),0) AS average,
    count(s.sales_amt) AS sales_count
    
FROM customers c
LEFT JOIN sales s
	ON c.cust_id = s.sales_cust_id
GROUP BY
	c.cust_id,
    c.cust_fname,
    c.cust_lname,
    c.cust_city
ORDER BY c.cust_id;

-- Q4
SELECT
	e.first_name,
    e.last_name,
    d.department_name,
    l.street_address,
    l.city,
    l.state_province
FROM employees e, departments d, locations l
WHERE d.manager_id = e.employee_id
AND l.location_id = d.location_id
	
ORDER BY d.department_id;

-- Q5
SELECT
	e.first_name as First_name,
    e.last_name as Last_Name,
    e.job_id as Job_id,
    e.salary as Own_salary,
    m_e.salary as Manager_Salary
FROM employees e, employees m_e
WHERE e.manager_id = m_e.employee_id
AND e.salary >= m_e.salary;

-- Q6
SELECT
	e.employee_id,
    e.first_name,
    e.last_name,
    e.job_id,
    e.salary

FROM employees e
WHERE EXISTS(
	SELECT 1
    FROM job_history j_h
    WHERE j_h.employee_id = e.employee_id
    AND j_h.job_id = e.job_id
    AND EXISTS(
		SELECT 1
        FROM job_history j_h1
        WHERE j_h.employee_id = e.employee_id
        AND j_h1.job_id <> e.job_id
        AND j_h1.start_date > j_h.end_date
    )
);

-- Q7
SELECT DISTINCT
	e.first_name,
    e.last_name,
    e.job_id,
    e.salary
FROM employees e
WHERE e.employee_id NOT IN(
	SELECT manager_id
    FROM employees
    WHERE manager_id IS NOT NULL
)
AND e.salary > (
	SELECT MAX(salary)
    FROM employees
    WHERE employee_id IN(
		SELECT manager_id
        FROM employees
        WHERE manager_id IS NOT NULL
    )
)
ORDER BY e.salary;

-- Q7
WITH managers AS(
SELECT DISTINCT m.salary, m.employee_id
FROM employees m
WHERE m.employee_id NOT IN(
	SELECT manager_id
    FROM employees
    WHERE manager_id IS NOT NULL
	)
)
SELECT
	e.first_name,
    e.last_name,
    e.job_id,
    e.salary
FROM employees e
WHERE e.employee_id NOT IN (SELECT employee_id FROM managers)
AND e.salary > (SELECT MAX(salary) FROM managers)
ORDER BY e.salary;

-- Q8
SELECT
	count(e.employee_id) AS employee_count ,
    r.region_name
FROM employees e
LEFT JOIN departments d
	on e.department_id = d.department_id
LEFT JOIN locations l
	on d.location_id = l.location_id
LEFT JOIN countries c
	on l.country_id = c.country_id
LEFT JOIN regions r
	on r.region_id = c.region_id
GROUP BY r.region_name
ORDER BY r.region_name;





-- Q9 i
START TRANSACTION;

UPDATE employees
SET first_name = 'Kimberly',
    department_id = (
        SELECT DISTINCT jh.department_id
        FROM jobs j, job_history jh
        WHERE j.job_title = 'Sales Representative'
          AND j.job_id = jh.job_id
          AND jh.department_id IS NOT NULL
        LIMIT 1
    )
WHERE employee_id = (
    SELECT employee_id
    FROM (SELECT employee_id
          FROM employees
          WHERE first_name = 'Kimberely'
            AND last_name = 'Grant'
          LIMIT 1) x
);

-- Q9 ii
UPDATE employees
SET salary = (
    SELECT salary
    FROM consultants
    WHERE last_name = 'Taylor'
    LIMIT 1
)
WHERE employee_id IN (
    SELECT x.employee_id
    FROM (
        SELECT employee_id
        FROM employees
        WHERE last_name IN ('Weiss', 'Fripp')
    ) x
);

-- Q9 iii
UPDATE regions
SET region_name = 'North America'
WHERE region_id = (
    SELECT x.region_id
    FROM (
        SELECT region_id
        FROM regions
        WHERE region_name = 'Americas'
        LIMIT 1
    ) x
);

UPDATE regions
SET region_name = 'Middle East'
WHERE region_id = (
    SELECT x.region_id
    FROM (
        SELECT region_id
        FROM regions
        WHERE region_name = 'Middle East and Africa'
        LIMIT 1
    ) x
);

-- Q9b
DELETE FROM consultants
WHERE consultant_id = (
    SELECT x.consultant_id
    FROM (
        SELECT c.consultant_id
        FROM consultants c, employees e
        WHERE c.first_name = e.first_name
          AND c.last_name  = e.last_name
        LIMIT 1
    ) x
);

-- Q9c
INSERT INTO regions (region_id, region_name)
VALUES (5, 'South America');

INSERT INTO regions (region_id, region_name)
VALUES (6, 'Africa');

COMMIT;

-- Bonus 1
SELECT 
	s.sales_rep_id,
    e.first_name,
    e.last_name,
    s.sales_amt,
    s.sales_timestamp,
    s.sales_cust_id,
    c.cust_lname
FROM sales s
JOIN employees e
	ON s.sales_rep_id = e.employee_id
JOIN customers c
	ON s.sales_cust_id = c.cust_id
Join (
SELECT sales_rep_id, MAX(sales_amt) AS max_sale
FROM sales
GROUP BY sales_rep_id
) mx
ON s.sales_rep_id = mx.sales_rep_id
AND s.sales_amt = mx.max_sale
ORDER BY s.sales_rep_id;

-- Bonus 2
SELECT
	t.first_name,
    t.last_name,
    t.total_pay
    
FROM (
	SELECT
		e.first_name,
        e.last_name,
        (e.salary + (e.commission_pct * coalesce(sum(s.sales_amt), 0))) AS total_pay
        FROM employees e
        LEFT JOIN sales s
			ON s.sales_rep_id = e.employee_id
		WHERE e.commission_pct IS NOT NULL
        GROUP BY
			e.employee_id,
            e.first_name,
            e.last_name,
            e.salary,
            e.commission_pct
) t
WHERE t.total_pay > (
	SELECT AVG(t2.total_pay)
    FROM (
		SELECT
			(e2.salary + (e2.commission_pct * coalesce(SUM(s2.sales_amt), 0))) AS total_pay
		FROM employees e2
        LEFT JOIN sales s2
			ON s2.sales_rep_id = e2.employee_id
		WHERE e2.commission_pct IS NOT NULL
        GROUP BY
			e2.employee_id,
            e2.salary,
            e2.commission_pct
            
    ) t2
)
ORDER BY t.total_pay;

-- Bonus 3
SELECT
	m.employee_id AS manager_id,
    m.last_name AS manager_last_name,
    (m.salary + (m.commission_pct * COALESCE(SUM(s.sales_amt), 0))) AS total_compensation
FROM employees m
JOIN employees r
	ON r.manager_id = m.employee_id
LEFT JOIN sales s
	ON s.sales_rep_id = r.employee_id
WHERE m.commission_pct IS NOT NULL
GROUP BY
	m.employee_id,
    m.last_name,
    m.salary,
    m.commission_pct
ORDER BY m.employee_id;

-- Bonus 4
SELECT
    rep.last_name,
    mgr.last_name,
    c.cust_fname,
    c.cust_lname,
    c.cust_city,
    c.cust_country,
    s.sales_amt
FROM customers c
JOIN (
    SELECT sales_cust_id, MAX(sales_amt) AS max_amt
    FROM sales
    GROUP BY sales_cust_id
) mx
    ON mx.sales_cust_id = c.cust_id
JOIN sales s
    ON s.sales_cust_id = mx.sales_cust_id
   AND s.sales_amt = mx.max_amt
JOIN employees rep
    ON rep.employee_id = s.sales_rep_id
LEFT JOIN employees mgr
    ON mgr.employee_id = rep.manager_id
ORDER BY rep.last_name;

