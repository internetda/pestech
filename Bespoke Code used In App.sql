--Code used to generate schedule time list of values at 30 minute intervals  from 08:00 to 18:00

WITH thirty AS
    (SELECT TRUNC(sysdate) + (LEVEL * 30)/(24*60) c_time
     FROM dual
      CONNECT BY LEVEL <= (24*60) / 30
    )
  SELECT to_char(c_time, 'hh24:mi') start_time,
         to_char(c_time + 30 / (24 * 60), 'hh24:mi') end_time
   FROM thirty
   WHERE EXTRACT(HOUR FROM CAST (c_time AS TIMESTAMP)) BETWEEN 8 AND 18;
   
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--List Of Values - Customer Contract for workorders

SELECT contract_name D,cc_id R
   FROM (
   SELECT w.workorder_id,
        ct.customer_type_id,
        co.contract_name,
        cc.cc_id
        FROM pt_workorders w
        JOIN pt_customers C ON C.custid = w.customer_id
        JOIN pt_customer_type ct ON ct.customer_type_id = C.cust_type_id
        JOIN pt_customer_contracts cc ON cc.custid = C.custid
        JOIN pt_contracts co ON co.contract_id = cc.contract_id);
	
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--List Of Values forEmployees

SELECT first_name||' '||Last_name D , empid R
FROM pt_employees;

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- List Of Values  Salutation

  SELECT 'Mr' D , 'Mr' R FROM DUAL
  UNION
    SELECT 'Mrs' D , 'Mrs' R FROM DUAL
    UNION 
      SELECT 'Mrs' D , 'Mrs' R FROM DUAL
      UNION
        SELECT 'Dr' D , 'Dr' R FROM DUAL;
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--List Of Values  Customers
		
SELECT CASE WHEN company IS NULL THEN  first_name||' '||last_name
ELSE company END AS D,
     custid R
FROM pt_customers;

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Stored PROCEDURE used to add Employee History if Role or Salary changes

create or replace PROCEDURE add_role_history
CREATE OR REPLACE PROCEDURE add_role_history
  (  p_emp_id          pt_emp_history.empid%TYPE
   , p_start_date      pt_emp_history.start_date%TYPE
   , p_end_date        pt_emp_history.end_date%TYPE
   , p_job_id          pt_emp_history.roleid%TYPE
   , p_salary          pt_emp_history.salary%TYPE
  
   )
IS
BEGIN
  INSERT INTO pt_emp_history (empid, start_date, end_date, 
                           roleid, salary )
    VALUES(p_emp_id, p_start_date, p_end_date, p_job_id, p_salary);
END add_role_history;

-- Stored PROCEDURE fired by the following trigger

CREATE OR REPLACE TRIGGER update_emp_history
  AFTER UPDATE OF roleid, salary ON pt_employees
  FOR EACH ROW
DECLARE
  l_sdate DATE;
BEGIN
IF (:OLD.roleid != :NEW.roleid
 OR :OLD.salary != :NEW.salary
 ) 
THEN
  FOR c1 IN 
    (SELECT MAX(end_date) prev_start_date 
       FROM pt_emp_history
      WHERE empid = :OLD.empid) 
  LOOP
     l_sdate := c1.prev_start_date;
  END LOOP;
  add_role_history(:OLD.empid, 
                  nvl(l_sdate,:OLD.hire_date), 
                  sysdate, 
                  :OLD.roleid, 
                  :OLD.salary
                  );
END IF;

END;


-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


----Customers report
SELECT custid,
       nvl(company, 'Domestic Customer') company,
       salutation ||' '||first_name||' '|| last_name AS customer_name,      
        address_1 || decode(address_2, NULL, NULL, ', ' || address_2)||', '||town_city||', '||co.county ||', '||decode(eircode, NULL, NULL, ', ' || eircode) address, 
       phone,
       mobile,
       email,
       account_status_id ,
       cust_type_id
  FROM pt_customers C
  JOIN pt_counties co ON co.county_id = C.county
  
  -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--HTML for About Page
  
<p>Pests can cause serious damage both financially and to a business’s reputation. A good quality, well documented pest management system carried out in a within a defined schedule will help protect the business, its staff, customers, and its reputation.
For a food manufacturing business to meet their audit requirements for example, they need to be able to provide a fully traceable, well documented pest control inspection record.
This app will help ensure regular routine inspections are record and carried out in a timely manner in accordance with the agreed SLA.</p> 

<p>The app will also make the data available live online 24hrs a day to ensure a customer can provide any documentation required for audits or surprise inspections.
There are numerous benefits to the pest control company.</P> 
<br>
For example:
<br>
<ul>
<li> Helps keep track of their customers.</li>
<li> Improve quality of service being delivered.</li>
<li> Schedule Technician’s workload.</li>
<li> Reduce operating costs.</li>
<li> Provide a USP (Unique Selling Proposition) to help grow the business.</li>
<li> Improve cashflow with integrated payments</li> 
</ul>
<br> <br>
<hr>
App version: 1.0 <br>
<br>
<address>
Email: &nbsp;<a href="mailto:info@pestech.eu">info@pestech.eu</a><br>
Visit us at:&nbsp;  <a href= "www.pestech.eu">PestTech.eu</a><br>
Postal address:&nbsp;  PO Box 564, Disneyland<br>
USA
</address>

  
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  --Dashboard Charts
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Wotkorder Metrics

WITH DATA AS (
SELECT 
(SELECT COUNT(*) FROM pt_workorders w  JOIN  pt_call_type ct ON w.call_type_id =  ct.call_type_id  WHERE status_id = 1 AND ct.call_type_id = 1 ) AS open_call_outs,
(SELECT COUNT(*) FROM pt_workorders w  JOIN  pt_call_type ct ON w.call_type_id =  ct.call_type_id WHERE status_id = 2 AND ct.call_type_id = 1 ) AS closed_call_outs,
(SELECT COUNT(*) FROM pt_workorders w  JOIN  pt_call_type ct ON w.call_type_id =  ct.call_type_id WHERE status_id = 3 AND ct.call_type_id = 1 ) AS on_hold_call_outs,

(SELECT COUNT(*) FROM pt_workorders w  JOIN  pt_call_type ct ON w.call_type_id =  ct.call_type_id WHERE status_id = 1 AND ct.call_type_id = 2) AS open_followup_calls,
(SELECT COUNT(*) FROM pt_workorders w  JOIN  pt_call_type ct ON w.call_type_id =  ct.call_type_id WHERE status_id = 2 AND ct.call_type_id = 2) AS closed_followup_calls,
(SELECT COUNT(*) FROM pt_workorders w  JOIN  pt_call_type ct ON w.call_type_id =  ct.call_type_id WHERE status_id = 3 AND ct.call_type_id = 2) AS on_hold_followup_calls,

(SELECT COUNT(*) FROM pt_workorders w  JOIN  pt_call_type ct ON w.call_type_id =  ct.call_type_id WHERE w.status_id = 1 AND ct.call_type_id = 3) AS open_routine_calls,
(SELECT COUNT(*) FROM pt_workorders w  JOIN  pt_call_type ct ON w.call_type_id =  ct.call_type_id WHERE status_id = 2 AND ct.call_type_id = 3) AS closed_routine_calls,
(SELECT COUNT(*) FROM pt_workorders w  JOIN  pt_call_type ct ON w.call_type_id =  ct.call_type_id WHERE status_id = 3 AND ct.call_type_id = 3) AS on_hold_routine_calls
FROM dual
)
SELECT DISTINCT
DATA.open_call_outs AS open_callouts,
DATA.closed_call_outs AS closed_callouts ,
DATA.on_hold_call_outs AS on_hold_callouts,

DATA.open_followup_calls AS open_followup_call,
DATA.closed_followup_calls AS closed_followup_call,
DATA.on_hold_followup_calls AS on_hold_followup_call,

DATA.open_routine_calls AS open_routine_call,
DATA.closed_routine_calls AS closed_routine_call,
DATA.on_hold_routine_calls AS on_hold_routine_call
FROM DATA;


--Top 10, commerical customers (Contract and callout value)

SELECT CUSTOMER, TOTAL_CHARGE
FROM (
SELECT
   C.COMPANY CUSTOMER,
    SUM(NVL(CC.ANNUAL_FEE, 0)+  NVL(W.AMOUNT,0))TOTAL_CHARGE
FROM
         PT_CUSTOMERS C
    LEFT JOIN PT_CUSTOMER_CONTRACTS CC ON C.CUSTID = CC.CUSTID
    LEFT JOIN PT_WORKORDERS W ON CC.CUSTID = W.CUSTOMER_ID
    WHERE C.CUST_TYPE_ID =2
    GROUP BY C.COMPANY)
    WHERE ROWNUM <11
    ORDER BY TOTAL_CHARGE DESC
   
   --Combined Sales by Employee (Contract and callout value)
   
   SELECT SUM(fee) AS total_charges, REP FROM (

SELECT
SUM(cc.annual_fee) AS fee,
E.first_name ||' '||E.last_name AS REP    

FROM
     pt_customers C
INNER JOIN pt_customer_contracts cc ON C.custid = cc.custid
INNER JOIN pt_employees E ON cc.rep_id = E.empid

GROUP BY
E.first_name,
E.last_name

UNION 

SELECT
SUM(w.amount) AS fee,
 E.first_name ||' '||E.last_name AS REP 
FROM
     pt_workorders w
INNER JOIN pt_schedule S ON S.workorder_id = w.workorder_id
INNER JOIN pt_employees E ON S.empid = E.empid
GROUP BY
E.first_name,
E.last_name)
GROUP BY REP
ORDER BY total_charges DESC;

--Customer by county
SELECT
    COUNT(c.county)                            AS "Count_COUNTY",
    SUM(cc.annual_fee)         AS "Sum_ANNUAL_FEE",
    co.county
FROM
         pt_customers c
    INNER JOIN pt_customer_contracts cc ON c.custid = cc.custid
    INNER JOIN pt_counties co ON c.county = a203196.co.county_id
GROUP BY
    co.county
    order by 1 desc , 2 desc
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  
  -- Work Order Schedule Calendar
  
SELECT
    s.schedule_id,
    s.empid,
    s.schedule_date,
    s.schedule_time display_time, --used in report to display time only
    TO_CHAR(TO_DATE(s.schedule_time, 'HH24:MI:SS'), 'DD-MON-YYYY HH24:MI:SS') schedule_time, --needed to get the form to return a correct value when being set on submit
    s.customer_contract_id,
    s.workorder_id,
    s.custid,
    e.first_name||' '||e.Last_name as Technican,
    co.contract_name,
    ct.call_type,
    ws.status,
    CASE WHEN c.company IS NULL THEN  c.first_name||' '||c.last_name
    ELSE c.company END AS Customer,
    w.amount Workorder_Charge,
    w.details Workorder_Details
FROM
         pt_schedule s
    INNER JOIN pt_employees e ON s.empid = e.empid
    INNER JOIN pt_customer_contracts cc ON s.customer_contract_id = cc.cc_id
    INNER JOIN pt_contracts co ON cc.contract_id = co.contract_id
    INNER JOIN pt_workorders w ON s.workorder_id = w.workorder_id
    INNER JOIN pt_call_type ct ON w.call_type_id = ct.call_type_id
    INNER JOIN pt_workorder_status ws ON w.status_id = ws.status_id
    INNER JOIN pt_customers c ON s.custid = c.custid;

 -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
 --Workorder Report
   
   With Account_balance as (SELECT
     w.workorder_id,
     w.customer_id,
    SUM(pd.amount) AS balance
FROM
         pt_payment_details pd
    INNER JOIN  pt_workorders w ON pd.workorder_id =  w.workorder_id
GROUP BY
     w.workorder_id,
     w.customer_id)
     
     SELECT distinct 
    nvl(c.company, c.first_name
                   || ' '
                   || c.last_name)           AS customer,
                   c.address_1 ||', '||c.town_city as Location,
    w.details,
    w.amount,
    s.schedule_date,
    s.schedule_time,
    e.first_name
    || ' '
    || e.last_name            AS employee,
    cc.cc_id,
    w.workorder_id,
    ws.status,
    case when w.amount - nvl(ab.balance,0) = 0 then null else w.amount - nvl(ab.balance,0) end  AS account_balance,
    case when  w.amount - nvl(ab.balance,0) != 0.00 then 'Make Payment' else null end AS "Make Payment",
    case when ws.status_ID != 2 then 'View Schedule' else null end AS "View Schedule"
FROM
         pt_customers c
    INNER JOIN pt_customer_contracts  cc ON c.custid = cc.custid
    INNER JOIN pt_workorders          w ON cc.custid = w.customer_id
                                  AND cc.cc_id = w.customer_contract_id
    LEFT JOIN pt_schedule            s ON w.workorder_id = s.workorder_id
    INNER JOIN pt_employees           e ON s.empid = e.empid
    INNER JOIN pt_workorder_status    ws ON w.status_id = ws.status_id
    LEFT JOIN pt_payment_details     pd ON w.workorder_id = pd.workorder_id
    left join Account_balance ab on ab.customer_id = c.custid and ab.workorder_id = w.workorder_id
    
   ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
   
   --Workorder Payment report
    
    With Account_balance as (SELECT
     w.workorder_id,
     w.customer_id,
    SUM(pd.amount) AS Balance
FROM
         pt_payment_details pd
    INNER JOIN  pt_workorders w ON pd.workorder_id =  w.workorder_id
GROUP BY
     w.workorder_id,
     w.customer_id)
     SELECT
    nvl(c.company, c.first_name
                   || ' '
                   || c.last_name)      AS customer,
    w.workorder_id,
    w.amount as workorder_Amount,
    pt.payyment_type as Payment_type,
    pd.payment_date,
    pd.amount as Payment_Amount,
    pd.payment_detail_id,
    w.amount - nvl(ab.balance , 0)     AS account_balance,
    'Edit Payment' AS EDIT_LINK
FROM
         pt_payment_details pd
    INNER JOIN pt_workorders    w ON pd.workorder_id = w.workorder_id
    INNER JOIN pt_customers     c ON c.custid = w.customer_id
    INNER JOIN pt_payment_type  pt ON pd.payment_type_id = pt.payment_type_id
    join Account_balance ab on ab.workorder_id = w.workorder_id
    
    
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Employee report

select EMPID,
       FIRST_NAME ||' '||LAST_NAME Employee,
       MOBILE,
       EMAIL,
       HIRE_DATE,
       ROLEID,
       SALARY
  from PT_EMPLOYEES
  
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------  

 --APP ICON CSS
 
 .app-icon {
    background-image: url(app-icon.svg);
    background-repeat: no-repeat;
    background-size: cover;
    background-position: 50%;
    background-color: #CA589D;
}


--set report icons

<span aria-label="Edit"><span class="fa fa-edit" aria-hidden="true" title="Edit"></span></span>

--CSS to add Make Payment Button
	
	class="t-Button t-Button--simple t-Button--hot t-Button--stretch"
	
	class="t-Button hot"
	

   
