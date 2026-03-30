// 컨텍스트 설정
USE ROLE tasty_data_engineer;
USE DATABASE frostbyte_tasty_bytes ;

// harmonized 스키마에 orders_v 뷰 생성
CREATE OR REPLACE VIEW harmonized.orders_v AS
SELECT oh.order_id,
       oh.truck_id,
       oh.order_ts,
       od.order_detail_id,
       od.line_number,
       m.truck_brand_name,
       m.menu_type,
       t.primary_city,
       t.region,
       t.country,
       t.franchise_flag,
       t.franchise_id,
       f.first_name AS franchisee_first_name,
       f.last_name AS franchisee_last_name,
       l.location_id,
       cl.customer_id,
       cl.first_name,
       cl.last_name,
       cl.e_mail,
       cl.phone_number,
       cl.children_count,
       cl.gender,
       cl.marital_status,
       od.menu_item_id,
       m.menu_item_name,
       od.quantity,
       od.unit_price,
       od.price,
       oh.order_amount,
       oh.order_tax_amount,
       oh.order_discount_amount,
       oh.order_total
  FROM raw_pos.order_detail od
  JOIN raw_pos.order_header oh
    ON od.order_id = oh.order_id
  JOIN raw_pos.truck t
    ON oh.truck_id = t.truck_id
  JOIN raw_pos.menu m
    ON od.menu_item_id = m.menu_item_id
  JOIN raw_pos.franchise f
    ON t.franchise_id = f.franchise_id
  JOIN raw_pos.location l
    ON oh.location_id = l.location_id
  LEFT JOIN raw_customer.customer_loyalty cl
    ON oh.customer_id = cl.customer_id;

// analytics 스키마에 orders_v 뷰 생성
CREATE OR REPLACE VIEW analytics.orders_v AS
SELECT DATE(o.order_ts) AS date, * 
  FROM harmonized.orders_v o;

// 컨텍스트 설정
USE WAREHOUSE tasty_de_wh; 

// order_v를 이용하여 데이터 조회
SELECT o.date,
       SUM(o.price) AS daily_sales
  FROM frostbyte_tasty_bytes.analytics.orders_v o
 WHERE 1=1
   AND o.country = 'Germany'
   AND o.primary_city = 'Hamburg'
   AND DATE(o.order_ts) BETWEEN '2022-02-10' AND '2022-02-28'
 GROUP BY o.date
 ORDER BY o.date ASC;

 // 푸드 트럭 운영 국가의 날씨 데이터 조회 view 생성
CREATE OR REPLACE VIEW harmonized.daily_weather_v AS
SELECT hd.*,
       TO_VARCHAR(hd.date_valid_std, 'YYYY-MM') AS yyyy_mm,
       pc.city_name AS city,
       c.country AS country_desc
  FROM weather_source.onpoint_id.history_day hd
  JOIN weather_source.onpoint_id.postal_codes pc
    ON pc.postal_code = hd.postal_code
   AND pc.country = hd.country
  JOIN raw_pos.country c
    ON c.iso_country = hd.country
   AND c.city = hd.city_name;

 // 2022년 2월의 함부르크의 일평균 기온
SELECT dw.country_desc,
       dw.city_name,
       dw.date_valid_std,
       AVG(dw.avg_temperature_air_2m_f) AS avg_temperature_air_2m_f
  FROM harmonized.daily_weather_v dw
 WHERE 1=1
   AND dw.country_desc = 'Germany'
   AND dw.city_name = 'Hamburg'
   AND YEAR(date_valid_std) = '2022'
   AND MONTH(date_valid_std) = '2'
 GROUP BY dw.country_desc, dw.city_name, dw.date_valid_std
 ORDER BY dw.date_valid_std DESC;

// 2022년 2월의 함부르크의 일 최대 풍속
SELECT dw.country_desc,
       dw.city_name,
       dw.date_valid_std,
       MAX(dw.max_wind_speed_100m_mph) AS max_wind_speed_100m_mph
  FROM harmonized.daily_weather_v dw
 WHERE 1=1
   AND dw.country_desc IN ('Germany')
   AND dw.city_name = 'Hamburg'
   AND YEAR(date_valid_std) = '2022'
   AND MONTH(date_valid_std) = '2'
 GROUP BY dw.country_desc, dw.city_name, dw.date_valid_std
 ORDER BY dw.date_valid_std DESC ;

// 화씨를 섭씨로
CREATE OR REPLACE FUNCTION analytics.fahrenheit_to_celsius(temp_f NUMBER(35,4))
RETURNS NUMBER(35,4)
AS
$$
    (temp_f - 32) * (5/9)
$$;

// 인치를 밀리미터로
CREATE OR REPLACE FUNCTION analytics.inch_to_millimeter(inch NUMBER(35,4))
RETURNS NUMBER(35,4)
AS
$$
    inch * 25.4
$$;

// 매출과 날씨
SELECT fd.date_valid_std AS date,
       fd.city_name,
       fd.country_desc,
       ZEROIFNULL(SUM(odv.price)) AS daily_sales,
       ROUND(AVG(fd.avg_temperature_air_2m_f),2) AS avg_temperature_fahrenheit,
       ROUND(AVG(analytics.fahrenheit_to_celsius(fd.avg_temperature_air_2m_f)),2) AS avg_temperature_celsius,
       ROUND(AVG(fd.tot_precipitation_in),2) AS avg_precipitation_inches,
       ROUND(AVG(analytics.inch_to_millimeter(fd.tot_precipitation_in)),2) AS avg_precipitation_millimeters,
       MAX(fd.max_wind_speed_100m_mph) AS max_wind_speed_100m_mph
  FROM harmonized.daily_weather_v fd
  LEFT JOIN harmonized.orders_v odv
    ON fd.date_valid_std = DATE(odv.order_ts)
   AND fd.city_name = odv.primary_city
   AND fd.country_desc = odv.country
 WHERE 1=1
   AND fd.country_desc = 'Germany'
   AND fd.city = 'Hamburg'
   AND fd.yyyy_mm = '2022-02'
 GROUP BY fd.date_valid_std, fd.city_name, fd.country_desc
 ORDER BY fd.date_valid_std ASC;

// 매출과 날씨 뷰
CREATE OR REPLACE SECURE VIEW analytics.daily_city_metrics_v AS
SELECT fd.date_valid_std AS date,
       fd.city_name,
       fd.country_desc,
       ZEROIFNULL(SUM(odv.price)) AS daily_sales,
       ROUND(AVG(fd.avg_temperature_air_2m_f),2) AS avg_temperature_fahrenheit,
       ROUND(AVG(analytics.fahrenheit_to_celsius(fd.avg_temperature_air_2m_f)),2) AS avg_temperature_celsius,
       ROUND(AVG(fd.tot_precipitation_in),2) AS avg_precipitation_inches,
       ROUND(AVG(analytics.inch_to_millimeter(fd.tot_precipitation_in)),2) AS avg_precipitation_millimeters,
       MAX(fd.max_wind_speed_100m_mph) AS max_wind_speed_100m_mph
  FROM harmonized.daily_weather_v fd
  LEFT JOIN harmonized.orders_v odv
    ON fd.date_valid_std = DATE(odv.order_ts)
   AND fd.city_name = odv.primary_city
   AND fd.country_desc = odv.country
 WHERE 1=1
 GROUP BY fd.date_valid_std, fd.city_name, fd.country_desc
 ORDER BY fd.date_valid_std ASC;

// 함부르크의 2022년 2월의 일별 매출액과 평균 기온, 평균 강우량, 최대 풍속
SELECT dcm.date,
       dcm.city_name,
       dcm.country_desc,
       dcm.daily_sales,
       dcm.avg_temperature_celsius,
       dcm.avg_precipitation_millimeters,
       dcm.max_wind_speed_100m_mph
  FROM analytics.daily_city_metrics_v dcm
 WHERE 1=1
   AND dcm.country_desc = 'Germany'
   AND dcm.city_name = 'Hamburg'
   AND dcm.date BETWEEN '2022-02-01' AND '2022-02-28'
 ORDER BY date DESC;

// 공유할 테이블 생성
CREATE OR REPLACE TABLE analytics.daily_hamburg_202202
AS
SELECT dcm.date,
       dcm.city_name,
       dcm.country_desc,
       dcm.daily_sales,
       dcm.avg_temperature_celsius,
       dcm.avg_precipitation_millimeters,
       dcm.max_wind_speed_100m_mph
  FROM analytics.daily_city_metrics_v dcm
 WHERE 1=1
   AND dcm.country_desc = 'Germany'
   AND dcm.city_name = 'Hamburg'
   AND dcm.date BETWEEN '2022-02-01' AND '2022-02-28' ;

SELECT CURRENT_ACCOUNT();

 