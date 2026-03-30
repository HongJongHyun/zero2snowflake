// 컨텍스트 설정
USE ROLE sysadmin ;
USE WAREHOUSE tasty_de_wh ;
USE DATABASE frostbyte_tasty_bytes ;
USE SCHEMA raw_pos ;

// CTAS 수행
CREATE OR REPLACE TABLE order_detail_ctas AS
SELECT * FROM order_detail ;


// Clone 수행
CREATE OR REPLACE TABLE order_detail_clone 
 CLONE order_detail ;

// 테이블 정보 확인
SHOW TABLES LIKE 'order_detail%' ;

// 클론 테이블에 데이터 추가
INSERT INTO order_detail_clone
SELECT * replace(1000000000 + order_detail_id as order_detail_id) 
  FROM order_detail
 WHERE unit_price > 20
;

// 테이블 정보 확인
SHOW TABLES LIKE 'order_detail%' ;

