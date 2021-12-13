# This script runs the scv command. If successful, uploads to the collator system.
# These are the error codes returned from scv
# 0 - All operations are successful and inventory matched
# 1 - Generic failure
# 2 - Another instance of SCV is run
# 3 – Permission is not appropriate for the user
# 4 – Dependencies are not met to run SCV
# 5 – Certificate download failed from iDRAC
# 6 – Validating signature and Root of Trust Failed
# 7 – Validating proof of possession failed 
# 8 - Profile not supported for the version details mentioned in certificate.
# 9 - Profile, Subschema / utilities are tampered, profile signature mismatch
# 10 - Unable to collect data due to utility failure
# 11 - Mismatch in the inventory

# dot source the upload function

. X:\NCCoE\upload.ps1

# run scv

$FilePath = "scv.exe"
$Arguments = "ValidateSystemInventory"

$Info = New-Object System.Diagnostics.ProcessStartInfo
$Process = New-Object System.Diagnostics.Process

$Info.FileName = $FilePath
$Info.RedirectStandardError = $true
$Info.RedirectStandardOutput = $true
$Info.UseShellExecute = $false
$Info.Arguments = $Arguments

$Process.StartInfo = $Info
$Process.Start() | Out-Null
[string]$stdOut = $Process.StandardOutput.ReadToEnd()
[string]$stdErr = $Process.StandardError.ReadToEnd()
#$Process.WaitForExit(10000)    # Wait maximum of 10 seconds

If ($process.ExitCode -eq 0) { 

    $stdOut.Split("`n")
    # system inventory is created at
    # scvapp\out\systemInventory_<servicetag>_d<date>.json
    $manifest = Get-ChildItem -Path scvapp\out\systemInventory*.json 
    New-Archer-Upload -FilePath $manifest[0] -AssetType Dell

}    # Standard Output
Else {
    If ($stdErr.Length -gt 0) { 
        Return ($stdErr.Split("`n")) 
    }    # Standard Error  (if it exists)
    Else { 
        Return ($stdOut.Split("`n")) 
    }    # Standard Output (if there are no errors)
}
   


