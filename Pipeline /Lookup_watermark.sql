SELECT  CAST(LastWatermark AS NVARCHAR(100)) AS LastWatermark
FROM ETL.Watermarks
WHERE PipelineName='OINV'
