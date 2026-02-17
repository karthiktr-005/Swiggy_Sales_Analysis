USE [Swiggy Database]

SELECT * FROM swiggy_data

--Data Validation & Cleaning
--Null Check
SELECT
	SUM(case when State is null then 1 else 0 end) as null_state,
	SUM(case when City is null then 1 else 0 end) as null_city,
	SUM(case when Order_Date is null then 1 else 0 end) as null_order_Date,
	SUM(case when Restaurant_Name is null then 1 else 0 end) as null_Restaurant_Name,
	SUM(case when Location is null then 1 else 0 end) as null_Location,
	SUM(case when Category is null then 1 else 0 end) as null_Category,
	SUM(case when Dish_Name is null then 1 else 0 end) as null_Dish_Name,
	SUM(case when Price_INR is null then 1 else 0 end) as null_price_INR,
	SUM(case when Rating is null then 1 else 0 end) as null_Rating,
	SUM(case when Rating_count is null then 1 else 0 end) as null_Rating_count
FROM swiggy_data;

--Blank or Empty String
SELECT * 
FROM swiggy_data
WHERE state =''or City =''or Restaurant_Name ='' or Location ='' or Category='' or Dish_Name='';

--Duplicate Detection
SELECT state, city, order_date, Restaurant_Name, Location, Category, Dish_Name, Price_INR, Rating, Rating_Count,Count(*) as CNT 
FROM swiggy_data
GROUP BY state, city, order_date, Restaurant_Name, Location, Category, Dish_Name, Price_INR, Rating,Rating_Count
HAVING Count(*)>1;

--Duplicate Removal
WITH CTE AS (
SELECT *, ROW_NUMBER() OVER(
PARTITION BY state, city, order_date, Restaurant_Name, Location, Category, Dish_Name, Price_INR, Rating, Rating_Count
ORDER BY (SELECT NULL)
) AS rn
FROM swiggy_data
)
DELETE FROM CTE WHERE rn>1;


--CREATING SCHEMA
--DIMENSION TABLE
--DATE TABLE

CREATE TABLE dim_date (
date_id INT IDENTITY(1,1) PRIMARY KEY,
Full_Date DATE,
Year INT,
Month INT,
Month_Name VARCHAR(20),
Quarter INT,
Day INT,
weeK INT
);

CREATE TABLE dim_location (
location_id INT IDENTITY(1,1) PRIMARY KEY,
State VARCHAR(100),
City VARCHAR(100),
LOCATION VARCHAR(200)
);

CREATE TABLE dim_restaturant(
restaturant_id INT IDENTITY(1,1) PRIMARY KEY,
Restaturant_Name VARCHAR(200)
);

CREATE TABLE dim_category(
category_id INT IDENTITY(1,1) PRIMARY KEY,
Category VARCHAR(200)
);

CREATE TABLE dim_dish(
dish_id INT IDENTITY(1,1) PRIMARY KEY,
Dish_Name VARCHAR(200)
);
 
--FACT TABLE
CREATE TABLE fact_swiggy_orders(
order_id INT IDENTITY(1,1) PRIMARY KEY,
date_id INT,
Price_INR DECIMAL(10,2),
Rating DECIMAL(4,2),
Rating_Count INT,
location_id INT,
restaturant_id INT,
category_id INT,
dish_id INT,

FOREIGN KEY (date_id) REFERENCES dim_date(date_id),
FOREIGN KEY (location_id) REFERENCES dim_location(location_id),
FOREIGN KEY (restaturant_id) REFERENCES dim_restaturant(restaturant_id),
FOREIGN KEY (category_id) REFERENCES dim_category(category_id),
FOREIGN KEY (dish_id) REFERENCES dim_dish(dish_id)
); 

--INSERT DATA IN  TABLES
INSERT INTO dim_date(Full_Date,Year,Month,Month_Name,Quarter,Day,weeK)
SELECT DISTINCT
order_date,
YEAR(order_date),
MONTH(order_date),
DATENAME(MONTH, order_date),
DATEPART(QUARTER, order_date),
DAY(order_date),
DATEPART(WEEK, order_date)
FROM swiggy_data
WHERE Order_date IS NOT NULL;

SELECT * FROM dim_date;

--dim_location
INSERT INTO dim_location (State, City ,LOCATION)
SELECT DISTINCT
STATE,
CITY,
LOCATION
FROM swiggy_data;

SELECT * FROM dim_location;

--dim_restaturant
INSERT INTO dim_restaturant(Restaturant_Name)
SELECT DISTINCT
Restaurant_Name
FROM swiggy_data;

SELECT * FROM dim_restaturant;

--dim_category
INSERT INTO dim_category(Category)
SELECT DISTINCT
Category
FROM swiggy_data;

SELECT * FROM dim_category;

--dim_dish
INSERT INTO dim_dish(Dish_Name)
SELECT DISTINCT
Dish_Name
FROM swiggy_data;

SELECT * FROM dim_dish;

--fact table
INSERT INTO fact_swiggy_orders
(
date_id,
Price_INR,
Rating,
Rating_Count,
location_id,
restaturant_id,
category_id,
dish_id
)
SELECT 
dd.date_id,
s.Price_INR,
s.Rating,
s.Rating_Count,
dl.location_id,
dr.restaturant_id,
dc.category_id,
dsh.dish_id
FROM swiggy_data s

JOIN dim_date dd
ON dd.Full_Date = s.Order_Date

JOIN dim_location dl
ON dl.state = s.State
AND dl.City = s.City
AND dl.LOCATION = s.Location

JOIN dim_restaturant dr
ON dr.Restaturant_Name = s.Restaurant_Name

JOIN dim_category dc
ON dc.Category = s.Category

JOIN dim_dish dsh
ON dsh.Dish_name = s.Dish_Name; 


SELECT * FROM fact_swiggy_orders;


SELECT * FROM fact_swiggy_orders f
JOIN dim_date d on f.date_id = d.date_id
JOIN dim_location l on f.location_id = l.location_id
JOIN dim_restaturant r on f.restaturant_id = r.restaturant_id
JOIN dim_category c on f.category_id = c.category_id
JOIN dim_dish di on f.dish_id = di.dish_id ;

--KPI's
--Total Orders
SELECT COUNT(*) As Total_Orders
FROM fact_swiggy_orders;

--Total Revenue
SELECT SUM(Price_INR) AS Total_Revenue
FROM fact_swiggy_Orders;

--Average Dish Price(INR Million)
SELECT AVG(Price_INR) AS Average_Dish_Price
FROM fact_swiggy_Orders;

--Average Rating
SELECT AVG(Rating) AS Average_Rating
FROM fact_swiggy_Orders;

                                --- Business Analysis ---


--Deep-Dive Business Analysis
--Monthly Order Trends

SELECT
d.year,
d.month,
d.month_name,
count(*) AS Total_Orders
FROM fact_swiggy_orders f
JOIN dim_date as d
ON f.date_id = d.date_id
GROUP BY d.year,d.month,d.Month_Name
ORDER BY count(*) DESC;
 
--Quarterly order trends

SELECT
d.year,
d.Quarter,
count(*) AS Total_Orders
FROM fact_swiggy_orders f
JOIN dim_date as d
ON f.date_id = d.date_id
GROUP BY d.year,d.Quarter
ORDER BY count(* ) DESC;

--Year-wise growth

SELECT
d.year,
count(*) AS Total_Orders
FROM fact_swiggy_orders f
JOIN dim_date as d
ON f.date_id = d.date_id
GROUP BY d.year
ORDER BY count(* ) DESC;

--Orders by Day of Week (Mon-Sun)

SELECT
	DATENAME(WEEKDAY,d.full_date) AS day_name,
	COUNT(*) AS Total_Orders 
FROM fact_Swiggy_Orders f
JOIN dim_date d on f.date_id = d.date_id
GROUP BY DATENAME(WEEKDAY, d.full_date), DATEPART(WEEKDAY,d.full_date)
ORDER BY DATEPART(WEEKDAY, d.full_date);

--Location Based Analysis
--Top 10 Cities by order volume

SELECT TOP 10
l.city,
COUNT(*) AS Total_Orders
FROM fact_swiggy_Orders f
JOIN dim_location l
ON l.location_id = f.location_id
GROUP BY l.city
ORDER BY COUNT(*)DESC
; 

--Revenue contribution by states

SELECT 
l.state,
SUM(f.price_INR) AS Total_Revenue FROM
fact_swiggy_orders f
JOIN dim_location l
on l.location_id = f.location_id
GROUP BY l.state
ORDER BY SUM(f.price_INR) DESC;

--Food Performance
-- Top 10 restatuants by orders

SELECT
r.Restaturant_Name,
SUM(f.price_INR) AS Total_Orders
FROM fact_swiggy_Orders f
JOIN dim_restaturant r
ON r.restaturant_id = f.restaturant_id
GROUP BY r.Restaturant_Name
ORDER BY SUM(f.price_INR)DESC ;

--Top categories (Indian, Chinese, etc.)

SELECT 
c.category,
COUNT(*) AS Total_Orders
FROM fact_swiggy_orders f
JOIN dim_category c
ON c.category_id = f.category_id
GROUP BY Category
ORDER BY Total_Orders DESC;

--Most Ordered Dishes

SELECT TOP 10
d.dish_Name,
COUNT(*) AS Total_Orders
FROM fact_swiggy_Orders f
JOIN dim_dish d
ON d.dish_id = f.dish_id
GROUP BY dish_Name
ORDER BY Total_Orders DESC;

--Cuisine performance 

SELECT 
c.category,
COUNT(*) AS Total_Orders,
AVG(f.rating) AS Avg_Rating
FROM fact_swiggy_orders f
JOIN dim_category c 
ON f.category_id = c.category_id
GROUP BY category
ORDER BY Total_orders DESC; 

--Total orders by Price Range

SELECT 
	CASE 
		WHEN CONVERT(FLOAT, price_INR) < 100 THEN 'Under 100'
		WHEN CONVERT(FLOAT, price_INR) BETWEEN 100 AND 199 THEN '100-199'
		WHEN CONVERT(FLOAT, price_INR) BETWEEN 200 AND 299 THEN '200-299'
		WHEN CONVERT(FLOAT, price_INR) BETWEEN 300 AND 499 THEN '300-499'
		ELSE '500+'
	END AS Price_Range,
	COUNT(*) AS Total_orders
FROM fact_swiggy_orders
GROUP BY 
	CASE
	    WHEN CONVERT(FLOAT, price_INR) < 100 THEN 'Under 100'
		WHEN CONVERT(FLOAT, price_INR) BETWEEN 100 AND 199 THEN '100-199'
		WHEN CONVERT(FLOAT, price_INR) BETWEEN 200 AND 299 THEN '200-299'
		WHEN CONVERT(FLOAT, price_INR) BETWEEN 300 AND 499 THEN '300-499'
		ELSE '500+'
	END
ORDER BY Total_orders DESC;

--Rating Count Distributiion(1-5)

SELECT 
rating,
COUNT(*) AS Rating_Count
FROM fact_swiggy_Orders
GROUP BY rating
ORDER BY rating DESC;

