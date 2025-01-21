--1. 1 Write a query to get a list of patients with event type 
--of EGV and  glucose (mgdl) greater than 155.

select patientid from demographics
join eventtype
on eventtype.id = demographics.patientid
where eventtype.event_type= 'EGV' and glucose_value_mgdl > 155 
group by patientid;

--2.How many patients consumed meals with at least 20 grams of protein in it?

select count(distinct patientid) from foodlog
where protein >= 20;

--3.Who consumed maximum calories during dinner? 
---(assuming the dinner time is after 6pm-8pm)

select patientid, calorie, datetime from foodlog 
where cast(datetime as time) >= '18:00:00' and cast(datetime as time) <= '20:00:00'   
order by calorie desc 


--4.Which patient showed a high level of stress on most days recorded for him/her?

with hrvstress as (
	select patientid,
	count(distinct (datestamp::date)) as hrvday 
	from ibi
	where rmssd_ms*600 < 20 
	group by patientid),
edastress as(select patientid,
	count(distinct (datestamp::date)) as edaday
	from eda
	where mean_eda > 40  
	group by patientid),
hrstress as 
	(select patientid,
	count(distinct (datestamp::date)) as no_of_days 
	from hr
	where mean_hr > 100
	group by patientid)
select * from hrstress union
select * from edastress union
select * from hrvstress 
order by no_of_days desc
limit 1;


--5.Based on mean HR and HRV alone, which patient would be considered least healthy?
select patientid,hrv,mean_hr from (
select ibi.patientid,avg(ibi.rmssd_ms*600) as hrv, hr.mean_hr from ibi 
join hr 
on ibi.patientid=hr.patientid
where (ibi.rmssd_ms*600) < 20 and hr.mean_hr >100) healthy
group by patientid,hrv,mean_hr 
order by patientid;

select hr.patientid, hr.mean_hr, (ibi.rmssd_ms * 600) as hrv
from hr
left join ibi on ibi.patientid = hr.patientid
where mean_hr > 100 
and (ibi.rmssd_ms * 600) > 20 
group by patientid,hrv,mean_hr 
order by hrv  desc;


--6. Create a table that stores any Patient Demographics of your choice
--as the parent table. Create a child table that contains max_EDA and mean_HR per patient and inherits all columns
--from the parent table

create table patient_demo as
(select patientid,gender,dob from demographics);

create table edahr_child 
( max_eda decimal,
  mean_hr decimal ) inherits (patient_demo);

select * from patient_demo;

insert into edahr_child
( select d.patientid,d.gender,d.dob,hr.mean_hr,eda.max_eda 
  from patient_demo d
  join eda on d.patientid = eda.patientid
  join hr on d.patientid = hr.patientid
 group by d.patientid,d.gender,d.dob,hr.mean_hr,eda.max_eda
 order by d.patientid
);

select * from edahr_child;

--7.What percentage of the dataset is male vs what percentage is female?

SELECT gender,
   concat (COUNT(patientid) * 100 / (SELECT COUNT(*) FROM demographics),'%') AS percentage
FROM demographics
GROUP BY gender;

--8.Which patient has the highest max eda?
select distinct(patientid), max(max_eda) from eda
group by patientid
order by max (max_eda) desc
limit 1;

--9.Display details of the prediabetic patients.
select * from demographics
where hba1c between 5.7 and 6.4;

--10.List the patients that fall into the highest EDA category by name, gender and age

select d.gender,concat (d.firstname || ' ' || d.lastname ) as Patient_name,
  extract (YEAR FROM age(CURRENT_DATE, dob)) AS age , e.patientid,
  max(e.max_eda) from demographics d
join eda e
on d.patientid=e.patientid
group by e.patientid, d.gender, Patient_name, e.max_eda, age
having (max(e.max_eda) > 20)
order by e.patientid;

--11.How many patients have names starting with 'A'?
select patientid,count(firstname) as count_of_name from demographics 
where firstname like 'A%'
group by patientid;

--12.Show the distribution of patients across age.
SELECT 
       EXTRACT(year FROM age('11-23-2023',dob)) AS patient_age,
       COUNT(patientid)
FROM demographics
GROUP BY patient_age 
ORDER BY patient_age ;
  
 --13.Display the Date and Time in 2 seperate columns for the patient 
 --who consumed only Egg
select patientid,logged_food, (datetime :: date ) as date , (datetime:: time ) as time
from foodlog
where logged_food = 'Egg';

--14.Display list of patients along with the gender and hba1c for whom 
--the glucose value is null.

select demographics.patientid,gender,hba1c 
from demographics 
join dexcom
on demographics.patientid = dexcom.patientid
where dexcom.glucose_value_mgdl is null
group by demographics.patientid;


select demographics.patientid,gender,hba1c 
from demographics 
join eventtype
on demographics.patientid = eventtype.id
where eventtype.glucose_value_mgdl is null
group by demographics.patientid;

--15.Rank patients in descending order of Max blood glucose value per day
select * from dexcom;

select (datestamp :: date ) as date, max(glucose_value_mgdl) ,patientid from dexcom
group by patientid,date
order by patientid;


--16.Assuming the IBI per patient is for every 10 milliseconds, 
--calculate Patient-wise HRV from RMSSD.
select patientid, avg(rmssd_ms*600) as hrv
from ibi
group by patientid
order by patientid;

--17.What is the % of total daily calories consumed by patient 14 after 3pm Vs
--Before 3pm?
select patientid,calorie from foodlog
where cast(datetime as time) > '15:00:00' and cast(datetime as time) < '15:00:00'
and patientid = 14 
group by patientid,calorie;

select * from demographics;


--18.Display 5 random patients with HbA1c less than 6.

select * from demographics
where hba1c < 6
order by random()
limit 5;

--19.Generate a random series of data using any column from any table as the base.

select * from demographics
order by random()+ hba1c
limit 5;


--20.Display the foods consumed by the youngest patient 

select f.patientid,f.logged_food, age('11-23-2023',dob) AS patient_age
from foodlog f
join demographics d
on f.patientid = d.patientid
group by f.patientid,f.logged_food,patient_age
order by patient_age asc;

select young-patient,logged_food from young_patient yp
(select age('11-23-2023',dob) as age from demographics
 	order by age asc
 	limit 1 )

--21.Identify the patients that has letter 'h' in their first name and print the last letter of their first name.

SELECT firstname as patientfirstname, RIGHT(firstname, 1) as lastletter
FROM demographics
where firstname like '%h%';

--22.Calculate the time spent by each patient outside the recommended blood glucose range
select * from dexcom;

--23.Show the time in minutes recorded by the Dexcom for every patient

select patientid,trunc(extract(epoch from(max(datestamp)-min(datestamp)))/60,1) as aggtotal
from dexcom 
group by patientid
order by patientid;

--24.List all the food eaten by patient Phill Collins
select logged_food from foodlog 
join demographics 
on foodlog.patientid= demographics.patientid
where demographics.firstname = 'Phill' and demographics.lastname ='Collins'
group by logged_food;

--25.Create a stored procedure to delete the min_EDA column in the table EDA

--26.When is the most common time of day for people to consume spinach?
select extract (hour from datetime) as loggedhour, count(*) as consumedcount  from foodlog
where logged_food like '%Spinach%'
group by loggedhour
order by consumedcount desc;

--27.Classify each patient based on their HRV range as high, low or normal

--29.Display a pie chart of gender vs average HbA1c

SELECT 
	gender,
	AVG(hba1c) 
FROM demographics
GROUP BY gender
ORDER BY gender;

--30.The recommended daily allowance of fiber is approximately 25 grams a day. What % of this does every patient get on average?

SELECT
    fl.patientid,
    ROUND(AVG(fl.dietary_fiber),3)AS avg_fiber_consumed,
    ROUND((AVG(fl.dietary_fiber) / 25.0) * 100, 3) AS percentage_of_daily
FROM
    foodlog fl
GROUP BY
    fl.patientid;
	
--31.What is the relationship between EDA and Mean HR? 

select corr(mean_eda,mean_hr) as relationship_eda_and_hr 
from eda join hr 
on eda.patientid=hr.patientid ;

--32.Show the patient that spent the maximum time out of blood glucose range.

--33.Create a User Defined function that returns min glucose value and patient ID for any date entered.


--34.Write a query to find the day of highest mean HR value for each patient and display it along with the patient id.
select datestamp,mean_hr,patientid from 
(select patientid,rank()over( partition by patientid order by mean_hr desc) as high_mean_hr , 
 mean_hr,
 datestamp from hr) X
where high_mean_hr =1 ;

--35.Create view to store Patient ID, Date, Avg Glucose value and Patient Day to every patient, ranging from 1-11 based on every patients minimum date and maximum date (eg: Day1,Day2 for each patient)

--36.Using width bucket functions, group patients into 4 HRV categories
 
select patientid , width_bucket(avg(rmssd_ms*600),0,70,4) as hrv
	from ibi
	group by patientid
	order by patientid;
select patientid, trunc(avg(rmssd_ms*600),2) from ibi
	group by patientid

--37.Is there a correlation between High EDA and  HRV. If so, display this data by querying the relevant tables?

select  max(mean_eda) as high_eda,
avg(rmssd_ms*600) as hrv from eda
join ibi
on eda.patientid=ibi.patientid
group by eda.patientid
order by eda.patientid;

--38.List hypoglycemic patients by age and gender

select d.patientid,gender,age('11-23-2023',dob) AS patient_age from demographics d
join dexcom de
on d.patientid = de.patientid
where glucose_value_mgdl < 70 
group by d.patientid;

--39.Write a query using recursive view(use the given dataset only)

with recursive demo as (
	select patientid,min_eda,max_eda,mean_eda,datestamp
	from eda e 
union 
	select h.patientid,h.min_hr,h.max_hr,h.mean_hr,h.datestamp
	from hr h
	join eda e  on e.patientid = h.patientid
)
select * from demo
order by patientid;

--40.Create a stored procedure that adds a column to table IBI. The column should just be the date part extracted from IBI.Date
create or replace procedure new_ibi ()
language plpgsql
 $$ 
select  * , cast(datestamp as date) from ibi 
end;
$$

--41.Fetch the list of Patient ID's whose sugar consumption exceeded 30 grams on a meal from FoodLog table. 
select distinct(patientid),sugar,logged_food from foodlog
where sugar > 30
order by patientid;

--42.How many patients are celebrating their birthday this month?

select count(patientid)  from demographics
 where extract(month from current_date)= extract (month from dob);

--43.How many different types of events were recorded in the Dexcom tables? Display counts against each Event type

select dexcom.eventid,eventtype.event_type from dexcom
join eventtype
on dexcom.eventid = eventtype.id
group by eventtype.event_type,dexcom.eventid;

--44.How many prediabetic/diabetic patients also had a high level of stress? 
select count (distinct (d.patientid))  from demographics d
join hr
on hr.patientid=d.patientid
where (mean_hr > 100 and d.hba1c >= 5.7);

--45.List the food that coincided with the time of highest blood sugar for every patient

--46.How many patients have first names with length >7 letters?
select count (patientid) from demographics
where length (firstname) > 7 ;

--47.List all foods logged that end with 'se'. Ensure that the output is in Title Case
select initcap (logged_food) as food_log from foodlog
where logged_food like '%se';

--48.List the patients who had a birthday the same week as their glucose or IBI readings
select date_part ('week',dob) , d.patientid from demographics d
join dexcom dx
on d.patientid=dx.patientid
join ibi i 
on d.patientid=i.patientid
where date_part('week',dob) = date_part('week',dx.datestamp) or 
date_part('week',dob) = date_part('week',i.datestamp)
group by d.patientid;

--49.Assuming breakfast is between 8 am and 11 am. How many patients ate a meal with bananas in it?
select patientid,logged_food from foodlog
where cast(datetime as time) > '08:00:00' and cast(datetime as time) < '11:00:00' and logged_food like '%Banana%';

--50.Create a User defined function that returns the age of any patient based on input

--51.Based on Number of hyper and hypoglycemic incidents per patient, which patient has the least control over their blood sugar?

select patientid,count (*) from demographics
where hba1c <70 and  hba1c >= 126
group by patientid;
select * from demographics
--52.Display patients details with event details and minimum heart rate
select d.patientid,d.dob,d.gender,d.hba1c,d.firstname,d.lastname,et.event_type,hr.min_hr from demographics d
join eventtype et
on d.patientid = et.id
join hr 
on d.patientid = hr.patientid
group by d.patientid,et.event_type,hr.min_hr
order by d.patientid;

--53.Display a list of patients whose daily max_eda lies between 40 and 50.
select datestamp,max_eda,patientid from eda
where  max_eda >= 40 and max_eda <= 50;

--54.Count the number of hyper and hypoglycemic incidents per patient

--55.What is the variance from mean  for all patients for the table IBI?
select patientid, variance(mean_ibi_ms)  as variance_ibi from ibi
group by patientid
order by patientid;

--56.Create a view that combines all relevant patient demographics and lab markers into one. Call this view ‘Patient_Overview’.
create view Patient_Overview as
select d.patientid,d.gender,d.hba1c,d.dob,d.firstname,d.lastname,
	 avg(de.glucose_value_mgdl)::numeric(10,2) as glucouse_level
from demographics d
join dexcom de
on d.patientid=de.patientid
group by d.patientid,d.gender,d.hba1c,d.dob,d.firstname,d.lastname
order by d.patientid;
 
--57.Create a table that stores an array of biomarkers: Min(Glucose Value), Avg(Mean_HR), Max(Max_EDA) for every patient. The result should look like this: (Link in next cell)
create table  patient_table as(
select de.patientid as pid,concat(min(de.glucose_value_mgdl),',',avg(hr.mean_hr),',',max(eda.max_eda)) as biomarkers 
from dexcom de
join hr
on de.patientid=hr.patientid
join eda
on de.patientid=eda.patientid
group by de.patientid
order by de.patientid);

select * from patient_table;

--58.Assuming lunch is between 12pm and 2pm. Calculate the total number of calories consumed by each patient for lunch on "2020-02-24"

select patientid,logged_food,sum(calorie) from foodlog
where (cast(datetime as time) >= '12:00:00' and cast(datetime as time) <= '14:00:00') and DATE(datetime) = '2020-02-24' 
group by patientid,logged_food;


--59.What is the total length of time recorded for each patient(in hours) in the Dexcom table?

--60.Display the first, last name, patient age and max glucose reading in one string for every patient.
select concat(d.firstname,',',d.lastname,',',age(d.dob),',',max(de.glucose_value_mgdl)) as patient_info
from demographics d
join dexcom de
on d.patientid=de.patientid
group by d.patientid
order by d.patientid;
 
--61.What is the average age of all patients in the database?
select trunc(avg(extract(year from age(dob))::numeric(10,2)),2) as patient_avg_age 
from demographics;

--62.Display All female patients with age less than 50
select patientid,gender,extract(year from age(dob)) as patient_age
from demographics
where gender = 'FEMALE' and extract(year from age(dob)) < 50
group by patientid;
 
--63.Display count of Event ID, Event Subtype and the first letter of the event subtype. Display all events 

select count(de.eventid),ev.event_type,ev.event_subtype,left(ev.event_subtype,1) as first_letter
from dexcom de
right join eventtype ev
on ev.id= de.eventid
group by de.eventid,ev.event_type,ev.event_subtype,first_letter;

--64.List the foods consumed by  the patient(s) whose eventype is "Estimated Glucose Value".

select fl.patientid,fl.logged_food,ev.event_subtype from foodlog fl
join eventtype ev
on fl.patientid=ev.id
where event_subtype = 'Estimated Glucose Value'
group by fl.patientid,fl.logged_food,ev.event_subtype;

--65.Rank the patients' health based on HRV and Control of blood sugar(AKA min time spent out of range)

--66.Create a trigger on the food log table that warns a person about any food logged that has more than 20 grams of sugar. The user should not be stopped from inserting the row. Only a warning is needed

--67.Display all the patients with high heart rate and prediabetic

select de.patientid,de.hba1c,hr.mean_hr as high_hr from demographics de
join hr
on de.patientid=hr.patientid
where (mean_hr)>100 and hba1c between 5.7 and 6.4
group by de.patientid,de.hba1c, high_hr;

--68.Display patients information who have tachycardia HR and a glucose value greater than 200.

select de.patientid,de.glucose_value_mgdl,hr.max_hr as tachycardia from dexcom de
join hr
on de.patientid=hr.patientid
where (max_hr)>100 and glucose_value_mgdl > 200
group by de.patientid,de.glucose_value_mgdl,tachycardia
order by de.patientid;


--69.Calculate the number of hypoglycemic incident per patient per day where glucose drops under 55
select (patientid),glucose_value_mgdl, (datestamp::date) as date from dexcom
where glucose_value_mgdl is not null and glucose_value_mgdl < 50
group by patientid, (datestamp::date),glucose_value_mgdl ;

--70.List the day wise calories intake for each patient.
select (datetime::date) as date ,sum (calorie) as total_calorie, patientid from foodlog
group by date,patientid
order by patientid;

--71.Display the demographic details for the patient that had the maximum time below recommended blood glucose range

select d.patientid,d.gender,d.dob,d.hba1c,d.firstname,d.lastname,de.glucose_value_mgdl, (datestamp::time) as time 
from demographics d
join dexcom de
group by d.patientid;

--72.How many patients have a minimum HR below the medically recommended level?
select count(distinct patientid) from hr
where min_hr < 60;

--73.Create a trigger to raise notice and prevent the deletion of a record from ‘Patient_Overview’ .

--74.What is the average heart rate, age and gender of the every patient in the dataset?

select age(d.dob),d.gender,trunc(avg(hr.mean_hr)::numeric,2) as avg_hr,d.patientid from demographics d
join hr 
on d.patientid=hr.patientid
group by d.patientid
order by d.patientid;

--75.What is the daily total calories consumed by every patient?
select (datetime::date) as date ,sum (calorie) as total_calorie, patientid from foodlog
group by date,patientid
order by patientid;

--76.Write a query to classify max EDA into 5 categories and display the number of patients in each category.
with eda_categries as (
	select patientid,width_bucket(max_eda,0,80,5) as eda
	from eda)
select eda,count( distinct patientid) as patient_count
from eda_categries
group by eda
order by eda;

select * from hr
--77.List the daily max HR for patient with event type Exercise.

select e.id,e.event_type,hr.datestamp,max(hr.max_hr),hr.patientid 
from hr
join eventtype e
on hr.patientid = e.id
where e.event_type = 'Exercise'
group by hr.patientid,e.id,e.event_type,hr.datestamp;

--78.What is the standard deviation from mean for all patients for the table HR?
select patientid, trunc(stddev (mean_hr)::numeric,2) as std_dev from hr
group by patientid
order by patientid;

--79.Give the demographic details of the patient with event type ID of 16.
select d.patientid,d.gender,d.dob,d.hba1c,d.firstname,d.lastname,de.eventid
from demographics d
join dexcom de
on d.patientid=de.patientid
where de.eventid='16'
group by d.patientid,d.gender,d.dob,d.hba1c,d.firstname,d.lastname,de.eventid
order by d.patientid;

--80.Display list of patients along with their gender having a tachycardia mean HR.

select d.patientid,d.gender,hr.mean_hr from demographics d
join hr
on d.patientid= hr.patientid
where hr.mean_hr > 100
group by d.patientid,d.gender,hr.mean_hr
order by d.patientid;
