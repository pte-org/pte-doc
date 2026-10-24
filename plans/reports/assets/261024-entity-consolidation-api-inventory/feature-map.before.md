# Feature map before entity consolidation (2026-10-24)

328 endpoints, 3 STOMP handlers. One feature per controller; every row must still have an endpoint (old or new) after phase 11.

| Feature (controller) | Endpoints | Client repos with call sites |
|---|---|---|
| AdminDashboardController | 1 | pte-web |
| AdminLicenseCodeController | 7 | pte-api-scripts, pte-web |
| AdminSupportTicketController | 4 | pte-web |
| AnnouncementController | 8 | pte-web |
| AttemptController | 12 | pte-api-scripts, pte-app, pte-web |
| AuditLogController | 1 | pte-web |
| AuthController | 7 | pte-api-scripts, pte-app, pte-practice, pte-web |
| BlueprintController | 9 | pte-web |
| ClassController | 14 | pte-api-scripts, pte-web |
| ClassMembershipController | 1 | pte-api-scripts, pte-web |
| EnrollmentController | 4 | pte-api-readme, pte-api-scripts, pte-app, pte-practice, pte-web |
| ExamSessionIncidentController | 5 | pte-app, pte-web |
| ExamStaffProfileController | 1 | pte-api-readme, pte-api-scripts, pte-app, pte-web |
| ExaminerAssignmentController | 5 | pte-api-readme, pte-api-scripts, pte-app, pte-practice, pte-web |
| ExaminerWorkController | 14 | pte-web |
| HeartbeatController | 1 | pte-api-scripts, pte-app, pte-web |
| HostAttendanceController | 5 | pte-web |
| HostDashboardController | 1 | pte-web |
| HostExaminerIssueController | 1 | pte-web |
| HostLocationController | 2 | pte-web |
| HostOrganizationController | 3 | pte-api-scripts, pte-web |
| HostScoreReviewController | 7 | pte-web |
| HostSupportTicketController | 4 | pte-web |
| InboxController | 5 | pte-web |
| InternalMediaController | 1 | - |
| InternalSessionController | 2 | - |
| InternalSnapshotController | 2 | - |
| LecturerAssignmentController | 3 | pte-api-scripts, pte-web |
| LicenseCodeController | 3 | pte-api-scripts, pte-web |
| LicenseCodeRedeemController | 1 | pte-api-scripts, pte-web |
| MediaController | 3 | pte-app, pte-practice, pte-web |
| MonitoringController | 2 | pte-app, pte-web |
| NotificationLogController | 1 | pte-app, pte-web |
| OrderController | 3 | pte-app, pte-web |
| OrganizationController | 4 | pte-api-scripts, pte-web |
| PayOsWebhookController | 1 | - |
| PlanController | 7 | pte-api-readme, pte-api-scripts, pte-app, pte-practice, pte-web |
| PlatformAuditLogController | 1 | pte-web |
| PlatformCommercialController | 2 | pte-web |
| PlatformSettingController | 4 | pte-api-scripts, pte-app, pte-web |
| PlatformUserController | 10 | pte-api-scripts, pte-web |
| PlatformUserDirectoryController | 1 | pte-web |
| ProctorAssignmentController | 4 | pte-api-readme, pte-api-scripts, pte-app, pte-practice, pte-web |
| ProctorAssignmentQueryController | 2 | pte-web |
| ProctorAttendanceController | 5 | pte-app, pte-web |
| ProctorSessionController | 1 | pte-app, pte-web |
| ProgramController | 9 | pte-api-scripts, pte-web |
| QuestionController | 15 | pte-api-readme, pte-api-scripts, pte-app, pte-practice, pte-web |
| QuestionTypeController | 6 | pte-web |
| ReportController | 2 | pte-app, pte-web |
| ReportPublishController | 3 | pte-web |
| RubricController | 12 | pte-web |
| ScoreTemplateController | 12 | pte-api-scripts, pte-web |
| ScoringCommandController | 1 | pte-api-readme, pte-api-scripts, pte-app, pte-practice, pte-web |
| ScoringReviewController | 3 | pte-app, pte-practice, pte-web |
| SessionClassAssignmentController | 3 | pte-api-readme, pte-api-scripts, pte-app, pte-practice, pte-web |
| SessionController | 22 | pte-api-readme, pte-api-scripts, pte-app, pte-practice, pte-web |
| SnapshotController | 1 | pte-app, pte-web |
| StaffWorkspaceController | 4 | pte-web |
| StudentEnrollmentController | 1 | pte-api-scripts, pte-app, pte-web |
| StudentQuotaController | 2 | pte-web |
| StudentRosterController | 1 | pte-api-readme, pte-web |
| StudentRosterImportController | 1 | pte-web |
| StudentSessionController | 1 | pte-app |
| StudentWorkspaceController | 3 | pte-api-scripts, pte-app, pte-web |
| SubscriptionController | 3 | pte-api-scripts, pte-app, pte-web |
| TaskTypeController | 9 | pte-api-scripts, pte-app, pte-web |
| TenantApplicationController | 5 | pte-app, pte-web |
| TenantController | 9 | pte-api-scripts, pte-web |
| UserController | 13 | pte-api-readme, pte-api-scripts, pte-app, pte-web |
| ViolationAuditController | 2 | pte-app, pte-web |
