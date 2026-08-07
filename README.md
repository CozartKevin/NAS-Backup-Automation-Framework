# NAS Backup Automation Framework

## Overview

This project is a refactor of a collection of Bash scripts used to manage backups across a multi-tier Synology NAS environment.

The original scripts were created to solve an immediate operational requirement: get the backup process working reliably. The focus at the time was making sure backups completed successfully, not building a reusable framework.

The framework itself does not create backups. Instead, it manages the lifecycle of existing backup data through standardized stamping, copying, movement, retention, validation, and logging workflows.

As new backup requirements appeared, the quickest solution was often to copy an existing workflow, modify it for the new task, and move on. The scripts successfully handled backup stamping, copy operations, archive movement, retention cleanup, and other operational tasks, but over time this approach resulted in duplicated functionality across multiple scripts.

The backups generally worked. The larger issue was the amount of time required to verify that they worked.

Reviewing backup jobs meant opening and checking numerous log files across multiple workflows every week. Troubleshooting required understanding how each individual script handled validation, logging, locking, and execution. As additional workflows were added, the operational overhead required to verify successful execution continued to grow.

This refactor was not intended to redesign the backup process itself. The goal was to standardize the framework supporting those workflows.

Common functionality such as logging, lock management, validation, runtime tracking, and execution handling was moved into shared libraries. Backup-specific operations were separated into reusable modules, allowing driver scripts to focus on workflow configuration while shared libraries handled logging, validation, locking, runtime tracking, and file operations.

The primary motivation behind the project was simple: reduce the amount of effort required to maintain, troubleshoot, and verify backup operations while establishing a foundation for future reporting and log aggregation.

The end result is a more maintainable automation framework that:

* Reduces duplicated code
* Standardizes execution behavior
* Produces consistent structured logs
* Simplifies troubleshooting
* Supports DRY_RUN validation
* Provides a foundation for future reporting and log aggregation

---

## Related Projects

The NAS Backup Automation Framework implements a standardized structured logging format designed to support reusable reporting and monitoring.

- **[Structured Log Report Generator](https://github.com/CozartKevin/Structured-Log-Report-Generator)** – Consumes the framework's structured logs and generates interactive HTML dashboards along with CSV and JSON reports for operational review.

---

## Framework Features

* Shared CORE and Backup library architecture
* Structured logging across all workflows
* DRY_RUN and LIVE execution modes
* Execution locking to prevent overlapping jobs
* Standardized workflow lifecycle
* Reusable backup operations
* Runtime tracking and execution summaries
* Retention management and cleanup workflows

---

## Repository Structure

```text
NAS-Backup-Automation-Framework/
├── lib/
│   ├── core/           # Framework services
│   └── backup/         # Backup operation libraries
│
├── examples/           # Reference driver scripts
│
├── docs/               # Additional documentation
│
└── sample-output/      # Sanitized example logs
```

## Using the Framework

This repository is organized around a shared library architecture.

The reusable framework lives under the lib/ directory, while the examples/ directory contains sanitized reference driver scripts demonstrating how the framework is intended to be used.

The driver scripts are examples, not the framework itself.

Each driver script performs only workflow-specific configuration, such as:

* Defining source and destination paths
* Setting script identity
* Configuring retention values
* Selecting the execution mode (DRY_RUN or LIVE)
* Calling the appropriate shared library functions

Operational behavior—including logging, validation, locking, runtime tracking, retry handling, and file operations—is provided by the shared framework libraries.
This separation allows multiple backup workflows to share the same implementation while keeping individual driver scripts concise and easy to maintain.
The included driver scripts are sanitized production-derived examples intended to demonstrate the framework architecture rather than provide a complete, deployable backup solution.



### Core Libraries

The `core` library contains reusable framework components shared across all workflows.

Responsibilities include:

* Bootstrap and initialization
* Structured logging
* Lock management
* Runtime tracking
* File operations
* Preflight validation
* Execution helpers

### Backup Libraries

The `backup` library contains reusable backup operations built on top of the core framework.

Responsibilities include:

* Backup discovery
* Backup stamping and date normalization
* Copy operations
* Move operations
* Retention cleanup (trim)
* Backup date processing

### Reference Driver Scripts

Reference driver scripts demonstrate how the framework is configured for individual backup workflows.

Typical driver responsibilities include:

* Source and destination paths
* Script identity
* Execution mode selection
* Retention settings
* Workflow sequencing

Driver scripts intentionally remain small and rely on shared framework components for operational functionality.

---

## Execution Model

Workflows are launched through Synology Task Scheduler and follow a standardized execution pattern:

1. Driver script is launched.
2. Workflow configuration is loaded.
3. Framework bootstrap process begins.
4. Core libraries are initialized.
5. Logging and runtime tracking are established.
6. Backup libraries are loaded.
7. Preflight validation is performed.
8. Execution lock is acquired.
9. Workflow operations are executed.
10. Runtime and summary information are logged.
11. Lock is released.

---

## Execution Modes

### DRY_RUN

DRY_RUN executes the workflow without modifying the environment.

Actions that would have been performed are logged but not executed, allowing workflow validation before production use.

### LIVE

LIVE mode performs the configured operations and records execution details through the structured logging system.

---

## Documentation

Additional documentation is available in:

* `docs/architecture.md`
* `docs/logging-format.md`

---

## Sample Output

Sanitized example logs are available in:

* `sample-output/copy_weekly_backups_example.log`
* `sample-output/move_weekly_VMs_example.log`
* `sample-output/trim_monthly_backups_example.log`

---

## Sanitization Notes

This repository contains a sanitized version of a production backup automation environment.

Client names, server names, storage paths, schedules, and environment-specific details have been removed or generalized. The included examples are intended to demonstrate framework architecture, workflow design, and logging behavior without exposing operational information.

---

## Limitations

* Developed and tested within a Synology NAS environment.
* Example workflows are simplified and sanitized.
* Environment-specific scheduling and monitoring integrations are not included.
* No standalone automated testing framework currently exists.

---

## Future Improvements

Potential future enhancements include:

* Centralized log aggregation
* Automated workflow reporting
* Externalized configuration management
* Additional validation and monitoring capabilities
* Expanded automated testing support

---

## License

MIT License
