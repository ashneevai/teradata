CREATE DATABASE TD_SILVER AS PERM = 100000000;

CREATE MULTISET TABLE TD_SILVER.boston_housing_silver (
    run_id             VARCHAR(40)  NOT NULL,
    crim               DECIMAL(18,8),
    zn                 DECIMAL(18,8),
    indus              DECIMAL(18,8),
    chas               BYTEINT,
    nox                DECIMAL(18,8),
    rm                 DECIMAL(18,8),
    age                DECIMAL(18,8),
    dis                DECIMAL(18,8),
    rad                INTEGER,
    tax                INTEGER,
    ptratio            DECIMAL(18,8),
    black_col          DECIMAL(18,8),
    lstat              DECIMAL(18,8),
    medv               DECIMAL(18,8),
    dq_valid_flag      CHAR(1)      NOT NULL,
    dq_error_reason    VARCHAR(200),
    transformed_dts    TIMESTAMP(0) NOT NULL DEFAULT CURRENT_TIMESTAMP(0)
) PRIMARY INDEX (run_id);
