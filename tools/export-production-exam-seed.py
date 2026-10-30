"""Export the local reusable exam catalog and a demo admin to a portable SQL seed.

Requires Docker, the local pte-postgres container and Python bcrypt.
The destination must already have the current Flyway schema. No local user,
organization, attempt, score, session, credential or payment records are exported.
"""

import argparse
import hashlib
import json
import subprocess
from pathlib import Path

import bcrypt


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_OUTPUT = ROOT / "pte-doc/data/production/production-admin-exam-seed.sql"
ADMIN_ID = "cc916708-5818-45ad-a707-c34482f5fd97"
PARENTS = ("question_types", "media_objects", "questions", "exam_definitions")
CHILDREN = {
    "question_options": ("questions", "question_id"),
    "exam_definition_items": ("exam_definitions", "exam_definition_id"),
}


def docker(*args, sql=None):
    result = subprocess.run(
        ["docker", *args], input=sql, text=True, encoding="utf-8",
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True,
    )
    return result.stdout.strip()


def query(role, sql):
    return docker("exec", "-i", "pte-postgres", "psql", "-X", "-qAt",
                  "-v", "ON_ERROR_STOP=1", "-U", role, "-d", "pte", sql=sql)


def literal(value):
    return "'" + value.replace("'", "''") + "'"


def quoted(columns):
    return ", ".join('"' + name + '"' for name in columns)


def export_snapshot(role):
    fields = []
    for table in (*PARENTS, *CHILDREN):
        if table == "media_objects":
            source = """SELECT * FROM media_objects WHERE public_id IN (
                SELECT audio_prompt_ref FROM questions UNION SELECT image_prompt_ref FROM questions
            ) ORDER BY id"""
        elif table == "question_options":
            source = "SELECT * FROM question_options ORDER BY question_id, order_index"
        elif table == "exam_definition_items":
            source = "SELECT * FROM exam_definition_items ORDER BY exam_definition_id, sequence"
        else:
            source = f"SELECT * FROM {table} ORDER BY id"
        fields.extend([literal(table), f"(SELECT coalesce(jsonb_agg(to_jsonb(t)), '[]') FROM ({source}) t)"])
    sql = "BEGIN ISOLATION LEVEL REPEATABLE READ READ ONLY;\n"
    sql += "SELECT jsonb_build_object(" + ",".join(fields) + ");\nROLLBACK;"
    snapshot = json.loads(query(role, sql))
    if not snapshot["questions"] or not snapshot["question_types"]:
        raise ValueError("Local question bank or task catalog is empty")
    if any(row["tenant_id"] is not None for row in snapshot["questions"]):
        raise ValueError("Tenant-private questions require an explicit organization mapping")
    for table in PARENTS:
        for row in snapshot[table]:
            if "author_user_public_id" in row:
                row["author_user_public_id"] = ADMIN_ID
            if table == "media_objects":
                row.update(owner_public_id=ADMIN_ID, tenant_id=None,
                           practice_item_public_id=None, practice_session_public_id=None)
    return snapshot


def staging_sql(table, rows):
    payload = json.dumps(rows, ensure_ascii=False, separators=(",", ":"))
    tag = "$seed_" + hashlib.sha256(payload.encode()).hexdigest()[:12] + "$"
    return (
        f"CREATE TEMP TABLE seed_{table} ON COMMIT DROP AS SELECT * FROM public.{table} WITH NO DATA;\n"
        f"INSERT INTO seed_{table} SELECT * FROM jsonb_populate_recordset(\n"
        f"NULL::public.{table}, {tag}{payload}{tag}::jsonb);\n"
    )


def generate(snapshot, password_hash):
    sql = ["""-- Exported from local DB: reusable global exam content only.
-- Apply with psql -X -v ON_ERROR_STOP=1 -f this-file.sql on Flyway V14+ schema.
-- Demo admin password is stored only as BCrypt. Import is atomic and repeatable.
-- Referenced Cloudinary objects must remain accessible in production.
BEGIN;
SET LOCAL lock_timeout = '10s';
SET LOCAL statement_timeout = '120s';
SELECT pg_advisory_xact_lock(261031, 1);
DO $guard$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM flyway_schema_history WHERE version = '14' AND success) THEN
    RAISE EXCEPTION 'Apply the current Flyway migrations before importing this seed';
  END IF;
  IF EXISTS (SELECT 1 FROM exam_attempts) THEN
    RAISE EXCEPTION 'Seed requires a demo database without student attempts';
  END IF;
END $guard$;
LOCK TABLE users, user_roles, question_types, media_objects, questions,
  question_options, exam_definitions, exam_definition_items IN SHARE ROW EXCLUSIVE MODE;
"""]
    sql.append(f"""INSERT INTO users (created_at,updated_at,deleted,public_id,username,email,
    full_name,credential_hash,must_change_password,status)
VALUES (now(),now(),false,'{ADMIN_ID}','admin@gmail.com','admin@gmail.com',
    'Platform Admin',{literal(password_hash)},false,'ACTIVE')
ON CONFLICT (username) DO UPDATE SET email=EXCLUDED.email,
    credential_hash=EXCLUDED.credential_hash,deleted=false,status='ACTIVE',
    must_change_password=false,updated_at=now();
INSERT INTO user_roles(user_id,role)
SELECT id,'PLATFORM_ADMIN' FROM users WHERE username='admin@gmail.com'
AND NOT EXISTS (SELECT 1 FROM user_roles WHERE user_id=users.id AND role='PLATFORM_ADMIN');
""")
    # Preserve the public ID of an existing admin rather than breaking its references.
    for table in PARENTS:
        rows = snapshot[table]
        if not rows:
            continue
        sql.append(staging_sql(table, rows))
        owner_column = "owner_public_id" if table == "media_objects" else "author_user_public_id"
        sql.append(f"UPDATE seed_{table} SET {owner_column}=(SELECT public_id FROM users WHERE username='admin@gmail.com');\n")
        if table == "exam_definitions":
            sql.append("""UPDATE exam_definitions SET status='RETIRED',updated_at=now()
WHERE status='ACTIVE' AND public_id NOT IN
  (SELECT public_id FROM seed_exam_definitions WHERE status='ACTIVE');
""")
        columns = [name for name in rows[0] if name != "id"]
        conflict = "task_type_key" if table == "question_types" else "public_id"
        updates = ", ".join(f'"{col}"=EXCLUDED."{col}"' for col in columns if col != conflict)
        sql.append(f"INSERT INTO public.{table} ({quoted(columns)})\n"
                   f"SELECT {quoted(columns)} FROM seed_{table}\n"
                   f"ON CONFLICT ({conflict}) DO UPDATE SET {updates};\n")
    for table, (parent, fk) in CHILDREN.items():
        rows = snapshot[table]
        if not rows:
            continue
        sql.append(staging_sql(table, rows))
        sql.append(f"DELETE FROM {table} WHERE {fk} IN (SELECT p.id FROM {parent} p JOIN seed_{parent} s USING (public_id));\n")
        columns = list(rows[0])
        selected = ", ".join("target.id" if col == fk else f's."{col}"' for col in columns)
        sql.append(f"INSERT INTO {table} ({quoted(columns)})\nSELECT {selected}\n"
                   f"FROM seed_{table} s JOIN seed_{parent} source ON source.id=s.{fk}\n"
                   f"JOIN {parent} target ON target.public_id=source.public_id;\n")
    sql.append("""DO $validate$
BEGIN
  IF EXISTS (SELECT 1 FROM seed_questions s LEFT JOIN question_types t USING (task_type_key)
             WHERE t.id IS NULL) THEN
    RAISE EXCEPTION 'Question task-type reference missing';
  END IF;
  IF EXISTS (SELECT 1 FROM seed_questions q LEFT JOIN media_objects m
             ON m.public_id=q.audio_prompt_ref WHERE q.audio_prompt_ref IS NOT NULL AND m.id IS NULL)
     OR EXISTS (SELECT 1 FROM seed_questions q LEFT JOIN media_objects m
             ON m.public_id=q.image_prompt_ref WHERE q.image_prompt_ref IS NOT NULL AND m.id IS NULL) THEN
    RAISE EXCEPTION 'Question media reference missing';
  END IF;
  IF (SELECT count(*) FROM exam_definitions WHERE status='ACTIVE') <> 1 THEN
    RAISE EXCEPTION 'Exactly one active template is required';
  END IF;
END $validate$;
COMMIT;
""")
    return "\n".join(sql)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()
    role = docker("exec", "pte-postgres", "printenv", "POSTGRES_USER")
    snapshot = export_snapshot(role)
    password_hash = bcrypt.hashpw(b"admin", bcrypt.gensalt(rounds=12)).decode()
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(generate(snapshot, password_hash), encoding="utf-8")
    counts = {table: len(rows) for table, rows in snapshot.items()}
    manifest = {"source": "local pte-postgres/pte", "minimum_migration": "V14",
                "admin_email": "admin@gmail.com", "rows": counts,
                "excluded": ["local users", "organizations", "payments", "sessions", "attempts", "scores"],
                "sha256": hashlib.sha256(args.output.read_bytes()).hexdigest()}
    args.output.with_suffix(".manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    print(json.dumps(counts))
    print(args.output)


if __name__ == "__main__":
    main()
