SELECT
    I.*  
FROM "SBO_NMU_PROD"."INV1" AS I
INNER JOIN "SBO_NMU_PROD"."OINV" AS H
        ON I."DocEntry" = H."DocEntry"
WHERE
  TO_SECONDDATE(
      TO_VARCHAR(H."UpdateDate",'YYYY-MM-DD') || ' ' ||
      SUBSTR(LPAD(TO_VARCHAR(H."UpdateTS"),6,'0'),1,2) || ':' ||
      SUBSTR(LPAD(TO_VARCHAR(H."UpdateTS"),6,'0'),3,2) || ':' ||
      SUBSTR(LPAD(TO_VARCHAR(H."UpdateTS"),6,'0'),5,2)
  )
  > TO_SECONDDATE('@{variables('LastWatermark')}');
