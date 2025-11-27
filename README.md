# CDCFabric

Este repositorio contiene los artefactos necesarios para implementar un pipeline de **Change Data Capture (CDC)** que replica en casi tiempo real la información de facturas desde **SAP HANA** hacia un **Data Warehouse en Microsoft Fabric** denominado **HANA**. El flujo prioriza bajo impacto en el servidor transaccional al extraer únicamente los registros nuevos o modificados, lo que habilita escenarios analíticos y de ciencia de datos sin comprometer el rendimiento del ERP **SAP Business One**.

## Propósito

El objetivo es disponer de un repositorio actualizado de las tablas de facturación (`OINV` y `INV1`) en Fabric, permitiendo:
- Consultas analíticas y reporting sin afectar la base de datos operativa.
- Integración con herramientas de ingeniería y ciencia de datos sobre datos casi en tiempo real.
- Escalabilidad para extender el CDC a otras entidades de SAP HANA conforme se requiera.

## Alcance del repositorio

- Contiene el código y definiciones del pipeline CDC (scripts, notebooks o plantillas) para mover datos desde SAP HANA hacia el DW HANA en Fabric.
- Incluye ejemplos y lineamientos para procesar las tablas de facturas (`OINV` cabecera y `INV1` detalle) mediante incrementales.
- No incluye configuraciones específicas de infraestructura, seguridad o redes propias de cada entorno.

## Requisitos previos

Antes de ejecutar el pipeline, asegúrate de contar con:
- **Data Warehouse en Fabric** creado y accesible (por ejemplo, `HANA`).
- **Conexión configurada** entre el servidor **SAP HANA** y Microsoft Fabric (gateway, credenciales, roles y permisos). Estos pasos de red/seguridad no están incluidos en este repositorio.
- **Accesos mínimos** para leer las tablas `OINV` e `INV1` en el origen SAP HANA y permisos de escritura en el DW de Fabric.
- Herramientas o runtimes requeridos por el pipeline (por ejemplo, runtimes de notebooks, librerías de conectores y drivers HANA, configuración de CDC o triggers según el enfoque elegido).

## Arquitectura de alto nivel

1. **Origen SAP HANA**: lecturas incrementales de `OINV` (factura cabecera) y `INV1` (factura detalle), aprovechando CDC para minimizar el volumen de datos transferidos.
2. **Ingesta hacia Fabric**: el pipeline captura cambios y los replica en tablas staging o directamente en el DW HANA dentro de Fabric.
3. **Transformaciones y armonización**: opcionalmente, se aplican pasos de limpieza, conformado de llaves y enriquecimiento antes de exponer los datos a consumidores analíticos.
4. **Consumo**: herramientas de BI, notebooks o modelos de ciencia de datos pueden consultar el DW en Fabric sin impactar el servidor transaccional.

## Flujo sugerido del pipeline

1. **Inicialización**: sincronización completa inicial de `OINV` e `INV1` para establecer el punto de partida.
2. **Captura continua**: habilitar CDC o lógica incremental (por marca de tiempo/versión) para leer únicamente cambios nuevos o actualizados.
3. **Carga en Fabric**: insertar/actualizar en tablas objetivo en el DW HANA, manteniendo integridad entre cabecera y detalle de factura.
4. **Monitoreo**: registrar métricas de latencia, volumen y errores para asegurar que la replicación se mantiene operativa en near real time.
5. **Evolución**: agregar nuevas entidades de SAP HANA o reglas de negocio conforme crezcan las necesidades de analítica.

## Buenas prácticas

- Validar periódicamente que la configuración de CDC en HANA funciona y que las marcas de cambio se consumen sin lag significativo.
- Mantener controles de calidad de datos (conteos, reconciliación de totales) para asegurar consistencia entre origen y destino.
- Automatizar despliegues y parametrizaciones por entorno (desarrollo, pruebas, producción) para reducir riesgos de configuración manual.
- Documentar credenciales y endpoints fuera del repositorio (vaults o gestores de secretos) para evitar exponer información sensible.

## Límites y supuestos

- El repositorio **no** incluye scripts para crear el DW en Fabric ni para configurar la conectividad con SAP HANA; se asume que dichos componentes ya existen.
- Las rutas, nombres de tablas y esquemas pueden requerir ajustes según la nomenclatura de cada organización.
- La frecuencia de captura (latencia) dependerá de las capacidades del entorno y de la configuración de CDC en el servidor SAP HANA.

## Descripción de los artefactos SQL

El repositorio incluye los siguientes archivos SQL que apoyan el flujo CDC y la consolidación de la información en el DW de Fabric. Ajusta esquemas y nombres de tabla según tu entorno.

- `Pipeline/CDC_OINV.sql`: consulta incremental de la tabla `OINV` en SAP HANA filtrando por `UpdateDate` y `UpdateTS` mayores al watermark (`LastWatermark`). Obtiene las facturas (cabecera) modificadas desde la última carga para minimizar el volumen replicado.
- `Pipeline/CDC_INV1.sql`: consulta incremental que obtiene las líneas de factura (`INV1`) asociadas a cabeceras cambiadas en `OINV`, usando el mismo filtro de watermark. Garantiza coherencia entre cabecera y detalle en el lote CDC.
- `Pipeline/LOAD_CLEAN_OINV.sql`: procedimiento almacenado que construye una tabla temporal con sello de tiempo (`RowLastChange`), elimina duplicados de `OINV` por `DocEntry` conservando la versión más reciente y publica el resultado en `SBO_NMU_PROD.CLEAN_OINV` mediante `TRUNCATE` + `INSERT`.
- `Pipeline/LOAD_CLEAN_INV1.sql`: procedimiento almacenado que lee el watermark compartido de `ETL.Watermarks`, identifica las facturas cambiadas en `CLEAN_OINV`, borra sus líneas existentes en `CLEAN_INV1` y vuelve a insertarlas deduplicadas por `(DocEntry, LineNum)` con una ventana `ROW_NUMBER`.
- `Pipeline/Lookup_watermark.sql`: consulta sencilla para recuperar el `LastWatermark` de la tabla `ETL.Watermarks` asociada al pipeline `OINV`; útil para depurar o validar la marca de corte antes de ejecutar cargas incrementales.
- `Pipeline/RESTOREWATERMARK_OINV.sql`: procedimiento que recalcula y restaura el `LastWatermark` tomando la fecha y hora máxima (`UpdateDate`, `UpdateTS`) presentes en `SBO_NMU_PROD.OINV`; sirve para reanclar la replicación tras reinicios o inconsistencias.
- `Others/vXLS_OINV.sql`: vista que expone un dataset combinado de encabezados (`CLEAN_OINV`) y líneas de factura (`CLEAN_INV1`) con atributos clave (cliente, vendedor, totales, estado) listo para exportación o consumo analítico ligero.

## Próximos pasos

- Añadir documentación específica de despliegue (por ejemplo, cómo registrar la conexión en Fabric y configurar el gateway hacia HANA).
- Incorporar pipelines adicionales para otras entidades de SAP B1 (clientes, artículos, pagos) según prioridades de negocio.
- Extender ejemplos de monitoreo y alertas para detectar atrasos o fallas en la replicación.

---

Para dudas o contribuciones, crea un issue o envía un pull request describiendo los cambios propuestos.
