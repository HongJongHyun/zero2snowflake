// 컨텍스트 설정
USE ROLE tasty_data_engineer ;
USE WAREHOUSE tasty_de_wh ;
USE DATABASE frostbyte_tasty_bytes ;
USE SCHEMA raw_pos ;

// 쿼리 수행 #1
SELECT l.country, l.city, year(order_ts), min(order_amount), avg(order_amount), max(order_amount)
  FROM order_header h
       LEFT OUTER JOIN location l
         ON h.location_id = l.location_id 
 GROUP BY ALL
 ORDER BY 1,2,3
;

// 웨어하우스 크기 변경
ALTER WAREHOUSE tasty_de_wh SET WAREHOUSE_SIZE = 'SMALL' ;

// 쿼리 수행 #2
SELECT l.country, l.city, year(order_ts), min(order_amount), avg(order_amount), max(order_amount)
  FROM order_header h
       LEFT OUTER JOIN location l
         ON h.location_id = l.location_id 
 GROUP BY ALL
 ORDER BY 1,2,3
;

// 웨어하우스 변경
USE WAREHOUSE tasty_dev_wh ;

// 쿼리 수행 #3
SELECT l.country, l.city, year(order_ts), min(order_amount), avg(order_amount), max(order_amount)
  FROM order_header h
       LEFT OUTER JOIN location l
         ON h.location_id = l.location_id 
 GROUP BY ALL
 ORDER BY 1,2,3
;

// 쿼리 수행 #4 
SELECT l.country, 
       l.city, 
       year(order_ts), 
       min(order_amount), 
       avg(order_amount), 
       max(order_amount)
  FROM order_header h
       LEFT OUTER JOIN location l
         ON h.location_id = l.location_id 
 GROUP BY ALL
 ORDER BY 1,2,3
;