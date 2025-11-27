SELECT *
FROM "SBO_NMU_PROD"."OINV"
WHERE
TO_SECONDDATE( TO_VARCHAR("UpdateDate",'YYYY-MM-DD') || ' ' || SUBSTR(LPAD(TO_VARCHAR("UpdateTS"),6,'0'),1,2) || ':' || SUBSTR(LPAD(TO_VARCHAR("UpdateTS"),6,'0'),3,2) || ':' || SUBSTR(LPAD(TO_VARCHAR("UpdateTS"),6,'0'),5,2) ) 
> TO_SECONDDATE('@{variables('LastWatermark')}');
