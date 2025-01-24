1st requset --     Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.

Select distinct market from dim_customer
where customer = "AtliQ Exclusive" and region = "APAC"
order by market

-- 2. What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields,
					unique_products_2020
					unique_products_2021
					percentage_chg
with f20 as (
			select count(distinct(product_code)) as unique_products_2020 
			from fact_sales_monthly 
			where fiscal_year = 2020) , 
     f21 as (
			select count(distinct(product_code)) as unique_products_2021
			from fact_sales_monthly 
			where fiscal_year = 2021)
 
select unique_products_2020,unique_products_2021,
round((unique_products_2021-unique_products_2020)*100/unique_products_2020,2) as percentage_change
from f20 ,f21

-- 3. Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. 
-- The final output contains 2 fields,
				segment
				product_count
select segment , count(product) as product_count from dim_product
group by segment
order by product_count DESC


-- 4. Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? The final output contains these fields,
							segment
							product_count_2020
							product_count_2021
							difference

with x as (
			select segment, count(distinct(p.product_code)) as product_count_2020 
			from dim_product p
            join fact_sales_monthly f
            using (product_code)
			where fiscal_year = 2020
            group by segment) , 
     y as (
			select segment, count(distinct(p.product_code)) as product_count_2021
			from  dim_product p
            join  fact_sales_monthly f
            using (product_code)
			where fiscal_year = 2021
            group by segment)
 
select x.segment,product_count_2020,product_count_2021,
(product_count_2021-product_count_2020) as difference
from x 
join y 
using(segment)
order by difference desc;

-- 5. Get the products that have the highest and lowest manufacturing costs.The final output should contain these fields,
						product_code
						product
						manufacturing_cost
	
    select p.product_code,p.product,m.manufacturing_cost
from dim_product p
join fact_manufacturing_cost as m
using(product_code)
where manufacturing_cost 
IN ( 
	SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost
    UNION
    SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost
    ) 
order by manufacturing_cost desc


-- 6. Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the
-- Indian market. The final output contains these fields,
						customer_code
						customer
						average_discount_percentage
select c.customer_code, c.customer, round(avg(pre_invoice_discount_pct*100),2) as average_discount_percentage
from dim_customer c
join fact_pre_invoice_deductions pre
using (customer_code)
where c.market = "india" and pre.fiscal_year = 2021
group by customer
order by average_discount_percentage desc 
limit 5;

-- 7. Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. This analysis helps to get an idea of low and
-- high-performing months and take strategic decisions.The final report contains these columns:
						Month
						Year
						Gross sales Amount

select monthname(fs.date) as month , fs.fiscal_year as year ,
	   round(sum(g.gross_price*fs.sold_quantity),2) as Gross_sales_amount
from fact_sales_monthly fs
 join dim_customer c
 using (customer_code)
 join fact_gross_price g
 using (product_code)
 where c.customer = "AtliQ Exclusive"
 group by month,year
 order by year
 
 
-- 8. In which quarter of 2020, got the maximum total_sold_quantity? The final output contains these fields sorted by the total_sold_quantity,
							Quarter
							total_sold_quantity
							 
 Select 
	CASE 
		WHEN MONTH(date) in (9,10,11) THEN "Q1"
		WHEN MONTH(date) in (12,1,2) THEN "Q2"
		WHEN MONTH(date) in (3,4,5) THEN "Q3"
		ELSE "Q4"
	END AS Quarter,
    sum(sold_quantity) as total_sold_quantity
from fact_sales_monthly
where fiscal_year = 2020
group by quarter 
order by total_sold_quantity desc

-- 9. Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? The final output contains these fields,
						channel
						gross_sales_mln
						percentage
with cte as(
		   select c.channel ,
				   concat(round((sum(g.gross_price*fs.sold_quantity))/1000000,2),'M') as Gross_sales_mln
           from fact_sales_monthly fs
			 join dim_customer c
			 using (customer_code)
			 join fact_gross_price g
			 using (product_code)
			 where fs.fiscal_year = 2021
			 group by channel)

select channel,Gross_sales_mln,concat(round((Gross_sales_mln/(SELECT sum(Gross_sales_mln) FROM cte))*100 , 2) ,' %') as percentage 
from cte 
order by percentage DESC

-- Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? The final output contains these 
							fields, 
							division 
							product_code 
							product 
							total_sold_quantity 
							rank_order


with x as (
    select p.division, p.product_code, p.product, sum(s.sold_quantity) as total_sold_quantity
    from dim_product p
    join fact_sales_monthly s
    using (product_code)
    where fiscal_year = 2021
    group by p.division, p.product_code, p.product
    order by total_sold_quantity
),
y as (
    select 
        *,
        dense_rank() over (partition by division order by total_sold_quantity desc) as drnk
    from x
)
select * from y
where drnk <= 3
order by division, drnk

