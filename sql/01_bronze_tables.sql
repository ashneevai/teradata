CREATE DATABASE TD_BRONZE AS PERM = 100000000;

CREATE MULTISET TABLE TD_BRONZE.boston_housing_bronze (
    run_id             VARCHAR(40)  NOT NULL,
    crim               VARCHAR(30),
    zn                 VARCHAR(30),
    indus              VARCHAR(30),
    chas               VARCHAR(30),
    nox                VARCHAR(30),
    rm                 VARCHAR(30),
    age                VARCHAR(30),
    dis                VARCHAR(30),
    rad                VARCHAR(30),
    tax                VARCHAR(30),
    ptratio            VARCHAR(30),
    black_col          VARCHAR(30),
    lstat              VARCHAR(30),
    medv               VARCHAR(30),
    source_file_name   VARCHAR(260),
    load_dts           TIMESTAMP(0) NOT NULL DEFAULT CURRENT_TIMESTAMP(0)
) PRIMARY INDEX (run_id);
