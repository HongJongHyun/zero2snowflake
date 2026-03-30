// 데이터베이스 생성
USE ROLE sysadmin ;
CREATE OR REPLACE DATABASE frostbyte_tasty_bytes ;

// 사용할 데이터베이스 지정
USE ROLE sysadmin ; 
USE DATABASE frostbyte_tasty_bytes ;

// 스키마 생성
CREATE OR REPLACE SCHEMA raw_pos ;
CREATE OR REPLACE SCHEMA raw_customer;

// raw_pos를 기본 스키마로 지정
USE SCHEMA raw_pos ;

// 테이블 country 생성
CREATE OR REPLACE TABLE country
(
    country_id NUMBER(18,0),
    country VARCHAR(16777216),
    iso_currency VARCHAR(3),
    iso_country VARCHAR(2),
    city_id NUMBER(19,0),
    city VARCHAR(16777216),
    city_population VARCHAR(16777216)
);

// 테이블 franchise 생성
CREATE OR REPLACE TABLE franchise 
(
    franchise_id NUMBER(38,0),
    first_name VARCHAR(16777216),
    last_name VARCHAR(16777216),
    city VARCHAR(16777216),
    country VARCHAR(16777216),
    e_mail VARCHAR(16777216),
    phone_number VARCHAR(16777216) 
);

// 테이블 location 생성
CREATE OR REPLACE TABLE location
(
    location_id NUMBER(19,0),
    placekey VARCHAR(16777216),
    location VARCHAR(16777216),
    city VARCHAR(16777216),
    region VARCHAR(16777216),
    iso_country_code VARCHAR(16777216),
    country VARCHAR(16777216)
);

// 테이블 truck 생성
CREATE OR REPLACE TABLE truck
(
    truck_id NUMBER(38,0),
    menu_type_id NUMBER(38,0),
    primary_city VARCHAR(16777216),
    region VARCHAR(16777216),
    iso_region VARCHAR(16777216),
    country VARCHAR(16777216),
    iso_country_code VARCHAR(16777216),
    franchise_flag NUMBER(38,0),
    year NUMBER(38,0),
    make VARCHAR(16777216),
    model VARCHAR(16777216),
    ev_flag NUMBER(38,0),
    franchise_id NUMBER(38,0),
    truck_opening_date DATE
);

// raw_customer를 기본 스키마로 지정
USE SCHEMA raw_customer ;

// 테이블 customer_loyalty 생성
CREATE OR REPLACE TABLE customer_loyalty
(
    customer_id NUMBER(38,0),
    first_name VARCHAR(16777216),
    last_name VARCHAR(16777216),
    city VARCHAR(16777216),
    country VARCHAR(16777216),
    postal_code VARCHAR(16777216),
    preferred_language VARCHAR(16777216),
    gender VARCHAR(16777216),
    favourite_brand VARCHAR(16777216),
    marital_status VARCHAR(16777216),
    children_count VARCHAR(16777216),
    sign_up_date DATE,
    birthday_date DATE,
    e_mail VARCHAR(16777216),
    phone_number VARCHAR(16777216)
);

// 익스터널스테이지 생성 
CREATE OR REPLACE STAGE public.s3load
COMMENT = 'Quickstarts S3 Stage Connection'
url = 's3://sfquickstarts/frostbyte_tastybytes/'
;

// 익스터널스테이지의 파일 확인
LIST @public.s3load ;
LIST @public.s3load/raw_pos/ ;
LIST @public.s3load/raw_customer/ ;

// 파일 포맷 정의
CREATE OR REPLACE FILE FORMAT public.csv_ff 
type = 'csv';

// 파일 포맷 확인
SHOW FILE FORMATS IN DATABASE frostbyte_tasty_bytes ;

// raw_pos 스키마 지정
USE SCHEMA raw_pos ;

// country 테이블 데이터 적재 
COPY INTO country
FROM @public.s3load/raw_pos/country/
     file_format = (format_name = 'public.csv_ff')
;

// 웨어하우스 생성
CREATE OR REPLACE WAREHOUSE demo_build_wh
       WAREHOUSE_SIZE = 'xsmall'
       WAREHOUSE_TYPE = 'standard'
       AUTO_SUSPEND = 60
       AUTO_RESUME = TRUE
       INITIALLY_SUSPENDED = TRUE
;

// 웨어하우스 지정
USE WAREHOUSE demo_build_wh ;

// raw_pos 스키마 지정
USE SCHEMA raw_pos ;

// country 테이블 데이터 적재 
COPY INTO country
FROM @public.s3load/raw_pos/country/
     file_format = (format_name = 'public.csv_ff')
;

// raw_pos 스키마의 나머지 테이블 적재
USE SCHEMA raw_pos ;
// franchise 테이블 데이터 적재 
COPY INTO franchise
FROM @public.s3load/raw_pos/franchise/
     file_format = (format_name = 'public.csv_ff')
;
// location 테이블 데이터 적재
COPY INTO location
FROM @public.s3load/raw_pos/location/
     file_format = (format_name = 'public.csv_ff')
;
// truck 테이블 데이터 적재
COPY INTO truck
FROM @public.s3load/raw_pos/truck/
     file_format = (format_name = 'public.csv_ff')
;

// raw_customer스키마의 테이블 데이터 적재
USE SCHEMA raw_customer ;

COPY INTO customer_loyalty
FROM @public.s3load/raw_customer/customer_loyalty/
     file_format = (format_name = 'public.csv_ff')
;