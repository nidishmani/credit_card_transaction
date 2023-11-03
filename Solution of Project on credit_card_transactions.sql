select* from credit_card_transcations


--1- write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends 
--Solution-1
with cte1 as (
select sum(cast(amount as bigint)) as total_spent
from credit_card_transcations
)
select top 5 city, sum(amount) as spent, total_spent, cast(sum(amount)*1.0/total_spent*100 as decimal(5,2)) as perc_contribution
from credit_card_transcations
inner join cte1 on 1=1
group by city, total_spent
order by spent desc
-------------------

--2- write a query to print highest spend month and amount spent in that month for each card type
--Solution-2
with cte1 as (
select card_type, datename(month,transaction_date) as transaction_month, datepart(year,transaction_date) as transaction_year, sum(amount) as monthly_expense
from credit_card_transcations
group by card_type, datename(month,transaction_date), datepart(year,transaction_date)
--order by card_type, monthly_expense desc
)
, cte2 as (
select*, rank() over(partition by card_type order by monthly_expense desc) as rnk
from cte1)

select* from cte2
where rnk='1'
-------------

--3- write a query to print the transaction details(all columns from the table) for each card type when
--it reaches a cumulative of 10,00,000 total spends(We should have 4 rows in the o/p one for each card type)
--Solution-3

select* from credit_card_transcations

with cte1 as (
select*, sum(amount) over(partition by card_type order by transaction_date,transaction_id rows between unbounded preceding and current row) as cumm_expense
from credit_card_transcations)
, cte2 as (
select*, rank() over(partition by card_type order by cumm_expense) as rnk from cte1 
where cumm_expense >=1000000)

select* from cte2
where rnk='1'
-------------

--4- write a query to find city which had lowest percentage spend for gold card type
--Solution-4

select* from credit_card_transcations

with cte1 as (
select  city, sum(amount) as total_expense
from credit_card_transcations
group by city
)
, cte2 as (
select city, card_type, sum(amount) as gold_expense
from credit_card_transcations
where card_type='Gold'
group by city, card_type
)

select top 1 cte2.city, total_expense, gold_expense, cast(gold_expense*1.0/total_expense*100 as decimal(5,2)) as percentage_gold_spend
from cte2
inner join cte1 on cte1.city=cte2.city
order by percentage_gold_spend asc
-----------------------------------

--5- write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)
--Solution-5
select* from credit_card_transcations

with cte as (
select city, exp_type, sum(amount) as total_expense
from credit_card_transcations
group by city, exp_type
--order by city, total_expense desc
)
,cte2 as (
select*, rank() over(partition by city order by total_expense desc) as rnk_high
, rank() over(partition by city order by total_expense) as rnk_low
from cte)

select city
,max(case when rnk_high=1 then exp_type end) as highest_expense_type
,max(case when rnk_low=1 then exp_type end) as lowest_expense_type
from cte2
where rnk_high=1 or rnk_low=1
group by city
-------------

--6- write a query to find percentage contribution of spends by females for each expense type
--Solution-6
select* from credit_card_transcations

with cte as (
select exp_type, sum(cast(amount as bigint)) as total_spend
from credit_card_transcations
group by exp_type
)
, cte2 as (
select exp_type, gender, sum(amount) as total_female_spend
from credit_card_transcations
where gender='F'
group by exp_type, gender
)
select cte2.exp_type, total_spend, total_female_spend, cast(total_female_spend*1.0/total_spend*100 as decimal (5,2)) as perc_female_contri
from cte2
inner join cte on cte2.exp_type=cte.exp_type
---------------------------------------------

--7- which card and expense type combination saw highest month over month growth in Jan-2014
--Solution-7
select* from credit_card_transcations

with cte as (
select card_type,exp_type,datepart(year,transaction_date) yt
,datepart(month,transaction_date) mt,sum(amount) as total_spend
from credit_card_transcations
group by card_type,exp_type,datepart(year,transaction_date),datepart(month,transaction_date)
)
select  top 1 *, (total_spend-prev_mont_spend) as mom_growth
from (
select *,lag(total_spend,1) over(partition by card_type,exp_type order by yt,mt) as prev_mont_spend
from cte) A
where prev_mont_spend is not null and yt=2014 and mt=1
order by mom_growth desc
-------------------------

--8- during weekends which city has highest total spend to total no of transcations ratio 
--Solution-8
select* from credit_card_transcations

select top 1 city, sum(amount)*1.0/count(transaction_id) as ratio
from credit_card_transcations
where datepart(weekday,transaction_date) in (1,7)
group by city
order by ratio desc
--------------------

--9- which city took least number of days to reach its 500th transaction after the first transaction in that city
--Solution-9

with cte as (
select*, row_number() over (partition by city order by transaction_date,transaction_id) as rnk
from credit_card_transcations
)
select top 1 city, min(transaction_date) as first_transac, max(transaction_date) as end_transac
, datediff(day,min(transaction_date),max(transaction_date)) as diff_bet_1_500
from cte
where rnk in (1,500)
group by city
having count(*)=2
order by diff_bet_1_500
-----------------------