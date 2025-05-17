#Task1 - Customer risk analysis: Identify customers with low credit scores & high risk loans to predict potential defaults and prioritize risk mitigation strategies

SELECT 
    c.customer_id,
    c.name,
    c.credit_score,
    c.risk_category AS customer_risk_category,
    l.loan_id,
    l.loan_amount,
    l.interest_rate,
    l.loan_status,
    l.default_risk AS loan_risk
FROM 
    customer_table c
JOIN 
    loan_table l ON c.customer_id = l.customer_id
WHERE 
    c.credit_score < 600
    AND l.default_risk = 'High'
    AND l.loan_status IN ('Approved', 'Defaulted')
ORDER BY 
    c.credit_score ASC,
    l.interest_rate DESC;
    

# Task 2 - Loan Purpose Insights: Determine the most popular loan purposes and their associated revenues to align financial products with customer demands

SELECT 
    loan_purpose,
    COUNT(*) AS num_loans,
    SUM(loan_amount) AS total_loan_amount
FROM 
    loan_table
GROUP BY 
    loan_purpose
ORDER BY 
    num_loans DESC;

# Task 3 - High-Value Transactions: Detect transactions that exceed 30% of their respective loan amounts to flag potential fraudulent activities

SELECT 
    t.transaction_id,
    t.loan_id,
    t.customer_id,
    t.transaction_amount,
    l.loan_amount,
    0.3 * l.loan_amount AS threshold_30pct
FROM 
    transaction_table t
JOIN 
    loan_table l ON t.loan_id = l.loan_id
WHERE 
    t.transaction_amount > 0.3 * l.loan_amount
ORDER BY 
    t.transaction_amount DESC;


# Task 4 - Missed EMI Count: Analyze the number of missed EMIs per loan to identify loans at risk of default and suggest intervention strategies

SELECT 
    l.loan_id,
    l.customer_id,
    l.loan_amount,
    l.loan_status,
    COUNT(t.transaction_id) AS missed_emi_count
FROM 
    loan_table l
JOIN 
    transaction_table t ON l.loan_id = t.loan_id
WHERE 
    t.transaction_type = 'Missed EMI'
GROUP BY 
    l.loan_id, l.customer_id, l.loan_amount, l.loan_status
ORDER BY 
    missed_emi_count DESC;

# Task 5 - Regional Loan Distribution: Examine the geographical distribution of loan disbursements to assess regional trends and business opportunities

SELECT 
    c.region,
    COUNT(l.loan_id) AS total_loans,
    SUM(l.loan_amount) AS total_loan_amount
FROM 
    customer_table c
JOIN 
    loan_table l ON c.customer_id = l.customer_id
WHERE 
    l.loan_status != 'Rejected'
GROUP BY 
    c.region
ORDER BY 
    total_loan_amount DESC;
    
# Task 6 - Loyal Customers: List customers who have been associated with Cross River Bank for over five years and evaluate their loan activity to design loyalty programs

SELECT 
    c.customer_id,
    c.name,
    c.customer_since,
    DATEDIFF(CURRENT_DATE, c.customer_since) / 365 AS years_with_bank,
    COUNT(l.loan_id) AS total_loans,
    SUM(l.loan_amount) AS total_loan_amount
FROM 
    customer_table c
LEFT JOIN 
    loan_table l ON c.customer_id = l.customer_id
WHERE 
    c.customer_since <= DATE_SUB(CURRENT_DATE, INTERVAL 5 YEAR)
GROUP BY 
    c.customer_id, c.name, c.customer_since
ORDER BY 
    total_loan_amount DESC;
    
# Task 7 - High-Performing Loans: Identify loans with excellent repayment histories to refine lending policies and highlight successful products

SELECT 
l.loan_id,
l.customer_id,
l.loan_amount,
l.loan_status,
COUNT(CASE WHEN t.transaction_type = 'EMI Payment' THEN 1 END) AS emi_payments,
COUNT(CASE WHEN t.transaction_type = 'Missed EMI' THEN 1 END) AS missed_emis
FROM loan_table l
JOIN transaction_table t ON l.loan_id = t.loan_id
WHERE l.loan_status NOT IN ('Rejected', 'Defaulted')
GROUP BY l.loan_id, l.customer_id, l.loan_amount, l.loan_status
HAVING missed_emis = 0 AND emi_payments > 0
ORDER BY emi_payments DESC;

# Task 8 - Age-Based Loan Analysis: Analyze loan amounts disbursed to customers of different age groups to design targeted financial products. INTERMEDIATE

SELECT
    CASE 
        WHEN c.age < 25 THEN '<25'
        WHEN c.age BETWEEN 25 AND 34 THEN '25-35'
        WHEN c.age BETWEEN 35 AND 44 THEN '35-45'
        WHEN c.age BETWEEN 45 AND 59 THEN '45-60'
        ELSE '60+'
    END AS age_group,
    COUNT(l.loan_id) AS total_loans,
    SUM(l.loan_amount) AS total_loan_amount,
    AVG(l.loan_amount) AS avg_loan_amount
FROM 
    customer_table c
JOIN 
    loan_table l ON c.customer_id = l.customer_id
WHERE
    l.loan_status != 'Rejected'  -- Optional: exclude rejected loans
GROUP BY 
    age_group
ORDER BY 
    total_loan_amount DESC;
    
    
# Task 9 - Seasonal Transaction Trends: Examine transaction patterns over years and months to identify seasonal trends in loan repayments. Advanced

SELECT 
    EXTRACT(YEAR FROM transaction_date) AS year,
    EXTRACT(MONTH FROM transaction_date) AS month,
    COUNT(transaction_id) AS total_transactions,
    SUM(transaction_amount) AS total_amount
FROM 
    transaction_table
WHERE 
    transaction_type IN ('EMI Payment', 'Missed EMI')
GROUP BY 
    EXTRACT(YEAR FROM transaction_date), EXTRACT(MONTH FROM transaction_date)
ORDER BY 
    year, month;
    
# Task 10 - Fraud Detection: Highlight potential fraud by identifying mismatches between customer address locations and transaction IP locations. Advanced

SELECT 
    t.transaction_id,
    t.customer_id,
    c.address,
    t.ip_location,
    t.transaction_date,
    t.transaction_amount
FROM 
    transaction_table t
JOIN 
    customer_table c ON t.customer_id = c.customer_id
WHERE 
    LOWER(TRIM(c.address)) NOT LIKE CONCAT('%', LOWER(TRIM(t.ip_location)), '%')
ORDER BY 
    t.transaction_date DESC;

# Task 11 - Repayment History Analysis: Rank loans by repayment performance using window functions.


WITH repayment_summary AS (
    SELECT 
        t.loan_id,
        COUNT(CASE WHEN t.transaction_type = 'EMI Payment' THEN 1 END) AS emi_payments,
        COUNT(CASE WHEN t.transaction_type = 'Missed EMI' THEN 1 END) AS missed_emis
    FROM 
        transaction_table t
    GROUP BY 
        t.loan_id
),
repayment_score AS (
    SELECT 
        loan_id,
        emi_payments,
        missed_emis,
        (emi_payments - missed_emis) AS repayment_score  -- you can tweak this formula
    FROM 
        repayment_summary
)
SELECT 
    *,
    RANK() OVER (ORDER BY repayment_score DESC) AS repayment_rank
FROM 
    repayment_score
ORDER BY 
    repayment_rank;


# Task 12 - Credit Score vs. Loan Amount: Compare average loan amounts for different credit score ranges.


SELECT
    CASE 
        WHEN c.credit_score < 600 THEN 'Poor (<600)'
        WHEN c.credit_score BETWEEN 600 AND 649 THEN 'Fair (600–649)'
        WHEN c.credit_score BETWEEN 650 AND 699 THEN 'Good (650–699)'
        WHEN c.credit_score BETWEEN 700 AND 749 THEN 'Very Good (700–749)'
        ELSE 'Excellent (750+)'
    END AS credit_score_range,
    COUNT(l.loan_id) AS total_loans,
    AVG(l.loan_amount) AS avg_loan_amount,
    SUM(l.loan_amount) AS total_loan_amount
FROM 
    customer_table c
JOIN 
    loan_table l ON c.customer_id = l.customer_id
WHERE
    l.loan_status != 'Rejected'  -- optional: ignore rejected loans
GROUP BY 
    credit_score_range
ORDER BY 
    credit_score_range;


# Task 13 - Top Borrowing Regions: Identify regions with the highest total loan disbursements

SELECT 
    c.region, 
    SUM(l.loan_amount) AS total_loans_disbursed
FROM customer_table c
JOIN loans_table l ON c.customer_id = l.customer_id
GROUP BY c.region
ORDER BY total_loans_disbursed DESC
LIMIT 10;  -- Adjust this to get more or fewer top regions

# Task 14 - Early Repayment Patterns: Detect loans with frequent early repayments and their impact on revenue

SELECT 
    l.loan_id, 
    l.customer_id, 
    l.loan_amount, 
    l.due_date, 
    r.payment_date, 
    r.payment_amount,
    CASE 
        WHEN r.payment_date < l.due_date THEN 'Early Repayment'
        ELSE 'On-Time or Late Repayment'
    END AS repayment_status
FROM loans_table l
JOIN repayments_table r ON l.loan_id = r.loan_id
WHERE r.payment_date < l.due_date
ORDER BY l.customer_id, r.payment_date;

# Task 15 - Feedback Correlation: Correlate customer feedback sentiment scores with loan statuses

