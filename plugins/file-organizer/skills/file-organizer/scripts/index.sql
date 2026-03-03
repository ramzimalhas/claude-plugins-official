-- =============================================================================
-- FILE ORGANIZER — DuckDB Filesystem Index
-- Creates a queryable metadata catalog of files in target directories.
-- Usage: duckdb ~/.maestroverse/maestro.duckdb < index.sql
-- Or:    duckdb :memory: < index.sql  (ephemeral, no persistence)
-- =============================================================================

-- Create the file index table (idempotent)
CREATE TABLE IF NOT EXISTS file_index (
    path        VARCHAR,
    name        VARCHAR,
    extension   VARCHAR,
    size_bytes  BIGINT,
    modified    TIMESTAMP,
    category    VARCHAR,
    indexed_at  TIMESTAMP DEFAULT current_timestamp,
    sha256      VARCHAR   -- populated separately if needed
);

-- Clear previous index for re-scan
DELETE FROM file_index WHERE indexed_at < current_timestamp - INTERVAL '1 hour';

-- Index ~/Downloads (recursive)
INSERT INTO file_index (path, name, extension, size_bytes, modified, category)
SELECT
    filename AS path,
    regexp_extract(filename, '[^/]+$') AS name,
    LOWER(regexp_extract(filename, '\.([^.]+)$', 1)) AS extension,
    size AS size_bytes,
    last_modified AS modified,
    CASE
        -- Archives
        WHEN LOWER(regexp_extract(filename, '\.([^.]+)$', 1)) IN ('zip','tar','gz','bz2','xz','rar','7z') THEN 'Archives'
        -- Documents
        WHEN LOWER(regexp_extract(filename, '\.([^.]+)$', 1)) IN ('pdf','doc','docx','txt','rtf','md','tex') THEN 'Documents'
        -- Images
        WHEN LOWER(regexp_extract(filename, '\.([^.]+)$', 1)) IN ('png','jpg','jpeg','heic','webp','tif','bmp','svg','gif') THEN 'Images'
        -- Video
        WHEN LOWER(regexp_extract(filename, '\.([^.]+)$', 1)) IN ('mp4','mov','mkv','avi','webm','m4v') THEN 'Media/Video'
        -- Audio
        WHEN LOWER(regexp_extract(filename, '\.([^.]+)$', 1)) IN ('mp3','wav','flac','m4a','aac') THEN 'Media/Audio'
        -- Code
        WHEN LOWER(regexp_extract(filename, '\.([^.]+)$', 1)) IN ('py','js','ts','jsx','tsx','go','rs','java','kt','swift','sh','sql') THEN 'Code'
        -- Config
        WHEN LOWER(regexp_extract(filename, '\.([^.]+)$', 1)) IN ('json','yaml','yml','toml','xml','plist','ini','conf','env') THEN 'Config'
        -- Data
        WHEN LOWER(regexp_extract(filename, '\.([^.]+)$', 1)) IN ('csv','xlsx','xls','parquet','avro','numbers','tsv') THEN 'Data'
        -- Installers
        WHEN LOWER(regexp_extract(filename, '\.([^.]+)$', 1)) IN ('dmg','pkg','ipa','apk') THEN 'Installers'
        -- Logs
        WHEN LOWER(regexp_extract(filename, '\.([^.]+)$', 1)) IN ('log','trace','crash','diag') THEN 'Logs'
        -- Books
        WHEN LOWER(regexp_extract(filename, '\.([^.]+)$', 1)) IN ('epub','mobi') THEN 'Books'
        -- Web
        WHEN LOWER(regexp_extract(filename, '\.([^.]+)$', 1)) IN ('html','htm') THEN 'Web'
        -- ML Models
        WHEN LOWER(regexp_extract(filename, '\.([^.]+)$', 1)) IN ('pt','pth','safetensors','onnx','gguf','ckpt') THEN 'ML-Models'
        -- Design
        WHEN LOWER(regexp_extract(filename, '\.([^.]+)$', 1)) IN ('fig','sketch','psd','xd','ai') THEN 'Design'
        -- Telemetry
        WHEN LOWER(regexp_extract(filename, '\.([^.]+)$', 1)) IN ('jsonl','ndjson') THEN 'Telemetry'
        -- Databases
        WHEN LOWER(regexp_extract(filename, '\.([^.]+)$', 1)) IN ('sqlite','duckdb','db','realm') THEN 'Databases'
        -- Spreadsheets (standalone)
        WHEN LOWER(regexp_extract(filename, '\.([^.]+)$', 1)) IN ('xlsx','xls','numbers') THEN 'Spreadsheets'
        ELSE 'Uncategorized'
    END AS category
FROM read_text('~/Downloads/**/*')
WHERE NOT contains(filename, '/.')
  AND NOT contains(filename, 'node_modules')
  AND NOT contains(filename, '.git/')
  AND NOT contains(filename, '__pycache__');

-- ─── USEFUL QUERIES ──────────────────────────────────────────────────────────

-- Summary by category
-- SELECT category, COUNT(*) as files,
--        printf('%.1f MB', SUM(size_bytes)/1048576.0) as total_size
-- FROM file_index GROUP BY category ORDER BY COUNT(*) DESC;

-- Find duplicates (same name, different path)
-- SELECT name, COUNT(*) as copies,
--        array_agg(path) as locations
-- FROM file_index GROUP BY name HAVING COUNT(*) > 1
-- ORDER BY COUNT(*) DESC LIMIT 20;

-- Files modified today
-- SELECT name, category, printf('%.0f KB', size_bytes/1024.0) as size
-- FROM file_index WHERE modified >= current_date
-- ORDER BY size_bytes DESC;

-- Large files (>10MB)
-- SELECT name, category, printf('%.1f MB', size_bytes/1048576.0) as size
-- FROM file_index WHERE size_bytes > 10485760
-- ORDER BY size_bytes DESC;

-- Stale installers (>30 days old)
-- SELECT name, modified, printf('%.1f MB', size_bytes/1048576.0) as size
-- FROM file_index WHERE category = 'Installers'
--   AND modified < current_timestamp - INTERVAL '30 days';

-- Extension distribution
-- SELECT extension, COUNT(*) as files,
--        printf('%.1f MB', SUM(size_bytes)/1048576.0) as total_size
-- FROM file_index GROUP BY extension ORDER BY COUNT(*) DESC LIMIT 20;
