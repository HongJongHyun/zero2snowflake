// 컨텍스트 설정
USE ROLE sysadmin ;
USE WAREHOUSE demo_build_wh ;
USE DATABASE frostbyte_tasty_bytes ;
USE SCHEMA raw_pos ;

// 테이블 생성
CREATE OR REPLACE TABLE order_header_by_order_ts AS
SELECT * 
  FROM order_header 
 ORDER BY order_ts 
;

// 웨어하우스 생성
CREATE OR REPLACE WAREHOUSE tasty_de_wh
       WAREHOUSE_SIZE = 'xsmall'
       WAREHOUSE_TYPE = 'standard'
       AUTO_SUSPEND = 60
       AUTO_RESUME = TRUE
       INITIALLY_SUSPENDED = TRUE
;

// 웨어하우스 확인
SHOW WAREHOUSES ;

// 웨어하우스 지정
USE WAREHOUSE tasty_de_wh ;

// Partition Pruning
SELECT * FROM order_header_by_order_ts 
 WHERE order_ts between '2021-01-01 00:00:00' 
                    and '2022-01-01 00:00:00' 
;

// Partition Pruning
SELECT * FROM order_header_by_order_ts 
 WHERE order_ts between '2021-03-01 00:00:00' 
                    and '2021-03-02 00:00:00' 
;

