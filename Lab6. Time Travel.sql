// 컨텍스트 설정
USE ROLE sysadmin ;
USE WAREHOUSE tasty_de_wh ;
USE DATABASE frostbyte_tasty_bytes ;
USE SCHEMA raw_pos ;

// 푸드 트럭의 연식 조회
SELECT truck_id, year, make, model, (year(current_date()) - year) as truck_age
  FROM truck_dev ;

// 컬럼 추가
ALTER TABLE truck_dev 
  ADD COLUMN truck_age number(4) ;
 
// 추가된 컬럼에 데이터 업데이트
UPDATE truck_dev 
   SET truck_age = (year(current_date()) - year) ; 

// 데이터 확인   
SELECT truck_id, year, make, model, truck_age
  FROM truck_dev ;

// 푸드 트럭 제조사
SELECT distinct make 
  FROM truck_dev ;

// 데이터 수정
UPDATE truck_dev
   SET make = 'Ford'
-- WHERE make = 'Ford_' --oops
;

// 데이터 확인   
SELECT truck_id, year, make, model, truck_age
  FROM truck_dev ;

// 쿼리 히스토리 검사
SELECT query_id,
       query_text,
       user_name,
       query_type,
       start_time
  FROM TABLE(information_schema.query_history())
 WHERE 1=1
   AND query_type = 'UPDATE'
   AND query_text LIKE '%truck_dev%'
 ORDER BY start_time DESC;

// query_id 변수
SET query_id = 
(
    SELECT TOP 1 query_id
      FROM TABLE(information_schema.query_history())
     WHERE 1=1
       AND query_type = 'UPDATE'
       AND query_text LIKE '%truck_dev%'
     ORDER BY start_time DESC
);   

SELECT $query_id ;

// Time Travel 쿼리를 이용하여 테이블 복구
CREATE OR REPLACE TABLE truck_dev AS 
SELECT * FROM truck_dev
BEFORE (STATEMENT => $query_id);

// 데이터 확인   
SELECT truck_id, year, make, model, truck_age
  FROM truck_dev ;

// 데이터 수정
UPDATE truck_dev
   SET make = 'Ford'
 WHERE make = 'Ford_' 
;

// 데이터 확인   
SELECT truck_id, year, make, model, truck_age
  FROM truck_dev ;

// 테이블 교체
ALTER TABLE truck_dev SWAP WITH truck;

// 푸드 트럭 제조사 확인
SELECT distinct make 
  FROM truck ;

// 푸드 트럭 제조사 확인
SELECT distinct make 
  FROM truck_dev ;

  // 테이블 드롭
DROP TABLE truck_dev ; 
DROP TABLE truck ; --oops 

// 테이블 언드롭
UNDROP TABLE truck ; 

