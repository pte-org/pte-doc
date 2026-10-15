param(
  [ValidateSet("baseline", "questions", "final")]
  [string]$Stage = "baseline"
)

$ErrorActionPreference = "Stop"
$planRoot = Split-Path -Parent $MyInvocation.MyCommand.Path | Split-Path -Parent
$repoRoot = (Resolve-Path (Join-Path $planRoot "..\..\..\..")).Path
$webRoot = Join-Path $repoRoot "pte-web"
$apiRoot = Join-Path $repoRoot "pte-api"

function Read-RepoFile([string]$RelativePath) {
  $path = Join-Path $repoRoot $RelativePath
  if (-not (Test-Path -LiteralPath $path)) {
    throw "Missing required file: $RelativePath"
  }
  return Get-Content -Raw -LiteralPath $path
}

function Assert-Contains([string]$Text, [string]$Needle, [string]$Message) {
  if (-not $Text.Contains($Needle)) {
    throw "Contract failure: $Message"
  }
}

function Assert-NotContains([string]$Text, [string]$Needle, [string]$Message) {
  if ($Text.Contains($Needle)) {
    throw "Contract failure: $Message"
  }
}

function Assert-Matches([string]$Text, [string]$Pattern, [string]$Message) {
  if ($Text -notmatch $Pattern) {
    throw "Contract failure: $Message"
  }
}

$tabs = Read-RepoFile "pte-web/apps/tenant-web/features/exams/components/ExamDetailTabs.tsx"
$detail = Read-RepoFile "pte-web/apps/tenant-web/features/exams/components/SessionDetailView.tsx"
$previewApi = Read-RepoFile "pte-web/apps/tenant-web/features/exams/api/index.ts"
$previewDto = Read-RepoFile "pte-api/app/src/main/java/com/pte/session/internal/dto/response/ExamPreviewResponse.java"
$answerDetail = Read-RepoFile "pte-web/apps/tenant-web/features/exams/components/AnswerDetailModal.tsx"
$controller = Read-RepoFile "pte-api/app/src/main/java/com/pte/session/internal/controller/SessionController.java"
$lifecycle = Read-RepoFile "pte-api/app/src/main/java/com/pte/session/internal/service/SessionLifecycleService.java"
$orchestration = Read-RepoFile "pte-api/app/src/main/java/com/pte/session/internal/service/ExamOrchestrationService.java"
$examSession = Read-RepoFile "pte-api/app/src/main/java/com/pte/session/domain/ExamSession.java"
$handoffPath = Join-Path $planRoot "tests\phase-01-locale-handoff.json"

if (-not (Test-Path -LiteralPath $handoffPath)) {
  throw "Contract failure: locale handoff artifact is missing"
}
$handoff = Get-Content -Raw -LiteralPath $handoffPath | ConvertFrom-Json
$requiredLocaleKeys = @(
  "tenant.examTabs.questions",
  "tenant.examQuestions.title",
  "tenant.examQuestions.answerKeyNotice",
  "tenant.examQuestions.itemCount",
  "tenant.examQuestions.options",
  "tenant.examQuestions.audio",
  "tenant.examQuestions.wordCount",
  "tenant.examQuestions.imageAlt",
  "tenant.examQuestions.report",
  "tenant.examQuestions.reported",
  "tenant.examQuestions.unavailable",
  "tenant.examQuestions.empty",
  "tenant.examQuestions.error",
  "tenant.examOverview.back",
  "tenant.examOverview.status",
  "tenant.examOverview.open",
  "tenant.examOverview.close",
  "tenant.examOverview.cancel",
  "tenant.examOverview.closeConfirm",
  "tenant.examOverview.cancelConfirm",
  "tenant.examOverview.lifecycleError",
  "tenant.examStatus.draft",
  "tenant.examStatus.preparing",
  "tenant.examStatus.ready",
  "tenant.examStatus.scheduled",
  "tenant.examStatus.open",
  "tenant.examStatus.closed",
  "tenant.examStatus.cancelled",
  "tenant.support.reportQuestion.title",
  "tenant.support.reportQuestion.cancel",
  "tenant.support.reportQuestion.submit",
  "tenant.support.reportQuestion.submitting",
  "tenant.support.reportQuestion.description",
  "tenant.support.reportQuestion.placeholder",
  "tenant.support.reportQuestion.successToast"
)
$allowedHandoffStates = @("blocked-until-owner-confirms", "keys-already-available", "owner-handoff-confirmed")
if ([string]$handoff.status -notin $allowedHandoffStates) {
  throw "Contract failure: invalid locale handoff status '$($handoff.status)'"
}
$artifactKeys = @($handoff.requiredKeys | ForEach-Object { [string]$_ })
if (@($artifactKeys | Sort-Object -Unique).Count -ne $requiredLocaleKeys.Count -or
    (@($requiredLocaleKeys | Where-Object { $artifactKeys -notcontains $_ }).Count -gt 0)) {
  throw "Contract failure: locale handoff requiredKeys does not match the approved key set"
}
$availableKeys = @($handoff.availableKeys | ForEach-Object { [string]$_ })
$missingKeys = @($handoff.missingKeys | ForEach-Object { [string]$_ })
if (@($availableKeys + $missingKeys | Sort-Object -Unique).Count -ne $requiredLocaleKeys.Count -or
    (@($requiredLocaleKeys | Where-Object { ($availableKeys + $missingKeys) -notcontains $_ }).Count -gt 0) -or
    (@($availableKeys | Where-Object { $missingKeys -contains $_ }).Count -gt 0)) {
  throw "Contract failure: locale handoff key inventory is incomplete or overlapping"
}
if ($handoff.permissionToConsumeKeys -isnot [bool]) {
  throw "Contract failure: permissionToConsumeKeys must be boolean"
}
if ($handoff.status -eq "blocked-until-owner-confirms" -and $handoff.permissionToConsumeKeys) {
  throw "Contract failure: blocked locale handoff cannot grant consumption permission"
}
if ($handoff.status -in @("keys-already-available", "owner-handoff-confirmed") -and
    (-not $handoff.permissionToConsumeKeys -or $missingKeys.Count -gt 0)) {
  throw "Contract failure: an active locale handoff must grant permission and have no missing keys"
}
foreach ($hashField in @("observedBeforeSha256", "observedAfterSha256")) {
  if ([string]$handoff.$hashField -notmatch "^[A-Fa-f0-9]{64}$") {
    throw "Contract failure: locale handoff $hashField is not a SHA-256 value"
  }
}
$baselineEvidencePath = Join-Path $planRoot "tests\phase-01-baseline.json"
if (-not (Test-Path -LiteralPath $baselineEvidencePath)) {
  throw "Contract failure: baseline ownership ledger is missing"
}
$baselineEvidence = Get-Content -Raw -LiteralPath $baselineEvidencePath | ConvertFrom-Json
foreach ($property in $baselineEvidence.protectedFiles.psobject.Properties) {
  $path = Join-Path $repoRoot ([string]$property.Name)
  if (-not (Test-Path -LiteralPath $path)) {
    throw "Contract failure: protected file is missing: $($property.Name)"
  }
  $currentHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash
  $allowedHashes = @([string]$property.Value)
  $drift = $null
  if ($null -ne $baselineEvidence.concurrentProtectedDrift) {
    $drift = $baselineEvidence.concurrentProtectedDrift.psobject.Properties |
      Where-Object { $_.Name -eq $property.Name } |
      Select-Object -First 1
    if ($null -ne $drift) {
      $allowedHashes += [string]$drift.Value.currentSha256
    }
  }
  if ($property.Name -eq "pte-web/packages/ui/src/i18n/LocaleProvider.tsx") {
    $allowedHashes += [string]$handoff.observedAfterSha256
  }
  if ($allowedHashes -notcontains $currentHash) {
    throw "Contract failure: protected file hash drifted without recorded handoff: $($property.Name)"
  }
  if ($currentHash -ne [string]$property.Value -and
      $null -eq $drift -and
      $property.Name -ne "pte-web/packages/ui/src/i18n/LocaleProvider.tsx") {
    throw "Contract failure: protected file drift has no concurrency classification: $($property.Name)"
  }
}
if ($Stage -eq "baseline") {
  foreach ($property in $baselineEvidence.laterOwnedSourceFiles.psobject.Properties) {
    if ($null -eq $property.Value -or [string]::IsNullOrWhiteSpace([string]$property.Value)) { continue }
    $path = Join-Path $repoRoot ([string]$property.Name)
    if (-not (Test-Path -LiteralPath $path)) {
      throw "Contract failure: baseline-owned source file is missing: $($property.Name)"
    }
    $currentHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash
    if ($currentHash -ne [string]$property.Value) {
      throw "Contract failure: later-owned source file changed before Phase 01 handoff: $($property.Name)"
    }
  }
}

Assert-Contains $previewApi "EXAM_PREVIEW_QUERY_KEY" "existing preview query key must remain"
Assert-Contains $previewApi "useSessionExamPreview" "existing preview hook must remain"
Assert-Contains $controller "hasRole('HOST_ADMIN')" "session controller must remain HOST_ADMIN-only"
Assert-Contains $lifecycle "findByPublicIdAndTenantId" "lifecycle lookup must remain tenant-scoped"
Assert-Contains $orchestration "findWithLockByPublicIdAndTenantId" "orchestration lookup must remain tenant-scoped"
Assert-Contains $examSession "snapshotPublicId" "session must retain snapshot identity"
Assert-Contains $previewDto "Deliberately excludes option correctness" "preview DTO must document answer-key exclusion"
if ($previewDto -match "\b(correct|isCorrect|score)\s*[;,(]") {
  throw "Contract failure: preview DTO appears to expose correctness or score metadata"
}
if ($answerDetail -match "option\.correct|teacher|score") {
  Write-Output "AnswerDetailModal contains scoring metadata and remains disallowed for Questions."
}

if ($Stage -eq "baseline") {
  Assert-Contains $tabs 'type ExamDetailTab = "overview" | "settings" | "participants" | "submissions" | "examiner" | "results";' "baseline must remain the observed six-tab source"
  Assert-Matches $tabs '(?s)"overview",\s*"settings",\s*"participants",\s*"submissions",\s*"examiner",\s*"results",' "baseline tab order must be six tabs"
  Assert-Contains $detail "useOpenSession" "detail shell must own Open mutation"
  Assert-Contains $detail "useCloseSession" "detail shell must own Close mutation"
  Assert-Contains $detail "useCancelSession" "detail shell must own Cancel mutation"
  Assert-Contains $detail 'session.status === "SCHEDULED"' "baseline Open guard must be present"
  Assert-Contains $detail 'session.status === "OPEN"' "baseline Close guard must be present"
  Assert-Contains $detail '"DRAFT", "PREPARING", "READY", "SCHEDULED"' "baseline Cancel guard must be present"
  Write-Output "PASS: Phase 01 baseline contract"
  exit 0
}

$questions = Read-RepoFile "pte-web/apps/tenant-web/features/exams/components/ExamQuestionsTab.tsx"
$surface = Read-RepoFile "pte-web/apps/tenant-web/features/exams/components/ExamPreviewSurface.tsx"
$content = Read-RepoFile "pte-web/apps/tenant-web/features/exams/components/ExamPreviewContent.tsx"
Assert-Matches $tabs '(?s)"overview",\s*"questions",\s*"settings",\s*"participants",\s*"submissions",\s*"examiner",\s*"results",' "target tabs must have Questions second"
Assert-Contains $tabs "ExamQuestionsTab" "target tabs must render Questions"
Assert-Contains $questions "snapshotPublicId" "Questions must receive snapshot availability"
Assert-Contains $surface "snapshotPublicId" "shared preview surface must gate snapshot availability"
Assert-Contains $surface "items.length === 0" "shared preview surface must have a successful-empty branch"
Assert-Contains $content "onReport" "content must use callback-only report support"
Assert-NotContains $content "option.correct" "Questions content must not render answer keys"
Assert-NotContains $content "AnswerDetailModal" "Questions content must not use scoring modal"
if ($handoff.status -notin @("keys-already-available", "owner-handoff-confirmed")) {
  throw "BLOCKED: locale handoff status is '$($handoff.status)'; Phase $Stage cannot consume new locale keys"
}

if ($Stage -eq "questions") {
  Write-Output "PASS: Questions-stage contract"
  exit 0
}

Assert-NotContains $detail "lifecycleError && <Alert" "detail shell must not render a duplicate lifecycle error"
$overview = Read-RepoFile "pte-web/apps/tenant-web/features/exams/components/ExamOverviewTab.tsx"
Assert-Contains $overview "lifecycleError" "Overview must own the lifecycle error"
Assert-Contains $overview "onOpen" "Overview must receive the Open callback"
Assert-Contains $overview "onClose" "Overview must receive the Close callback"
Assert-Contains $overview "onCancel" "Overview must receive the Cancel callback"
Write-Output "PASS: Final lifecycle contract"
