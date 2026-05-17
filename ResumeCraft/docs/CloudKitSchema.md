# CloudKit Schema Deployment

ResumeCraft can initialize the SwiftData CloudKit schema from `ResumeCraftApp.initializeCloudKitSchemaIfNeeded()` in `DEBUG` builds. The helper is guarded by a schema version string (`schemaVersion`) and a `UserDefaults` flag.

When SwiftData models change:

1. Bump `schemaVersion` in `ResumeCraftApp.swift`.
2. Run a Debug build against the development CloudKit environment once.
3. Verify the schema in CloudKit Console.
4. Deploy the development schema to production in CloudKit Console before shipping TestFlight or App Store builds.

Production builds do not push schema changes automatically.
