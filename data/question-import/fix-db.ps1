###############################################################################
# fix-db.ps1 — Fixes data issues in the local dev DB without touching volumes
#
# Fixes applied:
#   1. FILL_IN_THE_BLANKS_DROPDOWN / DRAG_AND_DROP: prompt_text gap markers
#      were 1-indexed ({{1}}, {{2}}...) but blankIndex / correctGapIndex are
#      0-indexed. Changed to {{0}}, {{1}}... in both `questions` and
#      `pinned_items` tables.
#   2. Encoding: WRITE_ESSAY / SUMMARIZE_WRITTEN_TEXT promptTexts have
#      garbled Unicode (Windows-1252 read of UTF-8 source). Replaced with
#      correct Unicode chars using CHR() sequences.
###############################################################################

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$Container = "pte-postgres"
$PgUser    = "pte-db"
$PgDb      = "pte"

function Invoke-Sql {
    param([string]$Label, [string]$Sql)
    Write-Host "  >> $Label"
    $out = docker exec -i $Container psql -U $PgUser -d $PgDb -t -c $Sql 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Error "SQL failed ($Label): $out"
        exit 1
    }
    Write-Host "     $($out.Trim())"
}

Write-Host "`n== Fix 1: FIB gap markers (1-indexed -> 0-indexed) =="
Write-Host "   Using intermediate [[n]] placeholders to avoid cascade conflicts"

# ── FILL_IN_THE_BLANKS_DROPDOWN ─────────────────────────────────────────────
$fib_dd = @"
UPDATE questions SET prompt_text =
    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
        prompt_text,
        '{{1}}','[[0]]'),'{{2}}','[[1]]'),'{{3}}','[[2]]'),'{{4}}','[[3]]'),
        '[[0]]','{{0}}'),'[[1]]','{{1}}'),'[[2]]','{{2}}'),'[[3]]','{{3}}')
WHERE task_type_key = 'FILL_IN_THE_BLANKS_DROPDOWN'
  AND prompt_text LIKE '%{{1}}%';
"@
Invoke-Sql "questions: FILL_IN_THE_BLANKS_DROPDOWN markers" $fib_dd

$fib_dd_pin = @"
UPDATE pinned_items SET prompt_text =
    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
        prompt_text,
        '{{1}}','[[0]]'),'{{2}}','[[1]]'),'{{3}}','[[2]]'),'{{4}}','[[3]]'),
        '[[0]]','{{0}}'),'[[1]]','{{1}}'),'[[2]]','{{2}}'),'[[3]]','{{3}}')
WHERE task_type_key = 'FILL_IN_THE_BLANKS_DROPDOWN'
  AND prompt_text LIKE '%{{1}}%';
"@
Invoke-Sql "pinned_items: FILL_IN_THE_BLANKS_DROPDOWN markers" $fib_dd_pin

# ── FILL_IN_THE_BLANKS_DRAG_AND_DROP ────────────────────────────────────────
$fib_dnd = @"
UPDATE questions SET prompt_text =
    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
        prompt_text,
        '{{1}}','[[0]]'),'{{2}}','[[1]]'),'{{3}}','[[2]]'),'{{4}}','[[3]]'),'{{5}}','[[4]]'),
        '[[0]]','{{0}}'),'[[1]]','{{1}}'),'[[2]]','{{2}}'),'[[3]]','{{3}}'),'[[4]]','{{4}}')
WHERE task_type_key = 'FILL_IN_THE_BLANKS_DRAG_AND_DROP'
  AND prompt_text LIKE '%{{1}}%';
"@
Invoke-Sql "questions: FILL_IN_THE_BLANKS_DRAG_AND_DROP markers" $fib_dnd

$fib_dnd_pin = @"
UPDATE pinned_items SET prompt_text =
    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
        prompt_text,
        '{{1}}','[[0]]'),'{{2}}','[[1]]'),'{{3}}','[[2]]'),'{{4}}','[[3]]'),'{{5}}','[[4]]'),
        '[[0]]','{{0}}'),'[[1]]','{{1}}'),'[[2]]','{{2}}'),'[[3]]','{{3}}'),'[[4]]','{{4}}')
WHERE task_type_key = 'FILL_IN_THE_BLANKS_DRAG_AND_DROP'
  AND prompt_text LIKE '%{{1}}%';
"@
Invoke-Sql "pinned_items: FILL_IN_THE_BLANKS_DRAG_AND_DROP markers" $fib_dnd_pin

Write-Host "`n== Fix 2: Encoding (Windows-1252 misread of UTF-8 special chars) =="
Write-Host "   CHR(226)+CHR(8364)+CHR(8220) = bad en-dash  -> CHR(8211) = correct en-dash"
Write-Host "   CHR(226)+CHR(8364)+CHR(339)  = bad open-'''' -> CHR(8220) = correct open-''''"
Write-Host "   CHR(226)+CHR(8364)+CHR(157)  = bad close-'''-> CHR(8221) = correct close-''''"

# Order matters: fix en-dash FIRST (its 3rd byte CHR(8220) is the correct open-quote,
# and replacing open-quote first could corrupt the en-dash pattern).

$enc_q = @"
UPDATE questions SET prompt_text =
    REPLACE(REPLACE(REPLACE(
        prompt_text,
        CHR(226)||CHR(8364)||CHR(8220), CHR(8211)),
        CHR(226)||CHR(8364)||CHR(339),  CHR(8220)),
        CHR(226)||CHR(8364)||CHR(157),  CHR(8221))
WHERE task_type_key IN ('WRITE_ESSAY','SUMMARIZE_WRITTEN_TEXT','SUMMARIZE_SPOKEN_TEXT')
  AND prompt_text LIKE '%' || CHR(226) || '%';
"@
Invoke-Sql "questions: fix encoding" $enc_q

$enc_pin = @"
UPDATE pinned_items SET prompt_text =
    REPLACE(REPLACE(REPLACE(
        prompt_text,
        CHR(226)||CHR(8364)||CHR(8220), CHR(8211)),
        CHR(226)||CHR(8364)||CHR(339),  CHR(8220)),
        CHR(226)||CHR(8364)||CHR(157),  CHR(8221))
WHERE task_type_key IN ('WRITE_ESSAY','SUMMARIZE_WRITTEN_TEXT','SUMMARIZE_SPOKEN_TEXT')
  AND prompt_text LIKE '%' || CHR(226) || '%';
"@
Invoke-Sql "pinned_items: fix encoding" $enc_pin

Write-Host "`n== Done. Verify with: =="
Write-Host "   docker exec -i $Container psql -U $PgUser -d $PgDb -c ``"
Write-Host "     SELECT task_type_key, LEFT(prompt_text,80) FROM questions"
Write-Host "     WHERE task_type_key IN ('FILL_IN_THE_BLANKS_DROPDOWN','FILL_IN_THE_BLANKS_DRAG_AND_DROP','WRITE_ESSAY','SUMMARIZE_WRITTEN_TEXT');`""
