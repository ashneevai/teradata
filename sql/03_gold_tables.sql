CREATE DATABASE TD_GOLD AS PERM = 100000000;

CREATE MULTISET TABLE TD_GOLD.dim_run (
    run_key                INTEGER GENERATED ALWAYS AS IDENTITY
                           (START WITH 1 INCREMENT BY 1) NOT NULL,
    run_id                 VARCHAR(40)  NOT NULL,
    run_date               DATE         NOT NULL,
    run_dts                TIMESTAMP(0) NOT NULL DEFAULT CURRENT_TIMESTAMP(0)
) PRIMARY INDEX (run_id);

CREATE MULTISET TABLE TD_GOLD.dim_location (
    location_key           INTEGER GENERATED ALWAYS AS IDENTITY
                           (START WITH 1 INCREMENT BY 1) NOT NULL,
    chas                   BYTEINT,
    rad                    INTEGER
) PRIMARY INDEX (chas, rad);

CREATE MULTISET TABLE TD_GOLD.fact_boston_housing_metrics (
    run_id                 VARCHAR(40)  NOT NULL,
    run_key                INTEGER      NOT NULL,
    location_key           INTEGER      NOT NULL,
    record_count           BIGINT,
    avg_medv               DECIMAL(18,8),
    min_medv               DECIMAL(18,8),
    max_medv               DECIMAL(18,8),
    avg_rm                 DECIMAL(18,8),
    avg_lstat              DECIMAL(18,8),
    total_tax              BIGINT,
    avg_ptratio            DECIMAL(18,8),
    aggregated_dts         TIMESTAMP(0) NOT NULL DEFAULT CURRENT_TIMESTAMP(0)
) PRIMARY INDEX (run_key, location_key);
