CREATE OR ALTER PROCEDURE RESTOREWATERMARK_OINV
AS 

UPDATE ETL.Watermarks
SET LastWatermark = (SELECT
  MAX(DATETIMEFROMPARTS(
    YEAR([UpdateDate]), MONTH([UpdateDate]), DAY([UpdateDate]),
    CAST([UpdateTS] AS INT)/10000,
    (CAST([UpdateTS] AS INT)/100)%100,
    CAST([UpdateTS] AS INT)%100,
    0
  )) AS LastWatermark
FROM [SBO_NMU_PROD].[OINV])


