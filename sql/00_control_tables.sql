-- Control metadata objects for dependency management and run tracking
CREATE DATABASE ETL_CTRL AS PERM = 10000000;

CREATE MULTISET TABLE ETL_CTRL.pipeline_control (
    job_name            VARCHAR(100) NOT NULL,
    layer_name          VARCHAR(20)  NOT NULL,
    is_enabled          CHAR(1)      NOT NULL DEFAULT 'Y',
    schedule_time_ist   CHAR(5)      NOT NULL DEFAULT '05:30',
    max_retries         SMALLINT     NOT NULL DEFAULT 3,
    retry_interval_mins SMALLINT     NOT NULL DEFAULT 30,
    last_run_status     VARCHAR(20),
    last_run_ts         TIMESTAMP(0),
    last_error_message  VARCHAR(500),
    last_attempt_no     SMALLINT,
    created_ts          TIMESTAMP(0) NOT NULL DEFAULT CURRENT_TIMESTAMP(0),
    updated_ts          TIMESTAMP(0) NOT NULL DEFAULT CURRENT_TIMESTAMP(0)
) PRIMARY INDEX (job_name);

CREATE MULTISET TABLE ETL_CTRL.pipeline_dependencies (
    child_job_name      VARCHAR(100) NOT NULL,
    parent_job_name     VARCHAR(100) NOT NULL,
    is_mandatory        CHAR(1)      NOT NULL DEFAULT 'Y',
    created_ts          TIMESTAMP(0) NOT NULL DEFAULT CURRENT_TIMESTAMP(0)
) PRIMARY INDEX (child_job_name);

CREATE MULTISET TABLE ETL_CTRL.pipeline_run_stats (
    run_id              VARCHAR(40)  NOT NULL,
    job_name            VARCHAR(100) NOT NULL,
    run_date            DATE         NOT NULL,
    run_status          VARCHAR(20)  NOT NULL,
    start_ts            TIMESTAMP(0),
    end_ts              TIMESTAMP(0),
    rows_loaded         BIGINT,
    error_message       VARCHAR(500),
    attempt_no          SMALLINT,
    updated_ts          TIMESTAMP(0) NOT NULL DEFAULT CURRENT_TIMESTAMP(0)
) PRIMARY INDEX (job_name, run_date);

DELETE FROM ETL_CTRL.pipeline_control WHERE job_name IN (
    'BRONZE_LOAD_BOSTON',
    'SILVER_BUILD_BOSTON',
    'GOLD_BUILD_BOSTON'
);

INSERT INTO ETL_CTRL.pipeline_control (job_name, layer_name, is_enabled, schedule_time_ist, max_retries, retry_interval_mins)
VALUES ('BRONZE_LOAD_BOSTON', 'BRONZE', 'Y', '05:30', 3, 30);

INSERT INTO ETL_CTRL.pipeline_control (job_name, layer_name, is_enabled, schedule_time_ist, max_retries, retry_interval_mins)
VALUES ('SILVER_BUILD_BOSTON', 'SILVER', 'Y', '05:30', 3, 30);

INSERT INTO ETL_CTRL.pipeline_control (job_name, layer_name, is_enabled, schedule_time_ist, max_retries, retry_interval_mins)
VALUES ('GOLD_BUILD_BOSTON', 'GOLD', 'Y', '05:30', 3, 30);

DELETE FROM ETL_CTRL.pipeline_dependencies WHERE child_job_name IN (
    'SILVER_BUILD_BOSTON',
    'GOLD_BUILD_BOSTON'
);

INSERT INTO ETL_CTRL.pipeline_dependencies (child_job_name, parent_job_name, is_mandatory)
VALUES ('SILVER_BUILD_BOSTON', 'BRONZE_LOAD_BOSTON', 'Y');

INSERT INTO ETL_CTRL.pipeline_dependencies (child_job_name, parent_job_name, is_mandatory)
VALUES ('GOLD_BUILD_BOSTON', 'SILVER_BUILD_BOSTON', 'Y');
