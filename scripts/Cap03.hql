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