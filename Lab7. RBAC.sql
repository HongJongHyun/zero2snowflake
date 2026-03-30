
// sysadmin으로 역할 전환
USE ROLE sysadmin ;

// 웨어하우스 tasty_dev_wh 생성
CREATE OR REPLACE WAREHOUSE tasty_dev_wh
    WAREHOUSE_SIZE = 'xsmall'
    WAREHOUSE_TYPE = 'standard'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
;

// 확인
SHOW WAREHOUSES LIKE 'tasty%';

// securityadmin으로 역할 전환
USE ROLE securityadmin ;

// 역할 추가
CREATE ROLE IF NOT EXISTS tasty_data_engineer ;
CREATE ROLE IF NOT EXISTS tasty_dev ;

SET MY_USER_ID = current_user();
GRANT ROLE tasty_data_engineer TO USER identifier($MY_USER_ID);
GRANT ROLE tasty_dev           TO USER identifier($MY_USER_ID);

// 확인
SHOW ROLES LIKE 'tasty%' ;

// securityadmin으로 역할 전환
USE ROLE securityadmin ;

// tasty_db에 대한 사용 권한
GRANT USAGE ON DATABASE frostbyte_tasty_bytes TO ROLE tasty_data_engineer;
GRANT USAGE ON DATABASE frostbyte_tasty_bytes TO ROLE tasty_dev;

// tasty_db의 모든 스키마에 대한 사용 권한
GRANT USAGE ON ALL SCHEMAS IN DATABASE frostbyte_tasty_bytes TO ROLE tasty_data_engineer;
GRANT USAGE ON ALL SCHEMAS IN DATABASE frostbyte_tasty_bytes TO ROLE tasty_dev;

// raw_pos 스키마에 대해 모든 권한
GRANT ALL ON SCHEMA frostbyte_tasty_bytes.raw_pos TO ROLE tasty_data_engineer;
GRANT ALL ON SCHEMA frostbyte_tasty_bytes.raw_pos TO ROLE tasty_dev;

// raw_customer 스키마에 대해 모든 권한
GRANT ALL ON SCHEMA frostbyte_tasty_bytes.raw_customer TO ROLE tasty_data_engineer;
GRANT ALL ON SCHEMA frostbyte_tasty_bytes.raw_customer TO ROLE tasty_dev;

// raw_pos 스키마 내의 전체 테이블에 대한 모든 권한
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA frostbyte_tasty_bytes.raw_pos TO ROLE tasty_data_engineer ;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA frostbyte_tasty_bytes.raw_pos TO ROLE tasty_dev ;

// raw_customer 스키마 내의 전체 테이블에 대한 모든 권한
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA frostbyte_tasty_bytes.raw_customer TO ROLE tasty_data_engineer ;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA frostbyte_tasty_bytes.raw_customer TO ROLE tasty_dev ;

// demo_build_wh
GRANT ALL ON WAREHOUSE demo_build_wh TO ROLE sysadmin;

// tasty_de_wh
GRANT ALL ON WAREHOUSE tasty_de_wh TO ROLE tasty_data_engineer;

// tasty_dev_wh
GRANT ALL ON WAREHOUSE tasty_dev_wh TO ROLE tasty_data_engineer;
GRANT ALL ON WAREHOUSE tasty_dev_wh TO ROLE tasty_dev;

// raw_pos 스키마에 생성될 향후 테이블
GRANT ALL ON FUTURE TABLES IN SCHEMA frostbyte_tasty_bytes.raw_pos TO ROLE tasty_data_engineer;
GRANT ALL ON FUTURE TABLES IN SCHEMA frostbyte_tasty_bytes.raw_pos TO ROLE tasty_dev;

// raw_customer 스키마에 생성될 향후 테이블
GRANT ALL ON FUTURE TABLES IN SCHEMA frostbyte_tasty_bytes.raw_customer TO ROLE tasty_data_engineer;
GRANT ALL ON FUTURE TABLES IN SCHEMA frostbyte_tasty_bytes.raw_customer TO ROLE tasty_dev;