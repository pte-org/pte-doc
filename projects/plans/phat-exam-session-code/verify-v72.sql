-- Verifies migration V72__exam_session_code.sql on a Postgres DB after Flyway
-- applied it (CI never runs Flyway). Run with:
--   psql -v ON_ERROR_STOP=1 -d pte -f verify-v72.sql
-- Each check RAISEs on failure; a clean run prints "V72 verification passed".

DO $$
DECLARE
    bad BIGINT;
BEGIN
    SELECT count(*) INTO bad FROM exam_sessions WHERE session_code IS NULL;
    IF bad > 0 THEN RAISE EXCEPTION 'V72: % rows with NULL session_code', bad; END IF;

    SELECT count(*) INTO bad FROM (
        SELECT session_code FROM exam_sessions GROUP BY session_code HAVING count(*) > 1
    ) dup;
    IF bad > 0 THEN RAISE EXCEPTION 'V72: % duplicated session_code values', bad; END IF;

    SELECT count(*) INTO bad FROM exam_sessions
    WHERE session_code !~ '^[A-Z0-9]{1,8}-[0-9]{6}-[A-HJ-NP-Z2-9]{4}$';
    IF bad > 0 THEN RAISE EXCEPTION 'V72: % rows with a malformed session_code', bad; END IF;

    -- Date part must be opens_at's calendar day in Asia/Ho_Chi_Minh.
    SELECT count(*) INTO bad FROM exam_sessions
    WHERE split_part(session_code, '-', 2) <> to_char(opens_at AT TIME ZONE 'Asia/Ho_Chi_Minh', 'YYMMDD');
    IF bad > 0 THEN RAISE EXCEPTION 'V72: % rows whose date part does not match opens_at', bad; END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'uq_exam_sessions_session_code' AND contype = 'u') THEN
        RAISE EXCEPTION 'V72: constraint uq_exam_sessions_session_code is missing';
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_name = 'exam_sessions' AND column_name = 'session_code' AND is_nullable = 'YES') THEN
        RAISE EXCEPTION 'V72: session_code is still nullable';
    END IF;

    IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'v72_random_session_suffix') THEN
        RAISE EXCEPTION 'V72: temporary helper v72_random_session_suffix was not dropped';
    END IF;
END;
$$;

-- Dedupe loop exercise: rerun V72's loop body on a scratch copy where rows are
-- forced to share one code, then roll everything back.
BEGIN;

CREATE FUNCTION v72_random_session_suffix() RETURNS VARCHAR AS $$
DECLARE
    alphabet CONSTANT TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    result TEXT := '';
BEGIN
    FOR i IN 1..4 LOOP
        result := result || substr(alphabet, 1 + floor(random() * 32)::INT, 1);
    END LOOP;
    RETURN result;
END;
$$ LANGUAGE plpgsql VOLATILE;

CREATE TEMP TABLE v72_scratch AS SELECT id, session_code FROM exam_sessions;
INSERT INTO v72_scratch (id, session_code)
SELECT -g, 'FPT-261010-AAAA' FROM generate_series(1, 3) g;
UPDATE v72_scratch SET session_code = 'FPT-261010-AAAA' WHERE id = (SELECT min(id) FROM exam_sessions);

DO $$
DECLARE
    iteration INT := 0;
    duplicates INT;
    remaining BIGINT;
BEGIN
    LOOP
        UPDATE v72_scratch s
        SET session_code = left(s.session_code, length(s.session_code) - 4) || v72_random_session_suffix()
        FROM (
            SELECT id, row_number() OVER (PARTITION BY session_code ORDER BY id) AS rn
            FROM v72_scratch
        ) ranked
        WHERE ranked.id = s.id AND ranked.rn > 1;
        GET DIAGNOSTICS duplicates = ROW_COUNT;
        EXIT WHEN duplicates = 0;
        iteration := iteration + 1;
        IF iteration >= 20 THEN
            RAISE EXCEPTION 'V72 dedupe exercise: duplicates remain after % iterations', iteration;
        END IF;
    END LOOP;

    IF iteration = 0 THEN
        RAISE EXCEPTION 'V72 dedupe exercise: loop did not re-randomize the forced duplicates';
    END IF;
    SELECT count(*) INTO remaining FROM (
        SELECT session_code FROM v72_scratch GROUP BY session_code HAVING count(*) > 1
    ) dup;
    IF remaining > 0 THEN
        RAISE EXCEPTION 'V72 dedupe exercise: % duplicated codes remain', remaining;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM v72_scratch WHERE session_code = 'FPT-261010-AAAA') THEN
        RAISE EXCEPTION 'V72 dedupe exercise: the first row of the duplicate group was changed';
    END IF;
    RAISE NOTICE 'V72 dedupe exercise: resolved in % iteration(s)', iteration;
END;
$$;

ROLLBACK;

SELECT 'V72 verification passed' AS result;
