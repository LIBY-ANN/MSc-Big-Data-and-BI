--CREATION OF DIMENSION TABLES

--TIME DIMENSION TABLE
DROP TABLE TIME_DIM;
CREATE TABLE TIME_DIM
(
  TIME_ID NUMBER NOT NULL
, DATEVALUE DATE 
, DAY VARCHAR2(20)  
, MONTH VARCHAR2(20) 
, YEAR NUMBER 
, DAYNUMBEROFWEEK NUMBER 
, WEEKNUMBEROFYEAR NUMBER
, MONTHNUMBEROFYEAR NUMBER
, CALENDERQUARTER NUMBER  
, CONSTRAINT TIME_DIM_PK PRIMARY KEY
  (
    TIME_ID
  )
  ENABLE
);

---CREATE TABLE LOCAL_COUNCIL DIM

DROP TABLE Local_Council_DIM;
CREATE TABLE Local_Council_DIM
(
LocalCouncil_ID NUMBER(5) NOT NULL,
LocalCouncil_Name VARCHAR2(50),
AddressLine_1 VARCHAR2(50),
AddressLine_2 VARCHAR2(50),
Town VARCHAR2(50),
County VARCHAR2(20),
PostCode VARCHAR2(10),
CONSTRAINT LocalCouncil_PK PRIMARY KEY
  (
    LocalCouncil_ID
  )
  ENABLE
);


--CREATE TABLE TEMP_DIM

DROP TABLE TEMP_DIM
CREATE TABLE TEMP_DIM
(
  TEMP_ID NUMBER NOT NULL
, FIRSTNAME VARCHAR2(20)
, LASTNAME VARCHAR2(20)
, DATEOFBIRTH VARCHAR2(20)
, GENDER VARCHAR2(20)
, CONSTRAINT TEMP_DIM_PK PRIMARY KEY
  (
    TEMP_ID
  )
  ENABLE
);

---create table session_dim

DROP TABLE SESSION_DIM
CREATE TABLE SESSION_DIM
(
  SESSION_ID NUMBER NOT NULL
, SESSION_START VARCHAR2(20)
, SESSION_END VARCHAR2(20)
, CONSTRAINT SESSION_DIM_PK PRIMARY KEY
  (
    SESSION_ID
  )
  ENABLE
);


--create table temp_request_dim

DROP TABLE TEMP_REQUEST_DIM
CREATE TABLE TEMP_REQUEST_DIM
(
  TEMPREQUEST_ID NUMBER NOT NULL
, REQUEST_DATE DATE
, CONSTRAINT TEMP_REQUEST_DIM_PK PRIMARY KEY
  (
    TEMPREQUEST_ID
  )
  ENABLE
);

--create table temp_staff_fact[FACT_TABLE]

DROP TABLE TEMP_STAFF_FACT
CREATE TABLE TEMP_STAFF_FACT
(
  FACT_ID NUMBER(20) NOT NULL
, TEMP_ID NUMBER 
, SESSION_ID NUMBER
, LOCALCOUNCIL_ID NUMBER(5) 
, TIME_ID NUMBER 
, TEMPREQUEST_ID NUMBER
, STATUS VARCHAR2(20) 
, TYPE VARCHAR2(20) 
, BOOKING_HOURS NUMBER(3)
, CONSTRAINT TEMP_STAFF_FACT_PK PRIMARY KEY
  (
    FACT_ID
  )
  ENABLE
);

--1.CLEANSE AND POPULATE TEMP_REQUEST_DIM 

DECLARE
CURSOR c_temprequest is
SELECT "TempRequestID","Request date" FROM TEMP_REQUEST;

BEGIN
FOR c_rec IN c_temprequest LOOP

INSERT INTO TEMP_REQUEST_DIM VALUES(c_rec."TempRequestID",c_rec."Request date");
END LOOP;
END;

--2. CLEANSE AND POPULATE SESSION_DIM table

DECLARE
CURSOR c_session is
SELECT "SessionID",TO_CHAR(SessionEnd, 'HH24:MI:SS') AS endtime, TO_CHAR(SessionStart,'HH24:MI:SS') AS starttime
FROM SESSION_TABLE;

BEGIN
FOR c_rec IN c_session LOOP
IF c_rec.starttime IS NULL AND c_rec.endtime IS NOT NULL THEN c_rec.starttime:=c_rec.starttime;
ELSIF c_rec.starttime IS NULL AND c_rec.endtime IS NULL THEN c_rec.starttime:= '00:00:00';
END IF;
IF c_rec.endtime IS NULL AND c_rec.starttime IS NOT NULL THEN c_rec.endtime:=c_rec.endtime;
ELSIF c_rec.endtime IS NULL AND c_rec.starttime IS NULL THEN c_rec.endtime:= '00:00:00';
END IF;
INSERT INTO SESSION_DIM VALUES(c_rec."SessionID",c_rec.starttime,c_rec.endtime);
END LOOP;
END;


--3. CLEANSE AND POPULATE LOCAL_COUNCIL_DIM 

DELETE FROM LOCAL_COUNCIL WHERE"Town" IS NULL;

DECLARE
CURSOR c_LOCALCOUNCIL IS
SELECT "LocalCouncil_ID", "LocalCouncilName","Address Line 1","Address Line 2","Town","County","Postcode" from LOCAL_COUNCIL;

addr1 VARCHAR2(20);
addr2 VARCHAR2(20);

BEGIN
FOR c_rec IN c_LOCALCOUNCIL LOOP
IF c_rec."Address Line 1" IS NULL THEN addr1:=c_rec."Address Line 2";
ELSE addr1:=c_rec."Address Line 1";
END IF;
IF c_rec."Address Line 2" IS NULL THEN addr2:=c_rec."Address Line 1";
ELSE addr2:=c_rec."Address Line 2";
END IF;
IF c_rec."Address Line 1" IS NULL AND c_rec."Address Line 2" IS NULL
THEN addr1:=c_rec."Town";
addr2:=c_rec."Town";
END IF;

INSERT INTO LOCAL_COUNCIL_DIM VALUES(c_rec."LocalCouncil_ID",
c_rec."LocalCouncilName" ,addr1,addr2,c_rec."Town",c_rec."County" , c_rec."Postcode");
END LOOP;
END;

COMMIT;

--4. CLEANSE AND POPULATE TEMP_DIM Table

DECLARE
CURSOR c_TEMP is
SELECT "Temp_ID", "First Name", "Last Name", "Date of birth", "Gender" from "TEMP";
gen VARCHAR2(20);
fname VARCHAR2(20);
dob VARCHAR2(20);

BEGIN
FOR c_rec IN c_TEMP LOOP
IF c_rec."Gender" = 1 THEN gen := 'Female';
ELSIF c_rec."Gender" = 2 THEN gen := 'Male';
ELSE gen:= 'Not Known';
END IF;
IF c_rec."First Name" IS NULL THEN fname:= c_rec."Last Name";
ELSIF c_rec."First Name"='....................' THEN fname:='Not Set';
ELSE fname:= c_rec."First Name";
END IF;
IF c_rec."Date of birth" IS NULL THEN dob:= 'No Data';
ELSE dob:= c_rec."Date of birth";
END IF;

INSERT INTO "TEMP_DIM" VALUES(c_rec."Temp_ID",
fname,c_rec."Last Name",dob, gen);

END LOOP;
END;

COMMIT;

--5. CLEANSE AND POPULATE TIME_DIM table 

DROP SEQUENCE time_dim_seq;

CREATE SEQUENCE time_dim_seq
START WITH 1;

DECLARE
CURSOR c_TIMEDIM IS
SELECT  DISTINCT("SessionDate") FROM SESSION_TABLE;
BEGIN
FOR c_rec IN c_TIMEDIM LOOP
INSERT INTO TIME_DIM VALUES(
  time_dim_seq.nextval,
  c_rec."SessionDate",
  to_char(c_rec."SessionDate",'Day'),
  to_char(c_rec."SessionDate",'Month'),
  to_char(c_rec."SessionDate",'YYYY'),
  to_char(c_rec."SessionDate",'DD'),   
  to_char(c_rec."SessionDate",'IW'),
  to_char(c_rec."SessionDate",'MM'),
  to_char(c_rec."SessionDate",'YYYY')
  );
END LOOP;
END;


--6. CREATE AND POPULATE THE FACT TABLE

drop sequence fact_dim_seq;

CREATE SEQUENCE fact_dim_seq
START WITH 1;

DECLARE
CURSOR c_FACT IS

SELECT "Temp_ID" ,"SessionID","LocalCouncil_ID",TIME_ID,"RequestID","Status","Type",24*(SESSIONEND-SESSIONSTART)"BOOKED_HOURS"
FROM  SESSION_TABLE

LEFT OUTER JOIN TEMP ON SESSION_TABLE."TempID"=TEMP."Temp_ID"
LEFT OUTER JOIN TEMP_REQUEST ON SESSION_TABLE."RequestID"= TEMP_REQUEST."TempRequestID"
LEFT OUTER JOIN TIME_DIM ON TIME_DIM."DATEVALUE"= SESSION_TABLE."SessionDate";

cover_type VARCHAR2(20);
booked_hours NUMBER;

BEGIN

FOR c_rec IN c_FACT LOOP

IF c_rec."Type" = 1 THEN cover_type:= 'Shop Assistant';
ELSIF c_rec."Type" = 2 THEN cover_type:= 'Floor Manager';
ELSIF c_rec."Type" = 3 THEN cover_type:= 'Window Dresser';
ELSIF c_rec."Type" = 4 THEN cover_type:= 'Store Assistant';
ELSIF c_rec."Type" = 5 THEN cover_type:= 'Cleaner';
ELSIF c_rec."Type" = 6 THEN cover_type:= 'Cashier';
ELSE  cover_type:= 'Other';
END IF;

IF NVL(c_rec.booked_hours,0)=0 THEN booked_hours := 0;
            ELSE booked_hours := c_rec.booked_hours;
        END IF;
        

INSERT INTO TEMP_STAFF_FACT VALUES (fact_dim_seq.nextval,c_rec."Temp_ID",c_rec."SessionID",
c_rec."LocalCouncil_ID",c_rec.TIME_ID,c_rec."RequestID",c_rec."Status",cover_type,booked_hours);


END LOOP;
END;

UPDATE TEMP_STAFF_FACT
SET STATUS='booked' WHERE SESSION_ID=688;


--QUERY 1

SELECT f.TYPE,t.MONTH, COUNT(*) AS "Sessions filled monthwise"
FROM TEMP_STAFF_FACT f
INNER JOIN TIME_DIM t on f.TIME_ID=t.TIME_ID
WHERE f.STATUS = 'booked'
GROUP BY MONTH,TYPE
ORDER BY to_date(t.MONTH,'MM');

--QUERY 2

SELECT f.LOCALCOUNCIL_ID,t.WEEKNUMBEROFYEAR, COUNT(*) AS "week-wise requests made by councils"
FROM TEMP_STAFF_FACT f
INNER JOIN TIME_DIM t on f.TIME_ID=t.TIME_ID
GROUP BY WEEKNUMBEROFYEAR,LOCALCOUNCIL_ID
ORDER BY WEEKNUMBEROFYEAR;


--QUERY 3

SELECT l.COUNTY,t.MONTH, COUNT(*) AS "No.of temp_reqs filled by county"
FROM TEMP_STAFF_FACT f
INNER JOIN LOCAL_COUNCIL_DIM l on f.LOCALCOUNCIL_ID=l.LOCALCOUNCIL_ID
INNER JOIN TIME_DIM t on t.TIME_ID= f.TIME_ID
WHERE f.STATUS = 'booked'
GROUP BY l.COUNTY,t.month
ORDER BY l.COUNTY,to_date(t.month,'MM');

--QUERY 4: 

SELECT f.LOCALCOUNCIL_ID , t.WEEKNUMBEROFYEAR, COUNT(*) AS "Number of temp requests filled by council"
FROM TEMP_STAFF_FACT f
INNER JOIN TIME_DIM t on f.TIME_ID=t.TIME_ID WHERE f.STATUS='booked'
GROUP BY WEEKNUMBEROFYEAR, LOCALCOUNCIL_ID 
ORDER BY WEEKNUMBEROFYEAR;


---QUERY 5 :

SELECT t.MONTH, COUNT(*) AS "Number of Cancelled Requests" from TEMP_STAFF_FACT  f
INNER JOIN TIME_DIM t on f.TIME_ID = t.TIME_ID
WHERE STATUS LIKE '%Cancelled%'
GROUP BY t.MONTH
ORDER BY to_date(t.MONTH,'MM');

COMMIT;


--FACT TABLE USING PARTITION BY YEAR

(select f.TEMP_ID,f.LOCALCOUNCIL_ID, f.SESSION_ID,f.TEMPREQUEST_ID,
f.STATUS,f.TYPE  ,t.year, COUNT(t.year) OVER (PARTITION BY YEAR) 
from temp_staff_fact f
inner join time_dim t on f.time_id = t.time_id);




