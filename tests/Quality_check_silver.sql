/*
===============================================================
Quality Checks
===============================================================
Script Purpose:
    This script performs various quality checks for data consistency, accuracy,
    and standardization across the 'silver' schemas. It includes checks for:
    - Null or duplicate primary keys.
    - Unwanted spaces in string fields.
    - Data standardization and consistency.
    - Invalid date ranges and orders.
    - Data consistency between related fields.

Usage Notes:
    - Run these checks after data loading Silver Layer.
    - Investigate and resolve any discrepancies found during the checks.
===============================================================
*/
-- ================================================================
-- Checking 'silver.crm_cust_info'
-- ================================================================
--Quality check : a primary key must be unique and not null
select cst_id, count (*) as cnt from silver.crm_cust_info
group by cst_id
having count (*) >1 or cst_id is null; 

select cst_id,
row_number() over (partition by cst_id order by cst_create_date desc) as flag_last
from silver.crm_cust_info
where cst_id in (29449,29473,29433,29483,29466) and cst_id is not null


--Quality check : check for unwanted spaces in string values
select cst_firstname, cst_lastname
from silver.crm_cust_info
where cst_firstname != Trim (cst_firstname)  or cst_firstname !=Trim(cst_lastname);

--Data standardization & consistency
select distinct cst_marital_status, cst_gndr
	from silver.crm_cust_info order by cst_marital_status desc
-- ================================================================
-- Checking 'silver.crm_prd_info'
-- ================================================================

--Quality check : a primary key must be unique and not null
--check for nulls or duplicated in primary key
--expectation: no result

select prd_id, count (*) as cnt from silver.crm_prd_info
group by prd_id
having count (*) >1 or prd_id is null; 


--Quality check : check for unwanted spaces
--expectation : no results
select prd_nm
from silver.crm_prd_info
where prd_nm != Trim (prd_nm) ;

--Quality check : check for Null or negative numbers
--expectation : no results
select prd_cost
from silver.crm_prd_info
where prd_cost < 0 or prd_cost is null ;


--Data standardization & consistency
select distinct prd_line
	from silver.crm_prd_info

--check for invalid Date orders
select * from silver.crm_prd_info 
where  prd_end_dt < prd_start_dt

select * from silver.crm_prd_info
-- ================================================================
-- Checking 'silver.crm_sales_details'
-- ================================================================
-- Quality check of silver layer to identify any data quality issues(crm_prd_info table)


select sls_ord_num, sls_prd_key, sls_cust_id, sls_order_dt, sls_ship_dt, sls_due_dt, sls_sales, sls_quantity, sls_price
from silver.crm_sales_details

--Quality check : a primary key must be unique and not null
select sls_ord_num, count (*) as cnt from silver.crm_sales_details
group by sls_ord_num
having count (*) >1 or sls_ord_num is null; 


--Quality check : check for unwanted spaces in string values
--Trim() removes leading and trailing spaces fom a string
select sls_ord_num
from silver.crm_sales_details
where sls_ord_num != Trim (sls_ord_num) ;

--Quality check of PK & FK
select sls_ord_num,
sls_prd_key,
sls_cust_id,
sls_order_dt,
sls_ship_dt,
sls_due_dt,
sls_sales,
sls_quantity,
sls_price
from silver.crm_sales_details
where (sls_prd_key not in (select prd_key from silver.crm_prd_info))
or 
(sls_cust_id not in (select cst_id from silver.crm_cust_info))

--quality check for invalid Dates
--Nullif(): returns null if two given values are equal;otherwise, it returns the first expresion.
-- Check invalid order dates
SELECT *
FROM silver.crm_sales_details
WHERE sls_order_dt IS NULL
   OR sls_order_dt > '2050-01-01'
   OR sls_order_dt < '1900-01-01';


-- Check invalid ship dates
SELECT *
FROM silver.crm_sales_details
WHERE sls_ship_dt IS NULL
   OR sls_ship_dt > '2050-01-01'
   OR sls_ship_dt < '1900-01-01';


-- Check invalid due dates
SELECT *
FROM silver.crm_sales_details
WHERE sls_due_dt IS NULL
   OR sls_due_dt > '2050-01-01'
   OR sls_due_dt < '1900-01-01';

--Quality check : for invalid Date orders 
select * from silver.crm_sales_details
where sls_order_dt > sls_ship_dt or sls_order_dt > sls_due_dt 

--Quality check : check Data consistency :between sales, Quantity, and price
--sales= quantity * price
-- values must not be null, zero, or negative
--ABS() : returns absolute value of a number 
--solution 1 : data issues will be fixed direc in source system 
--solution 2: dataa issues has to be fixed in data warehouse according to business rules
select distinct
sls_sales ,
sls_quantity,
sls_price 
from silver.crm_sales_details
where sls_sales != sls_quantity * sls_price
or sls_sales is null 
or sls_quantity is null 
or sls_price is null 
or sls_sales <= 0 
or sls_quantity <=0
or sls_price <=0
order by sls_sales,
sls_quantity,
sls_price;



select distinct
sls_sales as old_sls_sales,
sls_quantity,
sls_price as old_sls_price,

case when sls_sales is null or sls_sales <= 0 or sls_sales != sls_quantity * abs(sls_price) 
then sls_quantity * abs(sls_price) 
else sls_sales
End as sls_sales,

case when sls_price is null or sls_price <= 0 then sls_sales / nullif(sls_quantity,0)
else sls_price
end as sls_price
from silver.crm_sales_details
order by sls_sales,
sls_quantity,
sls_price;

SELECT *
FROM silver.crm_sales_details;

-- ================================================================
-- Checking 'silver.erp_cust_az12'
-- ================================================================
-- Quality check of silver layer to identify any data quality issues(erp_cust_az12 table)
select cid, bdate, gen
from [silver].[erp_cust_az12]

--Quality check : a primary key must be unique and not null
select cid, count (*) as cnt from [silver].[erp_cust_az12]
group by cid
having count (*) >1 or cid is null; 

--Quality check : 
select 
substring(cid,4,len(cid)) as cid,
bdate,
gen
from [silver].[erp_cust_az12]
--methode 1 : 
SELECT
    SUBSTRING(cid, 4, LEN(cid) - 3) AS cid,
    bdate,
    gen
FROM silver.erp_cust_az12;
--methode 2 :
select 
case when cid like 'NAS%' then substring (cid, 4 , len(cid) )
else cid
end as cid,
bdate,
gen
from [silver].[erp_cust_az12]
where case when cid like 'NAS%' then substring (cid, 4 , len(cid) )
else cid
end not in (select distinct cst_key from [silver].[crm_cust_info])

--quality check for Identity out - of - range Dates
SELECT
    SUBSTRING(cid, 4, LEN(cid) - 3) AS cid,
    bdate,
    gen
FROM silver.erp_cust_az12
where bdate < '1924-02-02' or bdate > getdate()

--Quality check: data standardization & consistency 
SELECT
gen, count (*) as cnt
FROM silver.erp_cust_az12
group by gen

  --methode 1 :
  select distinct gen , case when gen = 'M' then 'Male'
    when gen= 'F' then 'Female'
    when gen = ' ' then 'n/a'
    when gen is null then 'n/a'
    else gen 
    end as gen
    from silver.erp_cust_az12
--methode 2:
  select distinct gen , 
  case when upper(trim(gen)) in ('F','FEMALE') then 'Female'
    when upper(trim(gen)) in ('M','MALE') then 'Male'
    else 'n/a' 
    end as gen
    from silver.erp_cust_az12
-- ================================================================
-- Checking 'silver.erp_loc_a101'
-- ================================================================
-- Quality check of silver layer to identify any data quality issues(crm_prd_info table)

select 
replace (cid,'-','' ) as cid,
cntry
from Silver.erp_loc_a101
where replace (cid,'-','')  not in (
select [cst_key] from bronze.crm_cust_info) 

--Data standardazation & consistency
select distinct cntry from Silver.erp_loc_a101
select 
distinct cntry as old,
case when trim(cntry) like 'DE%' then 'Germany'
when trim(cntry) in ('US', 'USA') then 'United States'
when trim(cntry) is null or trim(cntry) ='' then 'n/a'
else cntry
end as cntry
from Silver.erp_loc_a101
order by cntry
-- ================================================================
-- Checking 'silver.erp_px_cat_g1v2'
-- ================================================================
-- Quality check of silver layer to identify any data quality issues(erp_px_cat_g1v2 table)
select id, cat, subcat, maintenance
from silver.erp_px_cat_g1v2
where id not in (select cat_id from silver.crm_prd_info);

--Quality check : check for unwanted spaces in string values
--Trim() removes leading and trailing spaces fom a string
select *
from silver.erp_px_cat_g1v2
where cat != Trim (cat) or subcat != Trim(subcat) or maintenance != Trim(maintenance);

-- Quality check: Data consistency & standardazation 
select distinct cat
from silver.erp_px_cat_g1v2
select distinct subcat
from silver.erp_px_cat_g1v2
select distinct maintenance
from silver.erp_px_cat_g1v2

--final querry of transformation 
select id, cat, subcat, maintenance
from silver.erp_px_cat_g1v2
