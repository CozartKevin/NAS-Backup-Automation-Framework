### Architecture Overview

This document describes the architecture of the NAS Backup Automation Framework, including the major framework components, execution flow, library structure, and workflow extension model.

The framework was designed to standardize backup automation tasks executed through Synology Task Scheduler while minimizing code duplication and promoting reusable operational components.


## Architectural Components

The framework is composed of three primary component types:

- Driver Scripts
- Backup Libraries
- Core Libraries

NOTE:  Each sections scripts are responsible for the logging pertaining to the script actions only.  If there are locking errors, the script that threw that error is in the CORE libraries lock.sh file. 


## Workflow Lifecycle

1. Synology Task Scheduler launches a driver script.
2. Workflow configuration is loaded.
3. The framework bootstrap process is started.
4. Core libraries are initialized.
5. Logging and runtime tracking are established.
6. Workflow-specific backup libraries are loaded.
7. Environment and path validation is performed.
8. An execution lock is acquired.
9. Backup operations are executed.
10. Summary and runtime metrics are recorded.
11. The execution lock is released.


# Driver Scripts: 

The `Driver` scripts contain the environmental data, SRC, DST, Expected Count and other job specific variables that will be reflected in job actions and logging for a given backup sequence. 

## Reference Driver Examples

The `examples/` directory contains annotated reference driver scripts for common workflow types:

- Copy workflow
- Move workflow
- Trim workflow

These examples are not complete production configurations. They demonstrate how driver scripts define workflow-specific settings and call the shared framework libraries.


# Backup Libraries:

The `Backup` libraries contain the execution methodologies for various backup related tasks.  These include: Copy, Move, Trim, Stamp and dated folder manipulation

    stamp_backups.sh - responsible for renaming non-dated folders to the standardized YYYYMMDD_FolderName format expected by all other scripts.
    copy_backups.sh - responsible for copying src folders to dst location based on a mode selected.  The mode is newest, oldest or non-dated backup folders
    move_backups.sh - responsible for moving oldest src folders to dst location and removing src folder post move confirmation.  
    trim_backups.sh - responsible for finding x# of newest dates from folders then removing all folders not within those found dates.  


# Core Libraries:

The `Core` libraries contain the universal helper functions that the Driver scripts and Backup libraries rely on.  These include: Bootstrapper, Execution, file_ops, lock, logging, preflight and timer. 

    bootstrap.sh - responsible for initializing the config file root directory path for the library, verifies Identities are set in the driver script, then loads all CORE library files.  Sets up logging, verifies execution mode, and starts script timer. 
    logging.sh - responsible for log syntax verification throughout all scripts, sets error trapping and end of script completion message and logging. 
    lock.sh - responsible for lock management.  checks, acquires, releases and runs with_locks the jobs and logging. 
    timer.sh - responsible for timer management.  Starts timer, stops timer, formats duration and gets elapsed duration based on start time and logging. 
    preflight.sh - responsible for SRC, DST, and drive space checks and validation and logging. 
    file_ops.sh - responsible for file operations like, Copy, Move, Delete, Verify directory match and removal of empty directories.  
    execution.sh - responsible for executing file operation wrappers while enforcing DRY_RUN/LIVE behavior and standardized result logging.


# config.sh

The `config.sh` file in the lib root folder is responsible for getting the current directory path and setting each CORE and Backup folders exported location.  Used within the bootstrapper during initialization. 


## Adding New Workflows

New workflows are typically implemented by creating a new driver script that defines the workflow-specific configuration, source and destination paths, retention settings, execution mode, and script identity.

Driver scripts should remain lightweight and focus on workflow configuration rather than operational implementation.

When creating a new workflow:

1. Create a new driver script.
2. Define the workflow-specific environment variables and configuration.
3. Load the framework bootstrap process.
4. Load the backup libraries required for the workflow.
5. Execute the desired backup operations.

Whenever possible, new workflows should reuse existing backup library functions.

If the required functionality does not exist within the backup libraries, a new backup library may be created using the services provided by the core framework libraries.

If additional framework-level functionality is required, a new core library may be added. New core libraries should provide reusable functionality that could reasonably be shared across multiple workflows. Core libraries must also be loaded by the bootstrap process to ensure they are available to all driver scripts.


## Design Principles

The framework was designed around several principles:

- Driver scripts should remain small and configuration-focused.
- Common functionality should exist in shared libraries.
- Backup operations should be reusable across workflows.
- Logging should be standardized across all execution paths.
- Workflows should support both DRY_RUN and LIVE execution modes.
- New workflows should require minimal code duplication.

