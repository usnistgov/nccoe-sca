# nist_sca
NIST NCCoE Supply Chain Assurance project
(C)HP Inc. 

## Authors: 
- Joshua Schiffman <joshua.ser.schiffman@hp.com>
- Jeff Jeanssone <jeff.jeannsone@hp.com>


# HP Inc. Demonstration of for NIST Verification of Computer Integrity
Submit HP UEFI Variables and HP Firmware events to NCCoE Dashboard endpoint.

HP Inc. has created this script as an example tool for driving the collection, filtering, and reporting of critical configurations and events related to HP's security features that protect device integrity throughout the supply chain.  The `runHPSCA.ps1` PowerShell script leverages HP Inc.'s CMSL library to collect this data via runtime BIOS.  CMSL is currently available in Windows systems and is being ported to Linux.  Similar functionality can be achieved using existing BIOS interfaces without CMSL if desired, but requires additional code to use these intefaces.

# Installation

- Install HP's CMSL library found here: https://ftp.ext.hp.com/pub/caps-softpaq/cmit/hp-cmsl.html
- Unzip `HPSCA.zip` into the `C:\hpsca` directory.  If you choose a different path, change the Config location in `runHPSCA.ps1` and update `config.json` filepaths.
- You must run `C:\hpsca\runHPSCA.ps1` from an elevated command prompt.
## Troubleshooting
- If you get a Permission Error, you may need to change you execution policies.  The easiest option is to use `Set-ExecutionPolicy Unrestricted`. 
- You can also use `powershell.exe -executionpolicy -ByPass -File C:\hpsca\runHPSCA.ps1`.
- The script should work in cmd.exe, but you might have better luck using powershell or Terminal directly.

# Configuration

`runHPSCA` uses 3 config files during execution, which must be present.  Recommended defaults are provided.  These have been tested and validated against the provided schema.

- `config.json` - Defines filepaths for output and config files.  By default, this file is expected at *"C:\hpsca\config.json"*.  
- `variables.json` - UEFI Variables to be collected.  Variables have an alias key and a string representing the variable name in CMSL.
- `events.json` - Notable events to select from the HP Endpoint Security Controller (EpSC) firmware audit log.  Event keys are the concatenated hex values of the event's SID and EID.  Each event is given a **category** corrisponding to a security feature and an event **type**.  `runHPSCA` will only select events in this list then assign them the categorty and type.

# JSON Report Schema

The tool produces a report in JSON following the schema defined in sca_schema.json.  Test output has been validated against this schema, but it is not explicitly used in the tool.

# Parameters

- `-Baseline` - Creates a new Baseline report with no previous run time.  Baseline reports ignore all previous firmware events.  Baseline is implied if no previous run data is present. 

- `-Reset` - Deletes all previous reports.  Used to reset to new system intake state. Next run will be a Baseline

- `-Offline` - Run script in offline mode.  Script will not send results to dashboard.

- `-Verbose` - Enable Verbose logging to terminal.  Verbose data is logged to out.log regardless of this setting.

# EXAMPLE

    # Must run as admin

    # Reports HP BIOS and Firmware events with verbose logging
    C:\hpsca\runHPSCA.ps1 -Verbose
        
    # Deletes all previous runs.  Will run a baseline scan.
    C:\hp_sca\test -Reset

    # Reports new baseline but does not submit it to the dashboard
    C:\hp_sca\test -Baseline -Offline
