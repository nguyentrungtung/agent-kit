# PySpark rules

- DataFrame / Spark SQL API only; no RDD code unless justified; **no Python UDFs** where a built-in function exists (use pandas UDFs if needed).
- Explicit `StructType` schemas when reading (no `inferSchema` in production); fail on malformed records or route them to a quarantine table.
- Never `collect()`/`toPandas()` large data on the driver; no `count()` just for logging.
- Partitioning: write partitioned by the natural time column; tune `spark.sql.shuffle.partitions`/AQE; avoid small files (coalesce on write); broadcast small dimensions explicitly.
- Jobs are idempotent: overwrite the target partition (`partitionOverwriteMode=dynamic`) or MERGE (Delta/Iceberg) keyed on business keys.
- Pure transformation functions `def transform(df: DataFrame) -> DataFrame` separated from I/O, so they are unit-testable.
- Tests with a local `SparkSession` fixture and `chispa` DataFrame equality; small, deterministic fixtures, no real data.
