# Update these values for your Teradata environment.
$Env:TD_TDPID = "YOUR_TDPID"
$Env:TD_USER = "YOUR_USERNAME"
$Env:TD_PASS = "YOUR_PASSWORD"

# Optional: use non-default database names if needed.
$Env:CTRL_DB = "ETL_CTRL"
$Env:BRONZE_DB = "TD_BRONZE"
$Env:SILVER_DB = "TD_SILVER"
$Env:GOLD_DB = "TD_GOLD"

# Input CSV path.
$Env:BOSTON_CSV = "C:\Users\LENOVO\Documents\Google ADK\bteq\data\boston_housing.csv"
