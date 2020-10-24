# DQExtensions
DispatchQueue Extensions: The Missing Parts

This library adds several useful extensions and conveniences for managing `DispatchQueue` types in Grand Central Dispatch.

Apple provides powerful functionality to boot, but there's some things that this library helps solve:
- Unified mechanism to create named dispatch queues
- Ability to identify the currently running queue
- Ability to check if running on the main queue or any specific queue
- Safer `sync` calls that execute inline if same queue detected
- Simplified API for common operations

## Swift Package Manager

The project supports SPM and can be added to projects targeting Swift 5.3 and higher.
