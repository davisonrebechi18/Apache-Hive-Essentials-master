beeline -n cloudera -p cloudera -u jdbc:hive2://localhost:10000

CREATE TABLE employee
(
name string,
work_place ARRAY<string>,
sex_age STRUCT<sex:string,age:int>,
skills_score MAP<string,int>,
depart_title MAP<string,ARRAY<string>>
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '|'
COLLECTION ITEMS TERMINATED BY ','
MAP KEYS TERMINATED BY ':';

--Verificar criação da tabela
!table employee

--Copiando arquivo do .txt para a tabela employee
LOAD DATA LOCAL INPATH '/home/cloudera/Downloads/employee.txt' OVERWRITE INTO TABLE employee;

--Criando DB
create database if not exists myhivebook
comment 'hive database demo'
location 'hdfs://quickstart.cloudera:8020/user/hive/warehouse/'
with dbproperties('creator'='davison','date'='2018-12-13');

alter database myhivebook
set dbproperties('edited-by'='Davison Rebechi');

--Criando uma tabela interna
CREATE TABLE IF NOT EXISTS employee_internal
(
 name string,
 work_place ARRAY<string>,
 sex_age STRUCT<sex:string,age:int>,
 skills_score MAP<string,int>,
 depart_title MAP<STRING,ARRAY<STRING>>
 )
 COMMENT 'This is an internal table'
 ROW FORMAT DELIMITED
 FIELDS TERMINATED BY '|'
 COLLECTION ITEMS TERMINATED BY ','
 MAP KEYS TERMINATED BY ':'
 STORED AS TEXTFILE;
 
 LOAD DATA LOCAL INPATH '/home/cloudera/Downloads/employee.txt' OVERWRITE INTO TABLE employee_internal;

--Criando uma tabela externa 
 CREATE EXTERNAL TABLE employee_external
 (
 name string,
 work_place ARRAY<string>,
 sex_age STRUCT<sex:string,age:int>,
 skills_score MAP<string,int>,
 depart_title MAP<STRING,ARRAY<STRING>>
 )
 COMMENT 'This is an external table'
 ROW FORMAT DELIMITED
 FIELDS TERMINATED BY '|'
 COLLECTION ITEMS TERMINATED BY ','
 MAP KEYS TERMINATED BY ':'
 STORED AS TEXTFILE
 LOCATION '/user/cloudera/employee';
 
 LOAD DATA LOCAL INPATH '/home/cloudera/Downloads/employee.txt' OVERWRITE INTO TABLE employee_external;
 
 --Criando uma tabela temporária
 create table ctas_employee
 as select * from employee_external;
 
 create table cte_employee as
 with r1 as
 (select name from r2
 where name= 'Michael'),
 r2 as 
 (select name from employee_external
 where sex_age.sex= 'Male'),
 r3 as 
 (select name from employee_external
 where sex_age.sex= 'Female')
 select * from r1 union all select * from r3;
 
 --1. Use CTAS as shown here:
 create table empty_ctas_employee as 
 select * from employee_internal where 1=2;
 
 --2. Use LIKE as shown here:
 create table empty_like_employee
 like employee_internal;
 
 select count(*) as row_cnt from empty_ctas_employee;
 select count(*) as row_cnt from empty_like_employee;
 
--The drop table’s command removes the metadata completely and moves data to
--Trash or to the current directory if Trash is configured:
 DROP TABLE IF EXISTS empty_ctas_employee;
 
 DROP TABLE IF EXISTS empty_like_employee;
 
 --Renomeando uma tabela
 ALTER TABLE cte_employee RENAME TO c_employee;
 
 --Alterar a propriedade da tabela
 ALTER TABLE c_employee
 SET TBLPROPERTIES ('comment'='New name, comments');
 
 -- Alterar o delimitador da tabela SERDEPROPERTIES:
 ALTER TABLE employee_internal SET
 SERDEPROPERTIES ('field.delim' = '$');
 
 -- Alterar o formato do arquivo da tabela
 ALTER TABLE c_employee SET FILEFORMAT RCFILE;
 
 -- Alterar o local da tablea, deve ter um completo URI do HDFS
ALTER TABLE c_employee
SET LOCATION
'hdfs://localhost:8020/user/cloudera/employee';

--CONCATENATE
--Mudando o tipo ou a ordem da coluna
ALTER TABLE employee_internal
CHANGE name employee_name string AFTER sex_age;

-- Add/replace columns:
--Add columns to the table
ALTER TABLE c_employee ADD COLUMNS (work string);

--HIVE PARTITIONS

--Criando partições quando criar tabelas
CREATE TABLE employee_partitioned
 (
 name string,
 work_place ARRAY<string>,
 sex_age STRUCT<sex:string,age:int>,
 skills_score MAP<string,int>,
 depart_title MAP<STRING,ARRAY<STRING>>
 )
 PARTITIONED BY (Year INT, Month INT)
 ROW FORMAT DELIMITED
 FIELDS TERMINATED BY '|'
 COLLECTION ITEMS TERMINATED BY ','
 MAP KEYS TERMINATED BY ':';
 
 --Mostrar partições
 SHOW PARTITIONS employee_partitioned;
 
 --Adicionar multiplas partições
 ALTER TABLE employee_partitioned ADD
 PARTITION (year=2014, month=11)
 PARTITION (year=2014, month=12);
 
 --Apagar a partição da tabela
ALTER TABLE employee_partitioned
DROP IF EXISTS PARTITION (year=2014, month=11);

--Load data to the partition:
LOAD DATA LOCAL INPATH 
'/home/cloudera/Downloads/employee.txt' 
OVERWRITE INTO TABLE employee_partitioned
PARTITION(year=2014, month=12);

SELECT name, year, month FROM employee_partitioned;

-- HIVE BUCKETS

--Prepare another dataset and table for bucket table
 CREATE TABLE employee_id
 (
 name string,
 employee_id int,
 work_place ARRAY<string>,
 sex_age STRUCT<sex:string,age:int>,
 skills_score MAP<string,int>,
 depart_title MAP<string,ARRAY<string>>
 )
 ROW FORMAT DELIMITED
 FIELDS TERMINATED BY '|'
 COLLECTION ITEMS TERMINATED BY ','
 MAP KEYS TERMINATED BY ':';
 
 LOAD DATA LOCAL INPATH 
'/home/cloudera/Hive_Essentials/data/employee_id.txt' 
OVERWRITE INTO TABLE employee_id

CREATE TABLE employee_id_buckets
 (
 name string,
 employee_id int,
 work_place ARRAY<string>,
 sex_age STRUCT<sex:string,age:int>,
 skills_score MAP<string,int>,
 depart_title MAP<string,ARRAY<string>>
 )
 CLUSTERED BY (employee_id) INTO 2 BUCKETS
 ROW FORMAT DELIMITED
 FIELDS TERMINATED BY '|'
 COLLECTION ITEMS TERMINATED BY ','
 MAP KEYS TERMINATED BY ':';
 
 set map.reduce.tasks = 2;
 set hive.enforce.bucketing = true;
 
 INSERT OVERWRITE TABLE employee_id_buckets
 SELECT * FROM employee_id;
 
 --Verify the buckets in the HDFS
hdfs dfs -ls /user/hive/warehouse/employee_id_buckets
Found 1 items
-rwxrwxrwx   1 cloudera supergroup       1473 2018-12-14 16:09 /user/hive/warehouse/employee_id_buckets/000000_0


--HIVE VIEWS
 create table employee as 
 select * from DEFAULT.employee;

CREATE VIEW employee_skills
AS
SELECT name, skills_score['DB'] AS DB,
skills_score['Perl'] AS Perl,
skills_score['Python'] AS Python,
skills_score['Sales'] as Sales,
skills_score['HR'] as HR
FROM employee;

-- alterar propriedade da view
ALTER VIEW employee_skills
SET TBLPROPERTIES ('comment' = 'This is a view');

--Alterar a view
ALTER VIEW employee_skills AS
SELECT * from employee;

--Apagando uma view
DROP VIEW employee_skills;