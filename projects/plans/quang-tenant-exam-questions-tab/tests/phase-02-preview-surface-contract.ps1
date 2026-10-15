$ErrorActionPreference = "Stop"

$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\..\..\..\.."))
$webRoot = Join-Path $repoRoot "pte-web"
$failures = [System.Collections.Generic.List[string]]::new()

function Read-ScopedFile([string] $relativePath) {
  $path = Join-Path $webRoot $relativePath
  if (-not (Test-Path -LiteralPath $path)) {
    $failures.Add("Missing file: $relativePath")
    return ""
  }
  return Get-Content -Raw -LiteralPath $path
}

function Assert-Contains([string] $label, [string] $content, [string] $needle) {
  if (-not $content.Contains($needle)) {
    $failures.Add($label + " missing: " + $needle)
  }
}

function Assert-NotContains([string] $label, [string] $content, [string] $needle) {
  if ($content.Contains($needle)) {
    $failures.Add($label + " must not contain: " + $needle)
  }
}

$content = Read-ScopedFile "apps/tenant-web/features/exams/components/ExamPreviewContent.tsx"
$surface = Read-ScopedFile "apps/tenant-web/features/exams/components/ExamPreviewSurface.tsx"
$modal = Read-ScopedFile "apps/tenant-web/features/exams/components/ExamPreviewModal.tsx"
$questions = Read-ScopedFile "apps/tenant-web/features/exams/components/ExamQuestionsTab.tsx"
$report = Read-ScopedFile "apps/tenant-web/features/supportTickets/components/ReportQuestionModal.tsx"

Assert-Contains "surface query gate" $surface "useSessionExamPreview(sessionPublicId, enabled && Boolean(snapshotPublicId))"
Assert-Contains "surface report selection" $surface "reportingQuestionId"
Assert-Contains "surface reported state" $surface "reportedQuestionIds"
Assert-Contains "surface unavailable branch" $surface "!snapshotPublicId"
Assert-Contains "surface loading branch" $surface "preview.isLoading"
Assert-Contains "surface error branch" $surface "preview.isError"
Assert-Contains "surface empty branch" $surface "preview.data.items.length === 0"
Assert-Contains "surface content branch" $surface "ExamPreviewContent"

Assert-Contains "content section grouping" $content "const sectionKey = item.section"
Assert-Contains "content task grouping" $content "const taskKey = item.taskType"
Assert-Contains "content order sorting" $content "left.item.orderIndex - right.item.orderIndex"
Assert-Contains "content localized title" $content 'tenant.examQuestions.title'
Assert-Contains "content localized report action" $content 'tenant.examQuestions.report'
Assert-Contains "content semantic section" $content "<section"
Assert-Contains "content semantic question" $content "<article"
Assert-NotContains "content answer-key boundary" $content "option.correct"
Assert-NotContains "content scoring boundary" $content "AnswerDetailModal"

Assert-Contains "modal snapshot contract" $modal "snapshotPublicId: string | null"
Assert-Contains "modal surface delegation" $modal "<ExamPreviewSurface"
Assert-Contains "modal enabled contract" $modal "enabled={open}"
Assert-NotContains "modal query ownership" $modal "useSessionExamPreview"
Assert-NotContains "modal report ownership" $modal "ReportQuestionModal"
Assert-NotContains "modal local state ownership" $modal "useState"
Assert-Contains "questions snapshot handoff" $questions "snapshotPublicId={session.snapshotPublicId}"

Assert-Contains "report locale hook" $report "useLocale"
Assert-Contains "report title locale" $report "tenant.support.reportQuestion.title"
Assert-Contains "report submit locale" $report "tenant.support.reportQuestion.submit"
Assert-Contains "report submitting locale" $report "tenant.support.reportQuestion.submitting"
Assert-Contains "report description locale" $report "tenant.support.reportQuestion.description"
Assert-Contains "report placeholder locale" $report "tenant.support.reportQuestion.placeholder"
Assert-NotContains "report light-only classes" $report "gray-"

if ($failures.Count -gt 0) {
  Write-Output "FAIL: Phase 02 preview surface contract"
  $failures | ForEach-Object { Write-Output ("- " + $_) }
  exit 1
}

Write-Output "PASS: Phase 02 preview surface contract"
exit 0
