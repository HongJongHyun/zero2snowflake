// 컨텍스트 설정
USE ROLE sysadmin ;
USE WAREHOUSE demo_build_wh ;
USE DATABASE frostbyte_tasty_bytes ;
USE SCHEMA raw_pos ;

// order_header 테이블 생성
CREATE OR REPLACE TABLE order_header
(
    order_id NUMBER(38,0),
    truck_id NUMBER(38,0),
    location_id FLOAT,
    customer_id NUMBER(38,0),
    discount_id VARCHAR(16777216),
    shift_id NUMBER(38,0),
    shift_start_time TIME(9),
    shift_end_time TIME(9),
    order_channel VARCHAR(16777216),
    order_ts TIMESTAMP_NTZ(9),
    served_ts VARCHAR(16777216),
    order_currency VARCHAR(3),
    order_amount NUMBER(38,4),
    order_tax_amount VARCHAR(16777216),
    order_discount_amount VARCHAR(16777216),
    order_total NUMBER(38,4)
);
// order_detail 테이블 생성
CREATE OR REPLACE TABLE order_detail 
(
    order_detail_id NUMBER(38,0),
    order_id NUMBER(38,0),
    menu_item_id NUMBER(38,0),
    discount_id VARCHAR(16777216),
    line_number NUMBER(38,0),
    quantity NUMBER(5,0),
    unit_price NUMBER(38,4),
    price NUMBER(38,4),
    order_item_discount_amount VARCHAR(16777216)
);

// 웨어하우스 조회
SHOW WAREHOUSES LIKE 'demo%' ;

// 웨어하우스 크기 변경
ALTER WAREHOUSE demo_build_wh 
  SET warehouse_size = 'small' ;

// order_header 데이터 검증
COPY INTO order_header
FROM @public.s3load/raw_pos/order_header/
     file_format = (format_name = 'public.csv_ff')
     validation_mode=return_all_errors
;

// order_header 데이터 적재
COPY INTO order_header
FROM @public.s3load/raw_pos/order_header/
     file_format = (format_name = 'public.csv_ff')
;

// 웨어하우스 크기 변경
ALTER WAREHOUSE demo_build_wh 
  SET warehouse_size = 'medium' ;

// 웨어하우스 조회
SHOW WAREHOUSES LIKE 'demo%' ;

// order_header 테이블 truncate
TRUNCATE TABLE order_header ;

// order_header 데이터 적재
COPY INTO order_header
FROM @public.s3load/raw_pos/order_header/
     file_format = (format_name = 'public.csv_ff')
;

// 데이터 파일 목록 조회
LIST @public.s3load/raw_pos/order_header/ ;

// 데이터 파일 크기 계산
SELECT floor(sum($2) / power(1024, 3), 1) as total_compressed_storage_gb,
       floor(avg($2) / power(1024, 2), 1) as avg_file_size_mb,
       count(*) as num_files
  FROM table(result_scan(last_query_id()))
;

// order_header 테이블 조회
SHOW TABLES LIKE 'order%'; 

// 웨어하우스 크기 변경
ALTER WAREHOUSE demo_build_wh 
  SET warehouse_size = 'large' ;

// 웨어하우스 조회
SHOW WAREHOUSES LIKE 'demo%' ;

// order_detail 데이터 적재
COPY INTO order_detail
FROM @public.s3load/raw_pos/order_detail/
     file_format = (format_name = 'public.csv_ff')
;

// order_header 테이블 조회
SHOW TABLES LIKE 'order%'; 


