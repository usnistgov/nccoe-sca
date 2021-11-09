<#
.SYNOPSIS
    Submit HP UEFI Variables and HP Firmware events to NIST endpoint

.DESCRIPTION
    HP Inc. Demonstration of for NIST Verification of Computer Integrity

.PARAMETER Baseline
    Creates a new Baseline report with no previous run time.  Baseline 
    reports ignore all previous firmware events.  Baseline is implied if
    no previous run data is present.

.PARAMETER Reset
    Deletes all previous reports.  Used to reset to new system intake state.
    Next run will be a Baseline

.PARAMETER Offline
    Run script in offline mode.  Script will not send results to dashboard.

.PARAMETER Verbose
    Enable Verbose logging to terminal.  Verbose data is logged to out.log
    regardless of this setting.

.EXAMPLE
    C:\hp_sca\test
        Reports HP BIOS and Firmware events.  
    
    C:\hp_sca\test -Reset
        Deletes all previous runs 
    
    C:\hp_sca\test -Baseline
        Reports new baseline
.NOTES
    (C)HP Inc. 
    Authors: Joshua Schiffman <joshua.ser.schiffman@hp.com>
             Jeff Jeanssone <jeff.jeannsone@hp.com>
#>

param(
    [Parameter()][Switch]$Baseline, # Run script as a Baseline report collection
    [Parameter()][Switch]$Reset, # Delete previous event data
    [Parameter()][Switch]$Offline   # Don't send data to dashboard
)

# Configuration options

#Requires -RunAsAdministrator #CMSL calls must be run as administrator

[string]$configFile = "C:\hpsca\config.json"
$Config = Get-Content -Path $configFile | ConvertFrom-Json

function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "ERROR")]
        [string]$Level = "INFO",

        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    $Stamp = (Get-Date).ToString("yyyy/MM/dd HH:mm:ss")
    $Line = "$Stamp [$Level] $Message"
    
    Add-Content -Path $script:Config.logfile -Value $Line
    
    Switch ($Level) {
        "ERROR" { Write-Host $Line } 
        "INFO" { Write-Verbose $Line }
    }
}


# Class for obtaining information from the BIOS via CMSL.
class Bios {

    hidden [System.Collections.Hashtable]GetNotableVariables() {
        $notableVariables = @{}

        Write-Log INFO $script:Config.varConfigFile

        if (Test-Path -Path $script:Config.varConfigFile) {
            (Get-Content $script:Config.varConfigFile | ConvertFrom-Json).psobject.properties | ForEach-Object { 
                $notableVariables[$_.Name] = $_.Value 
            }      
        }
        else {
            Write-Log ERROR "No file $script:Config.varConfigFile found.  Skipping variables."
        }
        return $notableVariables
    }
    
    [void]GetVariables([System.Collections.Hashtable] $report) {  
        
        # UEFI Variables of interest
        $notableVariables = $this.GetNotableVariables()
   
        # https://developers.hp.com/hp-client-management/doc/get%E2%80%90hpbiossettingvalue
        # Get-HPBIOSSettingsList and filtering is faster than Get-HPBIOSSettingValue for each variable.
        $allBiosSettings = Get-HPBIOSSettingsList -format csv | ConvertFrom-Csv

        foreach ($key in $notableVariables.keys) {
            $item = $allBiosSettings | Where-Object { $_.Name -eq $notableVariables[$key] }
            if ($item) {
                # Select active value with '*', then strip * from value
                $value = ($item.CURRENT_VALUE.Split(',') | Where-Object { $_.Contains("*") }) -replace '[*]', ''
            }
            else {
                Write-Log ERROR "'$notableVariables[$key]' not found."
                $value = "Not found"
            }

            $report.data.Variables[$key] = @{
                Name  = $notableVariables[$key];
                Value = $value
            }
        }
    }
}

# Class for obtaining information from the firmware via CMSL.
class Firmware {

    hidden [System.Collections.Hashtable]GetNotableEvents() {
        $notableEvents = @{}
        (Get-Content $script:Config.eventConfigFile | ConvertFrom-Json).psobject.properties | ForEach-Object { $notableEvents[$_.Name] = $_.Value }      
        return $notableEvents
    }

    hidden [void]AddEventToHashtable(
        [Object] $Type,
        [System.Object] $fwEvent, 
        [System.Collections.Hashtable] $report) {

        # Add event to category under value index
        $value = @{
            Message   = $fwEvent.message_number;
            Timestamp = $fwEvent.timestamp.ToString()
        }
        $report.data.Events[$Type.Category][$Type.Value] += @($value)

        # update Last_Timestamp
        if ($fwEvent.timestamp -gt $report.data.Events.Last_Timestamp) {
            $report.data.Events.Last_Timestamp = $fwEvent.timestamp.ToString()
            $msg = "Updated Last_Timestamp to " + $fwEvent.timestamp
            Write-Log INFO $msg
        }
    }
    
    hidden [void]EvaluateEvents([System.Object[]]$fwEvents, 
        [System.Collections.Hashtable] $notableEvents, 
        [System.Collections.Hashtable] $report) {

        foreach ($fwEvent in $fwEvents) {
            # SID_EID is bytes 8 + 9 of raw event data 
            $sid_eid = "0x" + $fwEvent.'raw event data'.Substring(24, 5) -replace '[:]', ''

            if (!$sid_eid) {
                Write-Log ERROR "Raw event data corrupt in FW event log."
            }
            $msg = "<Event:{0}> {1} - {2}" -f $sid_eid, $fwEvent.timestamp.ToString(), $fwEvent.description
            Write-Log INFO $msg
            
            $eventType = $notableEvents[$sid_eid]                        
            if ($eventType) {                        
                $msg = "Category: {0}' - Type: {1}" -f $eventType.Category, $eventType.Value
                Write-Log INFO $msg
               
                if ($fwEvent.timestamp -gt $report.data.Events.Prev_Timestamp) {
                    Write-Log INFO "Adding new event."
                    $this.AddEventToHashtable($eventType, $fwEvent, $report)
                }
                else {
                    $msg = "Ignoring event before " + $report.data.Events.Prev_Timestamp
                    Write-Log INFO $msg
                }
            }
            else {
                $msg = "Event {0} is not in event config list." -f $sid_eid
                Write-Log INFO $msg
            }
        }
    }

    # Uses https://developers.hp.com/hp-client-management/doc/get%E2%80%90hpfirmwareauditlog to obtain event log information.
    [void]GetEvents([System.Collections.Hashtable] $report) {
        $fw_events = Get-HPFirmwareAuditLog         # Get the firmware events
        $notableEvents = $this.GetNotableEvents()   # Get events to filter
        $this.EvaluateEvents($fw_events, $notableEvents, $report)
    }
}

# Class for posting REST JSON data to a server.
class RestServer {

    [void]SubmitDashboardTableToServer(
        [System.Collections.Hashtable] $report) { 

        $type = "HPINC"
        $uuid = "12212" # Dummy value for NCCoE Collator

            # Send data to server. 
        $reportAsJson = ($report | ConvertTo-Json -Depth 8)
        $uri = $script:Config.ServerAddress

        $msg = "Submitting report to $uri"
        Write-Log INFO $msg

        $data = @{
            jsonFile=$reportAsJson
            type=$type
            UUID=$uuid
        }        
        $json = $data | ConvertTo-Json
        $serverResponse = Invoke-RestMethod -Uri $uri -Method Post -Body $json -ContentType "application/json"
        
        Write-Log INFO $serverResponse
                
        if ($serverResponse.success -eq $true) {
            Write-Log INFO "The server determined the JSON was valid" 
        }
        else {
            Write-Log ERROR "The server determined the JSON was invalid" 
        }   
    }
}

# General purpose static functions 
class Utility {

    # Load last event from previous report
    static [DateTime]ImportLastEvent() {

        if (Test-Path -Path $script:Config.LastEventFile ) {
            return [DateTime](Get-Content $script:Config.LastEventFile | ConvertFrom-Json)
        }
        return New-Object System.DateTime
    }

    # Create events directory
    static [bool]CreateEventsDirectory() {

        if ((Test-Path -Path $script:Config.EventDir) -eq $false) {
            New-Item -Path $script:Config.EventDir -ItemType Directory
        }
        if ((Test-Path -Path $script:Config.EventDir)) {
            return $true
        }
        else {
            return $false
        }
    }

    static [void]SaveReport(
        [System.Collections.Hashtable] $report) {
        
        $timestamp = Get-Date -Format "MMddyyyy_HHmmss"
        $eventLogPath = "{0}\{1}.json" -f $script:Config.EventDir, $timestamp

        $msg = "Saving Last Timestamp: " + $report.data.Events.Last_Timestamp
        Write-Log INFO $msg
        $report.data.Events.Last_Timestamp.ToString() | ConvertTo-Json > $script:Config.LastEventFile

        $msg = "Saving report to: {0}" -f $eventLogPath
        Write-Log INFO $msg
        $report | ConvertTo-Json -Depth 8 -Compress > $eventLogPath 
    }

    # Delete Events directory and previous timestamps
    static [void]Reset() {
        if (Test-Path -Path $script:Config.EventDir) {
            Remove-Item -Path $script:Config.EventDir -Recurse
        }
        if (Test-Path -Path $script:Config.logfile) {
            Remove-Item -Path $script:Config.logfile 
        }

    }
}

class DashboardReport {
    $report = @{
        type = "HPINC";
        uuid = Get-HPBIOSUUID;
        data = @{
            Variables = @{};
            Events    = @{
                HP_Sure_Start   = @{};
                HP_Sure_Recover = @{};
                HP_SPM          = @{};
                HP_DMA          = @{};
                HP_Tamper_Lock  = @{};
                HP_RID          = @{};
                HP_Sure_Admin   = @{};
                Sys_Config      = @{};
                Last_Timestamp  = "";
                Prev_Timestamp  = ""
            }    
        }
    }
}

# Drives data collection
class Collector {

    [void]StartProcessing(
        [DateTime] $prevTime) {

        # New report JSON template
        $report = [DashboardReport]::new().report
        $report.data.Events.Prev_Timestamp = $prevTime.ToString()

        if ($script:Baseline) {
            $report.data.Events.Last_Timestamp = (Get-Date).ToString()
        }
        else {
            $report.data.Events.Last_Timestamp = $prevTime.ToString()
        }
    
        [Bios]::new().GetVariables($report)
        [Firmware]::new().GetEvents($report)
        [Utility]::SaveReport($report)

        if (!$script:Offline) {
            [RestServer]::new().SubmitDashboardTableToServer($report)
        }
        
        
    }

    [bool]StartCollection() {
        try {            
            $prevTime = New-Object System.DateTime

            # Create events directory if not already there
            if ([Utility]::CreateEventsDirectory() -eq $false) {
                Write-Log INFO "Failed to create .\Events directory"
                return $false
            }
            
            if ($script:Baseline -eq $false) {
                # Load last event from previous report
                $prevTime = [Utility]::ImportLastEvent()
                if ($prevTime -eq 0) {
                    Write-Log INFO "No Baseline found. Performing Baseline run."
                    $script:Baseline = $true
                }
            }

            $this.StartProcessing($prevTime)
            return $true
        }
        catch [System.Exception] { 
            $err = "HPSCA caught an unexpected exception at line " + $_.InvocationInfo.ScriptLineNumber + " in script / module name " + $_.InvocationInfo.ScriptName
            Write-Log ERROR $err
            Write-Log ERROR $_.Exception.Message
            return $false
        } 
    }
}

# Start main execution below
if ($script:Reset) {
    Write-Log INFO "Reset requested: Deleting previous event logs." 
    [Utility]::Reset()
}

Write-Log INFO "===== Starting execution =====" 

$collector = [Collector]::new()

if ($collector.StartCollection()) { 
    Write-Log INFO "Data collection success" 
}
else {
    Write-Log ERROR "Data collection failure" 
}