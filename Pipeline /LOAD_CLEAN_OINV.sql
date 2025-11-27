CREATE OR ALTER   PROCEDURE LOAD_CLEAN_OINV
AS
BEGIN
  SET NOCOUNT ON;

  -- 1) #OINVRLC: OINV + RowLastChange (temp distribuida)
  IF OBJECT_ID('tempdb..#OINVRLC') IS NOT NULL DROP TABLE #OINVRLC;
  CREATE TABLE #OINVRLC
  AS
  SELECT  o.*,
          CAST(DATETIMEFROMPARTS(
            YEAR(o.UpdateDate), MONTH(o.UpdateDate), DAY(o.UpdateDate),
            TRY_CONVERT(int,o.UpdateTS)/10000,
            (TRY_CONVERT(int,o.UpdateTS)/100)%100,
            TRY_CONVERT(int,o.UpdateTS)%100, 0
          ) AS DATETIME2(6)) AS RowLastChange
  FROM SBO_NMU_PROD.OINV AS o;

  -- 2) #OINV_DEDUP: solo columnas originales (sin RowLastChange ni rn)
  IF OBJECT_ID('tempdb..#OINV_DEDUP') IS NOT NULL DROP TABLE #OINV_DEDUP;
  CREATE TABLE #OINV_DEDUP
  AS
  SELECT t.*
  FROM (
      SELECT  o.*,
              ROW_NUMBER() OVER (
                PARTITION BY o.DocEntry
                ORDER BY o.RowLastChange DESC, o.DocEntry DESC
              ) AS rn
      FROM #OINVRLC AS o
  ) AS d
  CROSS APPLY ( SELECT d.* ) AS t  -- t = columnas originales de OINV
  WHERE d.rn = 1;

  -- 3) Publica en la tabla final
  TRUNCATE TABLE SBO_NMU_PROD.CLEAN_OINV;
  INSERT INTO SBO_NMU_PROD.CLEAN_OINV
  SELECT * FROM #OINV_DEDUP;
END
