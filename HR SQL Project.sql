USE [Human Resource];
SELECT * 
FROM hr ;
 
SELECT *
FROM hr
WHERE COALESCE(Age,Attrition,Gender,StandardHours) IS NULL
-- Fortunately we do not have any null values so we can move forward

 --no. of employees in each departments and their roles
SELECT Department, JobRole,
       COUNT ( DISTINCT EmployeeNumber) AS total_employees
FROM hr 
WHERE Attrition = 'No'
GROUP BY Department, JobRole 
ORDER BY Department ASC ; 

--no. of aged employees
SELECT COUNT(*)AS elderly_no , 
       MAX(Age) AS oldest,
	   COALESCE(JobRole,'Total') AS JobRole
FROM hr 
WHERE Age > 45 
AND Attrition = 'No'
GROUP BY JobRole WITH ROLLUP;

--no. of freshers
SELECT COUNT(*)  AS Youngsters, 
       MIN(Age) AS youngest,
	   COALESCE(JobRole,'Total') AS JobRole
FROM hr
WHERE Age between 18 and 25 
AND Attrition = 'No'
GROUP BY JobRole WITH ROLLUP  ;

--min and max hourly rate based on job roles
SELECT MIN(HourlyRate)  AS min_hourly_rate,
       MAX(HourlyRate) AS max_hourly_rate,
       JobRole
FROM hr
GROUP BY JobRole;

 --employee with max income
SELECT Age, EmployeeNumber, MonthlyIncome, Department,JobRole, YearsAtCompany
FROM hr 
WHERE MonthlyIncome = (SELECT MAX(MonthlyIncome) FROM hr) ;

-- min income employee
SELECT Age, EmployeeNumber, MonthlyIncome, JobRole, YearsAtCompany
FROM hr 
WHERE MonthlyIncome = (SELECT MIN (MonthlyIncome) FROM hr);

--employee that might need salaryhike
SELECT EmployeeNumber,YearsAtCompany,PerformanceRating,JobInvolvement,PercentSalaryHike
FROM hr 
WHERE YearsAtCompany > 2 
AND PerformanceRating >= 3
AND JobInvolvement > 3
AND PercentSalaryHike <= (SELECT MIN(PercentSalaryHike) FROM hr) ;

--hardworkers
SELECT EmployeeNumber,JobLevel,JobRole
FROM hr
WHERE JobInvolvement = (SELECT MAX(JobInvolvement) FROM hr)
AND PerformanceRating = (SELECT max(PerformanceRating) FROM hr)
AND OverTime = 'Yes' ;

--calculating attrition rate 
SELECT 
 ( COUNT(CASE WHEN Attrition = 'Yes' THEN 1 END) / COUNT( DISTINCT EmployeeNumber) ) * 100 AS Attrition_rate
FROM hr;
---Got 0 as a result which is quite unlikely

--taking diff approach 
WITH AttritionCount AS (
  SELECT COUNT(CASE WHEN Attrition = 'Yes' THEN 1 END) AS Departures
  FROM hr
) --using CTE
SELECT 
  (CAST(Departures AS DECIMAL) / (SELECT COUNT(*) FROM hr)) * 100 AS AttritionRate 
FROM AttritionCount;
  -- casting to decimal for accurate percentage calculation

--attrition in diff departments 
SELECT Department,
       MAX(Attrition) AS depletion,
	   COUNT(*) AS no_of_employees
FROM hr
WHERE Attrition = 'Yes'
GROUP BY Department
ORDER BY COUNT(*) DESC ;

--we can see research & development has max attrition (133)
--lets first explore what could be the reason
--is it because they were unhappy with the company 
SELECT COUNT(*) AS unhappy_no_promotion_no_hike
FROM hr
WHERE JobSatisfaction = (SELECT MIN(JobSatisfaction) FROM hr)
AND YearsSinceLastPromotion = (SELECT MIN(YearsSinceLastPromotion) FROM hr)
AND PercentSalaryHike = (SELECT MIN(PercentSalaryHike) FROM hr)
AND Attrition = 'Yes' 
AND Department = 'Research & Development';
--no dont think so (5)

--could be because of promotion
SELECT COALESCE(CAST(YearsAtCompany AS varchar(10)), 'Total') AS YearsAtCompany,
       COUNT(*) AS employee_with_no_promotion
FROM hr
WHERE YearsSinceLastPromotion = 0 
AND Attrition = 'Yes'
AND Department = 'Research & Development'
AND YearsAtCompany >1
GROUP BY YearsAtCompany WITH ROLLUP;
-- (23) i dont think so 

--could it be younger generation
SELECT COALESCE(MaritalStatus, 'TOTAL') AS MaritalStatus,
       COALESCE(Gender, 'TOTAL') AS Gender,
       MIN(Age) AS min_age,
       COUNT(*) AS employees
FROM hr
WHERE Attrition = 'Yes' 
AND Department = 'Research & Development'
GROUP BY  Gender, MaritalStatus WITH ROLLUP;
--max were males (90), out of which 45 were singles and aged 18, 31 were married and 14 were divorced
--females were 43, 21 were single and age was 19 , 18 married, 4 divorced
-- we can say that young single people are most likely to resign in the research and development department 

--lets see what made them leave
SELECT JobSatisfaction, EnvironmentSatisfaction, COUNT(*) AS total
FROM hr
WHERE Attrition = 'Yes'
AND Department = 'Research & Development'
AND Age BETWEEN 18 AND 26
GROUP BY  JobSatisfaction,EnvironmentSatisfaction  
HAVING JobSatisfaction <= 2  and EnvironmentSatisfaction <=2 ;
-- no its not 
  
--is it promotion or salary hike 
SELECT  Age,PercentSalaryHike, YearsSinceLastPromotion,
        COUNT(*) AS total
FROM hr
WHERE Attrition = 'Yes'
AND Department = 'Research & Development'
AND Age between 18 and 26
GROUP BY Age, PercentSalaryHike, YearsSinceLastPromotion WITH ROLLUP
ORDER BY YearsSinceLastPromotion ASC;
--no
--the cause of resigning of most young employees is neither the office environment nor promotion and salary hike
--we can simply conclude that either they got extremely good options or they have yet to discover their passion.
--which compels us to wonder if it is time to upgrade our hiring criteria  
--or can also work on retainment of employees through certain programs or compensation

--lets look at the sales department attrition as well
SELECT COALESCE(MaritalStatus, 'TOTAL') AS MaritalStatus,
       COALESCE(Gender, 'TOTAL') AS Gender,
       MIN(Age) AS min_age,
       COUNT(*) AS employees
FROM hr
WHERE Attrition = 'Yes' 
AND Department = 'Sales'
GROUP BY  Gender, MaritalStatus WITH ROLLUP;
--same is the case in Sales department 

--HR 
SELECT COALESCE(MaritalStatus, 'Total') AS MaritalStatus,
       COALESCE(Gender, 'Total') AS Gender,
       MIN(Age) AS min_age,
       COUNT(*) AS employees
FROM hr
WHERE Attrition = 'Yes' 
AND Department = 'Human Resources'
GROUP BY  Gender, MaritalStatus WITH ROLLUP;
--HR department has comparartively less attrition to other departments

--lets move forward and look into the current staff
SELECT COUNT(*) AS total,
       TrainingTimesLastYear, PerformanceRating
FROM hr
WHERE Attrition = 'No'
GROUP BY  TrainingTimesLastYear, PerformanceRating
ORDER BY TrainingTimesLastYear ASC;
SELECT
AVG(PerformanceRating) AS avg_performance
FROM hr
WHERE Attrition = 'No';
--need to improve our training strategies 
--as not much diff is seen in staff performance betn 1 training session and multiple training session
--the avg performance rating is same i.e 3 

--different distance
SELECT DistanceFromHome,
       COUNT(*) AS total_employee,
       AVG(WorkLifeBalance) AS average_work_life_balance,
       AVG(JobInvolvement) AS average_Job_involvement,
	   AVG(PerformanceRating ) AS avg_performance_rating
FROM (SELECT CASE 
    WHEN  DistanceFromHome <= 5 THEN 'Short Distance'
    WHEN DistanceFromHome BETWEEN 6 AND 15 THEN 'Medium Distance'
    ELSE 'Long Distance'
    END AS DistanceFromHome, WorkLifeBalance,JobInvolvement,PerformanceRating
    FROM hr) AS traveler_groups 
GROUP BY DistanceFromHome; 
--distance from home has not affected the employees performance

--correlation betn travel and daily rate
ALTER TABLE hr
ADD travel_frequency INT;
UPDATE hr
SET travel_frequency = CASE 
    WHEN BusinessTravel = 'Travel_Rarely' THEN 1
    WHEN BusinessTravel = 'Travel_frequently' THEN 2
    ELSE NULL
END;-- converted the string value to int for better calculation
SELECT AVG(DailyRate) AS avg_daily_rate,
       AVG(HourlyRate) AS avg_hourly_rate,
       COUNT(*) AS total,
       CASE 
        WHEN travel_frequency = 1 THEN 'Rare Traveler'
        WHEN travel_frequency = 2 THEN 'Frequent Traveler'
        ELSE 'Non Traveler'
       END AS travel_category
FROM hr
WHERE Attrition = 'No'
GROUP BY travel_frequency;
-- looking at the table we can see that the avg hourly rate of rare travelers are more
-- while on the other hand the avg daily rate of non travelers are more

-- Distribution of hourly rates
SELECT 
  HourlyRate,
  COUNT(*) AS employee_count
FROM hr
WHERE Attrition = 'No'
GROUP BY HourlyRate
ORDER BY HourlyRate;

--performance with same manager 
SELECT YearsInCurrentRole, PerformanceRating 
FROM hr
WHERE YearsWithCurrManager > 2 
AND Attrition = 'No';
 
--single male employees performance
SELECT COALESCE(EmployeeNumber, 'TOTAL') AS total_employee,
       JobInvolvement, PerformanceRating
FROM hr
WHERE Gender = 'Male'
AND MaritalStatus = 'Single'
AND Age BETWEEN 18 ANd 26
AND Attrition = 'No';

--single female employees performance
SELECT COALESCE(EmployeeNumber, 'TOTAL') AS total_employee,
       JobInvolvement, PerformanceRating
FROM hr
WHERE Gender = 'Female' 
AND MaritalStatus = 'Single' 
AND Age BETWEEN 18 ANd 26 
AND Attrition = 'No';

SELECT AVG(JobSatisfaction)  AS average_job_satisfaction,
       AVG(EnvironmentSatisfaction) AS avg_environment_satisfaction
FROM hr
WHERE Attrition = 'NO';
 







 

