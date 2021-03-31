#TSCVerifyUtil Script

#Current user
$whoami = whoami
$user=$whoami.split("\")[1]

# Prerequisite - Add vcruntime_1.dll to computer
$file2 = "C:\\Windows\System32\vcruntime140_1.dll"
$dest2 = "C:\\Windows\System32"
if (-not(Test-Path -Path $file2 -PathType Leaf)) {
	try {
		Copy-Item -Path "\\10.151.48.225\Users\Public\Documents\vcruntime140_1.dll" -Destination $dest2 -Force -PassThru
		#Read-Host -Prompt "Press Enter to Exit"
	}
	catch {
		throw $_.Exception.Message
	}
}


# TSCVerify File
$file = "C:\\Program Files\Intel\TSCVerifyUtil\TSCVerifyTool.exe"

# Destination Path
$dest = "C:\\Program Files\Intel\TSCVerifyUtil"

#If TSCVerify Script is not on computer, add it
if (-not(Test-Path -Path $file -PathType Leaf)) {
	try {
		Copy-Item -Path "\\10.151.48.225\Users\Public\Documents\TSCVerifyTool.exe" -Destination $dest -Force -PassThru
	}
	catch {
		throw $_.Exception.Message
	}
}

# Location of the Intel artifacts. Stored on network share, with serial number used as identifier
# TODO: Find a method to pass the organizational UUID to this script for consistency
$serialnumber = Get-WmiObject Win32_Bios | Select-Object SerialNumber
$artifactdirectory = "\\10.151.48.225\Users\Public\Intel\" + $serialnumber.SerialNumber


# Direct Platform Data file signed from Intel - 5CG9255XRZ should validate successfully.
# This is brittle - assuming there's only one DPD file in the directory. Same for platform certificate.

$dpdfilearray = Get-ChildItem -Path $artifactdirectory -Name -Include *.xml
$dpdfile = $dpdfilearray[0]
#$dpdfile = "CLIENT_DEMO_43125_5CG9255XRZ_DPD_5CG9255XRZ_DPD_INTC_Platform_Data.xml"
#$dpdfile = "PF2B4BC7-2021-03-26-NegativeTestCase\LENOVO_12056_PF2B4BC7_DPD_PF2B4BC7_DPD_INTC_Platform_Data.xml"

# Platform Certificate associated with this computing device - 5CG9255XRZ should validate successfully
$platformcertificatefilearray = Get-ChildItem -Path $artifactdirectory -Name -Include *.cer
$platformcertificatefile = $platformcertificatefilearray[0]
# $platformcertificatefile = "CLIENT_DEMO_43124_5CG9255XRZ_PAC_5CG9255XRZ_PCD_INTC_Platform_Cert_RSA.cer"
# $platformcertificatefile = "PF2B4BC7-2021-03-26-Negative Test Case\LENOVO_12057_PF2B4BC7_PAC_PF2B4BC7_PCD_INTC_Platform_Cert_RSA.cer"

# Run Scan and capture exit code. 0=No components have changed, 1=At least one component has changed, 3=Platform Certificate
# validation failed
# https://stackoverflow.com/questions/10262231/obtaining-exitcode-using-start-process-and-waitforexit-instead-of-wait
Write-Output "Starting DPD file scan and compare..."
$tscpinfo = New-Object System.Diagnostics.ProcessStartInfo
$tscpinfo.FileName = "TSCVerifyTool.exe"
$tscpinfo.WorkingDirectory = $artifactdirectory
$tscpinfo.RedirectStandardError = $true
$tscpinfo.RedirectStandardOutput = $true
$tscpinfo.UseShellExecute = $false
$tscpinfo.Arguments = "SCANREADCOMP -in $dpdfile"
$dpdprocess = New-Object System.Diagnostics.Process
$dpdprocess.StartInfo = $tscpinfo
$dpdprocess.Start() | Out-Null
$stdout = $dpdprocess.StandardOutput.ReadToEnd()
$dpdprocess.WaitForExit()
if ($dpdprocess.ExitCode) {
	Write-Output "At least one component has changed"
	return 1
}
else {
	Write-Output "No components have changed"
}

Write-Output "Starting Platform Certificate validation ..."
$tscpinfo.Arguments = "PFORMCRTCOMP -in $platformcertificatefile"
$platformcertprocess = New-Object System.Diagnostics.Process
$platformcertprocess.StartInfo = $tscpinfo
$platformcertprocess.Start() | Out-Null
$stdout = $platformcertprocess.StandardOutput.ReadToEnd()
$platformcertprocess.WaitForExit()
if ($platformcertprocess.ExitCode) {
	Write-Output "Platform Certificate did not validate"
	return 3
}
else {
	Write-Output "Platform Certificate validated"
}

return 0


#Read-Host -Prompt "Press Enter to Exit"