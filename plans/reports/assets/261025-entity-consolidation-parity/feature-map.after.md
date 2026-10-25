# Feature map after entity consolidation (2026-10-25)

260 endpoints (exporter), 3 STOMP handlers; phase 1 baseline: 328 / 3. Every feature of `feature-map.before.md` still has an endpoint or an intentional removal listed below.

| Feature (controller) | Endpoints before | Endpoints after | Note |
|---|---|---|---|
| AdminDashboardController | 1 | 1 |  |
| AdminLicenseCodeController | 7 | 7 |  |
| AdminSupportTicketController | 4 | 4 |  |
| AnnouncementController | 8 | 7 | status actions merged into PATCH .../status or unused routes removed |
| AttemptController | 12 | 11 | status actions merged into PATCH .../status or unused routes removed |
| AttemptEvidenceController | 0 | 1 | new |
| AttendanceController | 0 | 5 | new |
| AuditLogController | 1 | 1 |  |
| AuthController | 7 | 7 |  |
| BlueprintController | 9 | 5 | status actions merged into PATCH .../status or unused routes removed |
| ClassController | 14 | 11 | status actions merged into PATCH .../status or unused routes removed |
| ClassMembershipController | 1 | 1 |  |
| EnrollmentController | 4 | 4 |  |
| ExamDefinitionController | 0 | 9 | new |
| ExamIncidentController | 0 | 5 | new |
| ExamSessionIncidentController | 5 | 0 | status actions merged into PATCH .../status or unused routes removed |
| ExamStaffProfileController | 1 | 1 |  |
| ExaminerAssignmentController | 5 | 3 | status actions merged into PATCH .../status or unused routes removed |
| ExaminerWorkController | 14 | 14 |  |
| HeartbeatController | 1 | 1 |  |
| HostAttendanceController | 5 | 0 | replaced by AttendanceController |
| HostDashboardController | 1 | 1 |  |
| HostExaminerIssueController | 1 | 1 |  |
| HostLocationController | 2 | 2 |  |
| HostOrganizationController | 3 | 0 | status actions merged into PATCH .../status or unused routes removed |
| HostScoreReviewController | 7 | 7 |  |
| HostSupportTicketController | 4 | 4 |  |
| InboxController | 5 | 5 |  |
| InternalMediaController | 1 | 0 | replaced by (no consumer; removed) |
| InternalSessionController | 2 | 0 | replaced by (no consumer; removed) |
| InternalSnapshotController | 2 | 0 | replaced by (no consumer; removed) |
| LecturerAssignmentController | 3 | 3 |  |
| LicenseCodeController | 3 | 2 | status actions merged into PATCH .../status or unused routes removed |
| LicenseCodeRedeemController | 1 | 1 |  |
| MediaController | 3 | 3 |  |
| MonitoringController | 2 | 2 |  |
| NotificationLogController | 1 | 1 |  |
| OrderController | 3 | 3 |  |
| OrganizationController | 4 | 9 |  |
| PayOsWebhookController | 1 | 1 |  |
| PlanController | 7 | 6 | status actions merged into PATCH .../status or unused routes removed |
| PlatformAuditLogController | 1 | 1 |  |
| PlatformCommercialController | 2 | 2 |  |
| PlatformSettingController | 4 | 2 | status actions merged into PATCH .../status or unused routes removed |
| PlatformUserController | 10 | 7 | status actions merged into PATCH .../status or unused routes removed |
| PlatformUserDirectoryController | 1 | 1 |  |
| ProctorAssignmentController | 4 | 4 |  |
| ProctorAssignmentQueryController | 2 | 2 |  |
| ProctorAttendanceController | 5 | 0 | replaced by AttendanceController |
| ProctorSessionController | 1 | 0 | replaced by (ProctorSession removed; monitoring ends with the ExamSession status) |
| ProgramController | 9 | 6 | status actions merged into PATCH .../status or unused routes removed |
| QuestionController | 15 | 8 | status actions merged into PATCH .../status or unused routes removed |
| QuestionTypeController | 6 | 6 |  |
| ReportController | 2 | 2 |  |
| ReportPublishController | 3 | 3 |  |
| RubricController | 12 | 0 | replaced by (removed with the rubric module by the partner, PR #82/#83) |
| ScoreTemplateController | 12 | 0 | replaced by ExamDefinitionController |
| ScoringCommandController | 1 | 1 |  |
| ScoringReviewController | 3 | 3 |  |
| SessionClassAssignmentController | 3 | 0 | status actions merged into PATCH .../status or unused routes removed |
| SessionClassController | 0 | 3 | new |
| SessionController | 22 | 19 | status actions merged into PATCH .../status or unused routes removed |
| SnapshotController | 1 | 1 |  |
| StaffWorkspaceController | 4 | 3 | status actions merged into PATCH .../status or unused routes removed |
| StudentEnrollmentController | 1 | 1 |  |
| StudentQuotaController | 2 | 2 |  |
| StudentRosterController | 1 | 1 |  |
| StudentRosterImportController | 1 | 1 |  |
| StudentSessionController | 1 | 1 |  |
| StudentWorkspaceController | 3 | 3 |  |
| SubscriptionController | 3 | 3 |  |
| TaskTypeController | 9 | 7 | status actions merged into PATCH .../status or unused routes removed |
| TenantApplicationController | 5 | 4 | status actions merged into PATCH .../status or unused routes removed |
| TenantController | 9 | 0 | replaced by OrganizationController |
| UserController | 13 | 12 | status actions merged into PATCH .../status or unused routes removed |
| ViolationAuditController | 2 | 2 |  |
