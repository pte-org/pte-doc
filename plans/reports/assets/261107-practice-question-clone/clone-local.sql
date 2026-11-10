-- One-time local operation, not a Flyway migration. Run with ON_ERROR_STOP=1.
-- Rehearse with -v commit_clone=false; apply with -v commit_clone=true.
BEGIN;
SET LOCAL lock_timeout = '10s';
LOCK TABLE questions, question_options IN SHARE ROW EXCLUSIVE MODE;

CREATE TEMP TABLE clone_sources ON COMMIT DROP AS
SELECT q.*, md5('local-practice-clone-20261107:' || q.public_id::text)::uuid AS clone_public_id
FROM questions q
WHERE NOT q.deleted AND q.is_current AND q.status = 'APPROVED'
  AND q.pool = 'EXAM' AND q.available_for_exam
  AND NOT q.available_for_practice AND q.tenant_id IS NULL;

CREATE TEMP TABLE clone_source_options ON COMMIT DROP AS
SELECT o.* FROM question_options o JOIN clone_sources s ON s.id = o.question_id;

DO $$
BEGIN
  IF current_database() <> 'pte' OR (SELECT count(*) FROM clone_sources) <> 96
      OR (SELECT count(*) FROM clone_source_options) <> 264 THEN
    RAISE EXCEPTION 'Unexpected local source dataset; no changes applied';
  END IF;
  IF EXISTS (SELECT 1 FROM questions q JOIN clone_sources s ON q.public_id = s.clone_public_id) THEN
    RAISE EXCEPTION 'This clone batch already exists; refusing duplicate execution';
  END IF;
END $$;

INSERT INTO questions (
  created_at, deleted, public_id, updated_at, audio_prompt_ref, author_user_public_id,
  availability_flags_explicit, available_for_exam, available_for_practice,
  correct_answer_text, is_current, ever_published, image_prompt_ref,
  max_word_count, min_word_count, pool, prompt_text, pte_task_type,
  reference_answer_text, rejection_reason, revision_group_public_id, revision_number,
  status, supersedes_public_id, task_type_key, task_type_section, tenant_id, version,
  cefr_level, generation_meta, content_hash, generation_job_public_id, generation_item_index
)
SELECT
  transaction_timestamp(), false, clone_public_id, transaction_timestamp(), audio_prompt_ref,
  author_user_public_id, true, false, true, correct_answer_text, true, true, image_prompt_ref,
  max_word_count, min_word_count, 'PRACTICE', prompt_text, pte_task_type, reference_answer_text,
  NULL, clone_public_id, 1, 'APPROVED', NULL, task_type_key, task_type_section, NULL, 0,
  cefr_level, NULL, NULL, NULL, NULL
FROM clone_sources;

INSERT INTO question_options (question_id, blank_index, correct, correct_gap_index, order_index, public_id, text)
SELECT target.id, o.blank_index, o.correct, o.correct_gap_index, o.order_index, gen_random_uuid(), o.text
FROM clone_source_options o
JOIN clone_sources s ON s.id = o.question_id
JOIN questions target ON target.public_id = s.clone_public_id;

DO $$
BEGIN
  IF (SELECT count(*) FROM questions q JOIN clone_sources s ON q.public_id = s.clone_public_id
      WHERE q.pool = 'PRACTICE' AND q.available_for_practice AND NOT q.available_for_exam
        AND q.availability_flags_explicit AND q.status = 'APPROVED' AND q.is_current
        AND NOT q.deleted AND q.ever_published AND q.tenant_id IS NULL
        AND q.revision_group_public_id = q.public_id AND q.revision_number = 1
        AND q.supersedes_public_id IS NULL AND q.generation_job_public_id IS NULL) <> 96 THEN
    RAISE EXCEPTION 'Clone channel or revision verification failed';
  END IF;
  IF EXISTS (
    SELECT 1 FROM clone_sources s JOIN questions original ON original.id = s.id
    WHERE to_jsonb(original) IS DISTINCT FROM (to_jsonb(s) - 'clone_public_id')
  ) OR EXISTS (
    (SELECT * FROM clone_source_options EXCEPT ALL
     SELECT o.* FROM question_options o JOIN clone_sources s ON s.id = o.question_id)
    UNION ALL
    (SELECT o.* FROM question_options o JOIN clone_sources s ON s.id = o.question_id
     EXCEPT ALL SELECT * FROM clone_source_options)
  ) THEN
    RAISE EXCEPTION 'Original question or option data changed';
  END IF;
  IF EXISTS (
    SELECT 1 FROM clone_sources s JOIN questions q ON q.public_id = s.clone_public_id
    WHERE ROW(q.prompt_text, q.correct_answer_text, q.reference_answer_text,
              q.audio_prompt_ref, q.image_prompt_ref, q.min_word_count, q.max_word_count,
              q.task_type_key, q.task_type_section, q.pte_task_type, q.cefr_level, q.author_user_public_id)
      IS DISTINCT FROM
          ROW(s.prompt_text, s.correct_answer_text, s.reference_answer_text,
              s.audio_prompt_ref, s.image_prompt_ref, s.min_word_count, s.max_word_count,
              s.task_type_key, s.task_type_section, s.pte_task_type, s.cefr_level, s.author_user_public_id)
  ) THEN
    RAISE EXCEPTION 'Question content verification failed';
  END IF;
  IF EXISTS (
    SELECT 1 FROM clone_sources s JOIN questions q ON q.public_id = s.clone_public_id
    WHERE (SELECT coalesce(jsonb_agg(content ORDER BY content::text), '[]'::jsonb)
           FROM (SELECT to_jsonb(o) - 'question_id' - 'public_id' AS content
                 FROM question_options o WHERE o.question_id = q.id) target_options)
      IS DISTINCT FROM
          (SELECT coalesce(jsonb_agg(content ORDER BY content::text), '[]'::jsonb)
           FROM (SELECT to_jsonb(o) - 'question_id' - 'public_id' AS content
                 FROM clone_source_options o WHERE o.question_id = s.id) source_options)
  ) OR EXISTS (
    SELECT 1 FROM question_options o JOIN questions q ON q.id = o.question_id
    JOIN clone_sources s ON q.public_id = s.clone_public_id
    JOIN clone_source_options original ON original.public_id = o.public_id
  ) THEN
    RAISE EXCEPTION 'Option content or identity verification failed';
  END IF;
END $$;

SELECT q.pool, count(*) AS questions,
       (SELECT count(*) FROM question_options o JOIN questions target ON target.id = o.question_id
        JOIN clone_sources s ON target.public_id = s.clone_public_id) AS cloned_options
FROM questions q JOIN clone_sources s ON q.public_id = s.clone_public_id GROUP BY q.pool;

\if :commit_clone
COMMIT;
\else
ROLLBACK;
\endif
