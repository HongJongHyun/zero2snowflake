// 컨텍스트 설정
USE ROLE sysadmin ;
USE WAREHOUSE demo_build_wh ;
USE DATABASE frostbyte_tasty_bytes ;
USE SCHEMA raw_pos ;

// menu 테이블 생성
CREATE OR REPLACE TABLE menu
(
    menu_id NUMBER(19,0),
    menu_type_id NUMBER(38,0),
    menu_type VARCHAR(16777216),
    truck_brand_name VARCHAR(16777216),
    menu_item_id NUMBER(38,0),
    menu_item_name VARCHAR(16777216),
    item_category VARCHAR(16777216),
    item_subcategory VARCHAR(16777216),
    cost_of_goods_usd NUMBER(38,4),
    sale_price_usd NUMBER(38,4),
    menu_item_health_metrics_obj VARIANT
);

// menu 데이터 적재
COPY INTO menu
FROM @public.s3load/raw_pos/menu/
     file_format = (format_name = 'public.csv_ff')
;

// 컨텍스트 설정
USE ROLE tasty_data_engineer;
USE WAREHOUSE tasty_de_wh;
USE DATABASE frostbyte_tasty_bytes ;
USE SCHEMA raw_pos ;

// 데이터 조회
SELECT TOP 10
       m.truck_brand_name,
       m.menu_type,
       m.menu_item_name,
       m.menu_item_health_metrics_obj
  FROM menu m ;

// 점표기법
SELECT m.menu_item_health_metrics_obj:menu_item_id AS menu_item_id,
       m.menu_item_health_metrics_obj:menu_item_health_metrics AS menu_item_health_metrics
  FROM menu m;

// laternal flatten
SELECT m.menu_item_name,
       obj.value:"ingredients"::VARIANT AS ingredients
  FROM menu m,
       LATERAL FLATTEN (input => m.menu_item_health_metrics_obj:menu_item_health_metrics) obj;

// array_contains 
SELECT m.menu_item_name,
       obj.value:"ingredients"::VARIANT AS ingredients
  FROM menu m,
       LATERAL FLATTEN (input => m.menu_item_health_metrics_obj:menu_item_health_metrics) obj
 WHERE ARRAY_CONTAINS('Lettuce'::VARIANT, obj.value:"ingredients"::VARIANT);
;

// 전체 컬럼 구조화 
SELECT m.menu_item_health_metrics_obj:menu_item_id::integer AS menu_item_id,
       m.menu_item_name,
       obj.value:"ingredients"::VARIANT AS ingredients,
       obj.value:"is_healthy_flag"::VARCHAR(1) AS is_healthy,
       obj.value:"is_gluten_free_flag"::VARCHAR(1) AS is_gluten_free,
       obj.value:"is_dairy_free_flag"::VARCHAR(1) AS is_dairy_free,
       obj.value:"is_nut_free_flag"::VARCHAR(1) AS is_nut_free
  FROM menu m,
       LATERAL FLATTEN (input => m.menu_item_health_metrics_obj:menu_item_health_metrics) obj;

// 스키마 생성을 위한 컨텍스트 설정
USE ROLE sysadmin ;
USE DATABASE frostbyte_tasty_bytes ;

// 뷰 생성용 스키마  
CREATE OR REPLACE SCHEMA harmonized ;
CREATE OR REPLACE SCHEMA analytics ;

// 권한 설정을 위한 컨텍스트 설정
USE ROLE securityadmin ;

// harmonized 스키마에 대한 모든 권한 부여
GRANT ALL ON SCHEMA tasty_db.harmonized TO ROLE tasty_data_engineer ;
GRANT ALL ON SCHEMA tasty_db.harmonized TO ROLE tasty_dev ;

// analytics 스키마에 대한 모든 권한 부여
GRANT ALL ON SCHEMA tasty_db.analytics TO ROLE tasty_data_engineer ;
GRANT ALL ON SCHEMA tasty_db.analytics TO ROLE tasty_dev ;

// harmonized 스키마에 생성될 뷰에 대한 모든 권한 부여
GRANT ALL ON FUTURE VIEWS IN SCHEMA tasty_db.harmonized TO ROLE tasty_data_engineer;
GRANT ALL ON FUTURE VIEWS IN SCHEMA tasty_db.harmonized TO ROLE tasty_dev;

// analytics 스키마에 생성될 뷰에 대한 모든 권한 부여
GRANT ALL ON FUTURE VIEWS IN SCHEMA tasty_db.analytics TO ROLE tasty_data_engineer;
GRANT ALL ON FUTURE VIEWS IN SCHEMA tasty_db.analytics TO ROLE tasty_dev;

// analytics 스키마에 생성될 프로시저에 대한 모든 권한 부여
GRANT USAGE ON FUTURE PROCEDURES IN SCHEMA tasty_db.analytics TO ROLE tasty_data_engineer;
GRANT USAGE ON FUTURE PROCEDURES IN SCHEMA tasty_db.analytics TO ROLE tasty_dev;       

// 뷰 생성을 위한 컨텍스트 설정
USE ROLE sysadmin;
USE DATABASE frostbyte_tasty_bytes ;

// 뷰 생성 : harmonized.menu_v
CREATE OR REPLACE VIEW harmonized.menu_v AS
SELECT m.menu_id,
       m.menu_type_id,
       m.menu_type,
       m.truck_brand_name,
       m.menu_item_health_metrics_obj:menu_item_id::integer AS menu_item_id,
       m.menu_item_name,
       m.item_category,
       m.item_subcategory,
       m.cost_of_goods_usd,
       m.sale_price_usd,
       obj.value:"ingredients"::VARIANT AS ingredients,
       obj.value:"is_healthy_flag"::VARCHAR(1) AS is_healthy_flag,
       obj.value:"is_gluten_free_flag"::VARCHAR(1) AS is_gluten_free_flag,
       obj.value:"is_dairy_free_flag"::VARCHAR(1) AS is_dairy_free_flag,
       obj.value:"is_nut_free_flag"::VARCHAR(1) AS is_nut_free_flag
  FROM raw_pos.menu m,
       LATERAL FLATTEN (input => m.menu_item_health_metrics_obj:menu_item_health_metrics) obj;

// 뷰 생성 : analytics.menu_v
CREATE OR REPLACE VIEW analytics.menu_v AS
SELECT * 
       EXCLUDE (menu_type_id) --exclude MENU_TYPE_ID
       RENAME  (truck_brand_name AS brand_name) -- rename TRUCK_BRAND_NAME to BRAND_NAME
  FROM harmonized.menu_v;

  // 컨텍스트 설정
USE ROLE tasty_data_engineer ;
USE WAREHOUSE tasty_de_wh ;
USE DATABASE frostbyte_tasty_bytes ;

// 배열 분석
SELECT m1.menu_type,
       m1.menu_item_name,
       m2.menu_type AS overlap_menu_type,
       m2.menu_item_name AS overlap_menu_item_name,
       ARRAY_INTERSECTION(m1.ingredients, m2.ingredients) AS overlapping_ingredients
  FROM analytics.menu_v m1
  JOIN analytics.menu_v m2
    ON m1.menu_item_id <> m2.menu_item_id -- avoid joining the same menu item to itself
   AND m1.menu_type <> m2.menu_type 
 WHERE 1=1
   AND m1.item_category <> 'Beverage' -- remove beverages
   AND m2.item_category <> 'Beverage' -- remove beverages
   AND ARRAYS_OVERLAP(m1.ingredients, m2.ingredients) -- evaluates to TRUE if one ingredient is in both arrays
 ORDER BY m1.menu_type;

// 영양소별 메뉴 갯수 지표
SELECT m.brand_name,
       SUM(CASE WHEN is_gluten_free_flag = 'Y' THEN 1 ELSE 0 END) AS gluten_free_item_count,
       SUM(CASE WHEN is_dairy_free_flag = 'Y' THEN 1 ELSE 0 END) AS dairy_free_item_count,
       SUM(CASE WHEN is_nut_free_flag = 'Y' THEN 1 ELSE 0 END) AS nut_free_item_count
  FROM analytics.menu_v m
 GROUP BY m.brand_name;

 
