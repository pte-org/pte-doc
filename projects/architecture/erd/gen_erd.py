"""Sinh D2 (logical ERD theo module) và D3 (physical schema) từ V1__baseline.sql.

Chạy: python gen_erd.py. Nguồn hiện chỉ là V1, chưa áp dụng migration V2+.
D0, D1 và D4 viết tay, script không động vào.
"""
import re
import pathlib

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[3]
MIGRATIONS = ROOT / 'pte-api' / 'app' / 'src' / 'main' / 'resources' / 'db' / 'migration'
V1_LINK = '../../../../pte-api/app/src/main/resources/db/migration/'

GROUPS = {
    'org': ('tenancy, identity, enrollment', [
        'organizations', 'organization_quota_grants', 'users', 'user_roles', 'organization_members',
        'organization_member_roles', 'refresh_tokens', 'programs', 'classes', 'class_students', 'class_lecturers']),
    'content': ('itembank, assessment, media', [
        'question_types', 'questions', 'question_options', 'exam_blueprints', 'blueprint_items',
        'exam_definitions', 'exam_definition_items', 'exam_versions', 'exam_version_items', 'media_objects']),
    'exam': ('session, attempt, proctoring', [
        'exam_sessions', 'exam_session_selected_skills', 'exam_session_audience_sources', 'exam_session_proctors',
        'exam_registrations', 'exam_attempts', 'attempt_answers', 'exam_incidents']),
    'scoring': ('scoring, reporting', ['answer_evaluations', 'grading_assignments', 'grading_issues', 'exam_results']),
    'practice': ('practice', ['practice_sessions', 'practice_responses', 'otp_challenges']),
    'billing': ('billing', ['service_plans', 'orders', 'order_payments', 'subscriptions', 'license_codes',
                            'platform_settings']),
    'comms': ('notification, support, shared', [
        'notifications', 'notification_recipients', 'notification_recipient_streams', 'notification_inbox_snapshots',
        'notification_announcements', 'notification_logs', 'support_ticket', 'support_ticket_note', 'audit_logs',
        'idempotency_keys']),
}

USER_REFS = {
    'student_public_id', 'examiner_public_id', 'proctor_public_id', 'assignee_public_id', 'author_user_public_id',
    'reporter_public_id', 'submitter_user_public_id', 'admin_public_id', 'recipient_user_public_id',
    'owner_public_id', 'assigned_by_public_id', 'grading_frozen_by_public_id', 'published_by_public_id',
    'last_actor_public_id', 'reported_by', 'resolved_by', 'reviewed_by', 'actor_user_id', 'created_by',
    'issued_by', 'selected_score_source_by', 'user_id',
}
REFS = {
    'tenant_id': 'organizations', 'organization_id': 'organizations', 'redeemed_by_tenant_id': 'organizations',
    'session_public_id': 'exam_sessions', 'prior_session_public_id': 'exam_sessions',
    'attempt_public_id': 'exam_attempts', 'answer_public_id': 'attempt_answers',
    'item_public_id': 'exam_version_items', 'exam_definition_public_id': 'exam_definitions',
    'exam_version_public_id': 'exam_versions', 'source_blueprint_public_id': 'exam_blueprints',
    'source_question_public_id': 'questions', 'question_public_id': 'questions', 'supersedes_public_id': 'questions',
    'plan_id': 'service_plans', 'subscription_id': 'subscriptions', 'assignment_id': 'grading_assignments',
    'practice_session_id': 'practice_sessions', 'practice_session_public_id': 'practice_sessions',
    'practice_item_public_id': 'practice_responses', 'content_public_id': 'notifications',
    'published_content_public_id': 'notifications', 'correction_of_public_id': 'notification_announcements',
    'ticket_id': 'support_ticket', 'ticket_public_id': 'support_ticket',
    'selected_evaluation_public_id': 'answer_evaluations',
    **{c: 'users' for c in USER_REFS},
}
# Cột đa hình: chỉ ghi chú, không vẽ đường
POLYMORPHIC = {'target_public_id': 'target_type', 'aggregate_id': 'aggregate_type', 'entity_id': 'entity_type',
               'source_public_id': 'source_type'}
# tenant_id / organization_id chỉ đánh dấu, không vẽ đường (trừ nhóm org)
TENANT_COLS = {'tenant_id', 'organization_id'}
ONE_TO_ONE = {('exam_results', 'attempt_public_id')}
# Cột vai trò chính, dùng làm nhãn khi một bảng có nhiều tham chiếu tới users
PRIMARY_USER_REFS = ['student_public_id', 'examiner_public_id', 'proctor_public_id', 'assignee_public_id',
                     'recipient_user_public_id', 'submitter_user_public_id', 'author_user_public_id',
                     'owner_public_id', 'user_id', 'reporter_public_id']

BUSINESS = {
    'name', 'code', 'email', 'username', 'full_name', 'title', 'capacity', 'opens_at', 'closes_at',
    'max_retries_per_student', 'price', 'currency', 'duration_days', 'amount', 'score', 'overall_score',
    'listening_score', 'reading_score', 'speaking_score', 'writing_score', 'started_at', 'submitted_at',
    'expires_at', 'starts_at', 'attempt_number', 'version', 'revision_number', 'is_current',
    'available_for_exam', 'available_for_practice', 'session_code', 'order_code', 'setting_key', 'value',
    'sequence', 'order_index', 'task_type_key', 'deadline_at', 'time_limit_seconds', 'published', 'published_at',
    'student_limit', 'suspended_until', 'max_students_per_session', 'license_key', 'idempotency_key',
    'token_hash', 'category', 'importance', 'role', 'skill', 'correct', 'purpose', 'attempts', 'read_at',
    'sequence_no', 'last_sequence', 'paid_at', 'redeemed_at', 'code_expires_at', 'teacher_score', 'feedback',
    'grading_excluded', 'exam_definition_version', 'generation_seed', 'display_name', 'lifecycle_status',
    'active', 'scored', 'payload', 'processed', 'received_at', 'detected_at', 'notification_type', 'action',
    'completed', 'student_code', 'identity_note', 'work_version', 'finalized_at', 'objective_score',
    'ai_score', 'product_code', 'completed_at', 'source', 'decision_kind', 'item_order_index',
}

SQL_TYPES = [
    ('timestamp', 'instant'), ('character varying', 'string'), ('text', 'string'), ('uuid', 'uuid'),
    ('bigint', 'long'), ('integer', 'int'), ('smallint', 'int'), ('boolean', 'bool'), ('jsonb', 'json'),
    ('json', 'json'), ('numeric', 'decimal'), ('double precision', 'double'), ('date', 'date'),
]


def logical_type(sql):
    for prefix, name in SQL_TYPES:
        if sql.startswith(prefix):
            return name
    return sql.split('(')[0].replace(' ', '_')


def parse():
    path = MIGRATIONS / 'V1__baseline.sql'
    text = path.read_text(encoding='utf-8')
    line_of = lambda pos: text.count('\n', 0, pos) + 1
    tables = {}
    for m in re.finditer(r'^CREATE TABLE (?:public\.)?(\w+) \(\n([\s\S]*?)\n\);', text, re.M):
        cols, checks = [], []
        for raw in m.group(2).split('\n'):
            line = raw.strip().rstrip(',')
            if not line:
                continue
            if line.startswith('CONSTRAINT') or line.startswith('CHECK'):
                checks.append(line)
                continue
            cm = re.match(r'"?(\w+)"?\s+(.+?)(\s+NOT NULL)?(\s+DEFAULT .+)?$', line)
            if cm:
                cols.append(dict(name=cm.group(1), sql=cm.group(2).strip(), notnull=bool(cm.group(3)),
                                 default=(cm.group(4) or '').strip()))
        tables[m.group(1)] = dict(cols=cols, checks=checks, line=line_of(m.start()), pk=[], uniques=[], fks={},
                                  excludes=[], indexes=[])
    for m in re.finditer(r'ALTER TABLE (?:ONLY )?(?:public\.)?(\w+)\s+ADD CONSTRAINT (\w+) ([\s\S]*?);\n', text):
        t, name, body = m.group(1), m.group(2), ' '.join(m.group(3).split())
        if t not in tables:
            continue
        if body.startswith('PRIMARY KEY'):
            tables[t]['pk'] = [c.strip().strip('"') for c in re.search(r'\((.*?)\)', body).group(1).split(',')]
        elif body.startswith('UNIQUE'):
            tables[t]['uniques'].append([c.strip() for c in re.search(r'\((.*?)\)', body).group(1).split(',')])
        elif body.startswith('FOREIGN KEY'):
            fm = re.match(r'FOREIGN KEY \((\w+)\) REFERENCES (?:public\.)?(\w+)', body)
            tables[t]['fks'][fm.group(1)] = fm.group(2)
        elif body.startswith('EXCLUDE'):
            tables[t]['excludes'].append(f'{name}: {body}')
        elif body.startswith('CHECK'):
            tables[t]['checks'].append(f'CONSTRAINT {name} {body}')
    for m in re.finditer(r'^CREATE (UNIQUE )?INDEX (\w+) ON (?:public\.)?(\w+) USING (\w+) (\(.*?\))( WHERE .*)?;',
                         text, re.M):
        if m.group(3) in tables:
            tables[m.group(3)]['indexes'].append(
                dict(name=m.group(2), unique=bool(m.group(1)), method=m.group(4), cols=m.group(5),
                     where=(m.group(6) or '').strip()))
    for t in tables.values():
        t['enums'] = {}
        for chk in t['checks']:
            em = re.search(r'\(\(*(\w+)\)*(?:::text)? = ANY \(\(*ARRAY\[(.*?)\]', chk)
            if em:
                t['enums'][em.group(1)] = re.findall(r"'(\w+)'", em.group(2))
    return tables


AUDIT = {'id', 'created_at', 'updated_at', 'deleted'}


def d2_attributes(table, info):
    out, runtime, ai = [], 0, 0
    has_public = any(c['name'] == 'public_id' for c in info['cols'])
    for c in info['cols']:
        n = c['name']
        if n in AUDIT:
            continue
        if n.startswith('runtime_'):
            runtime += 1
            continue
        if n.startswith('ai_') and n != 'ai_score' and table != 'answer_evaluations':
            ai += 1
            continue
        key, comment = '', ''
        if n == 'public_id':
            key = 'PK'
        elif not has_public and n in info['pk']:
            key = 'PK'
        if n in info['fks']:
            key = (key + ', FK').strip(', ') if key else 'FK'
            comment = f"FK {info['fks'][n]}"
        elif n in TENANT_COLS:
            comment = 'tenant'
        elif n in REFS:
            comment = f'ref {REFS[n]}'
        elif n in POLYMORPHIC:
            comment = f'đa hình theo {POLYMORPHIC[n]}'
        if any(n in u and len(u) == 1 for u in info['uniques']) and n != 'public_id':
            key = (key + ', UK') if key else 'UK'
        keep = (key or comment or n in info['enums'] or n in BUSINESS or n.endswith('_id')
                or n == 'status' or n in {'section', 'type'})
        if not keep:
            continue
        typ = 'enum' if n in info['enums'] else logical_type(c['sql'])
        if n in info['enums']:
            values = info['enums'][n]
            comment = ' | '.join(values) if len(values) <= 6 else ' | '.join(values[:5]) + f' ... ({len(values)})'
        out.append((typ, n, key, comment))
    if runtime:
        out.append(('string', 'runtime_contract', '', f'gom {runtime} cột runtime_*'))
    if ai:
        out.append(('string', 'ai_result', '', f'gom {ai} cột ai_*'))
    return out


def mermaid_attr(typ, name, key, comment):
    parts = [f'    {typ} {name}']
    if key:
        parts.append(key)
    if comment:
        parts.append('"' + comment.replace('"', "'") + '"')
    return ' '.join(parts)


def d2(group, tables):
    title, members = GROUPS[group]
    lines = ['---', f'title: D2 Logical ERD - {title}', '---',
             '%% Sinh bởi gen_erd.py từ V1__baseline.sql. Không sửa tay; sửa script rồi chạy lại.',
             '%% Nét liền = FK thật trong DB. Nét đứt = tham chiếu logic bằng UUID (không có FK).',
             '%% Bảng không có thuộc tính = thuộc module khác, xem file D2 tương ứng.',
             '%% Mọi bảng entity còn có id (bigint), created_at, updated_at, deleted (xóa mềm).',
             'erDiagram']
    rels, seen = [], set()
    for t in members:
        info = tables[t]
        for c in info['cols']:
            n = c['name']
            if n in info['fks']:
                rels.append(f'  {info["fks"][n]} ||--o{{ {t} : "{n}"')
                continue
            target = REFS.get(n)
            if not target or target == t and n != 'supersedes_public_id':
                continue
            if n in TENANT_COLS and group != 'org':
                continue
            if n in TENANT_COLS and group == 'org' and t not in {'organization_members', 'programs', 'refresh_tokens'}:
                continue
            key = (t, target)
            if target == 'users':
                if key in seen:
                    continue
                cols = sorted((x['name'] for x in info['cols']
                               if REFS.get(x['name']) == 'users' and x['name'] not in info['fks']),
                              key=lambda c: PRIMARY_USER_REFS.index(c) if c in PRIMARY_USER_REFS else 99)
                label = cols[0] if len(cols) == 1 else f'{cols[0]} +{len(cols) - 1}'
                seen.add(key)
                rels.append(f'  users ||..o{{ {t} : "{label}"')
                continue
            card = '||..o|' if (t, n) in ONE_TO_ONE else '||..o{'
            rels.append(f'  {target} {card} {t} : "{n}"')
    for t in members:
        lines.append(f'  {t} {{')
        lines += [mermaid_attr(*a) for a in d2_attributes(t, tables[t])]
        lines.append('  }')
    lines += rels
    return '\n'.join(lines) + '\n'


def d3(tables):
    out = ['# D3 – Physical schema', '',
           '> Sinh bởi `gen_erd.py` từ `V1__baseline.sql`. Không sửa tay. Generator hiện chỉ đọc V1, chưa áp dụng migration V2+.',
           '', f'Tổng: {len(tables)} bảng. Kiểu cột ghi nguyên văn PostgreSQL. `PK` / `FK` / `UK` lấy từ constraint.',
           '', '## Mục lục', '']
    order = [t for _, (_, ms) in GROUPS.items() for t in ms]
    missing = [t for t in tables if t not in order]
    for g, (title, ms) in GROUPS.items():
        out.append(f'- **{title}**: ' + ', '.join(f'[`{t}`](#{t})' for t in ms))
    if missing:
        out.append('- **chưa phân nhóm**: ' + ', '.join(f'`{t}`' for t in missing))
    for g, (title, ms) in GROUPS.items():
        out += ['', f'## {title}']
        for t in ms:
            info = tables[t]
            out += ['', f'### {t}', '', f'[V1 dòng {info["line"]}]({V1_LINK}V1__baseline.sql#L{info["line"]})', '',
                    '| Cột | Kiểu | Null | Ràng buộc |', '|---|---|---|---|']
            for c in info['cols']:
                n, tags = c['name'], []
                if n in info['pk']:
                    tags.append('PK')
                if n in info['fks']:
                    tags.append(f'FK → `{info["fks"][n]}`')
                elif n in REFS:
                    tags.append(f'ref → `{REFS[n]}` (logic)')
                if any(u == [n] for u in info['uniques']):
                    tags.append('UK')
                if n in info['enums']:
                    tags.append('CHECK: ' + ', '.join(info['enums'][n]))
                if c['default']:
                    tags.append(c['default'].replace('|', '\\|'))
                out.append(f"| `{n}` | {c['sql']} | {'' if c['notnull'] else 'có'} | {'; '.join(tags)} |")
            multi = [u for u in info['uniques'] if len(u) > 1]
            if multi:
                out += ['', 'Unique nhiều cột: ' + '; '.join('(' + ', '.join(u) + ')' for u in multi)]
            if info['excludes']:
                out += ['', 'Exclusion: ' + '; '.join(f'`{e}`' for e in info['excludes'])]
            other_checks = [c for c in info['checks'] if 'ANY' not in c]
            if other_checks:
                out += ['', 'CHECK khác: ' + '; '.join(f'`{c[:160]}`' for c in other_checks)]
            if info['indexes']:
                out += ['', 'Index: ' + '; '.join(
                    f"`{i['name']}`{' (unique)' if i['unique'] else ''} {i['cols']}{(' ' + i['where']) if i['where'] else ''}"
                    for i in info['indexes'])]
    return '\n'.join(out) + '\n'


def main():
    import sys
    sys.stdout.reconfigure(encoding="utf-8")
    tables = parse()
    grouped = {t for _, (_, ms) in GROUPS.items() for t in ms}
    unknown = sorted(set(tables) - grouped)
    if unknown:
        print('Bảng chưa phân nhóm trong GROUPS:', ', '.join(unknown))
    for g in GROUPS:
        (HERE / f'd2-logical-{g}.mmd').write_text(d2(g, tables), encoding='utf-8')
    (HERE / 'd3-physical.md').write_text(d3(tables), encoding='utf-8')
    fk_count = sum(len(t['fks']) for t in tables.values())
    print(f'{len(tables)} bảng, {fk_count} FK, {len(GROUPS)} file D2, 1 file D3')


if __name__ == '__main__':
    main()
