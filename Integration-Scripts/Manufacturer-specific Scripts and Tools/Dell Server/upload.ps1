#invoke via:
# "". .\upload.ps1; New-Archer-Upload '.\Test Data\Dell Server\systemInventory_GJFBVD3_2021_07_21_11_24_56.json' Dell"

function New-Archer-Upload {
    param (
        [parameter(Mandatory=$True,Position=1)] [ValidateScript({ Test-Path -PathType Leaf $_ })] [String] $FilePath,
        [parameter(Mandatory=$True,Position=2)] [String] $AssetType
    )
	
	# Get the system UUID 
  $uuid = (Get-WmiObject -Class Win32_ComputerSystemProduct).UUID
  
  
    # We have a REST-Endpoint
    # Uncomment for local testing
	#$url = "http://localhost:3001/api/upload"
  $url = "<collator-hostname>"
  $fileBin = [System.IO.File]::ReadAllBytes($FilePath)
	$enc = [System.Text.Encoding]::GetEncoding("utf-8")
	$fileEnc = $enc.GetString($fileBin)

  $data = @{
    jsonFile=$fileEnc
    type=$AssetType
    UUID=$uuid
  }
  $json = $data | ConvertTo-Json
	
  try {
      Invoke-RestMethod -Uri $url -Method Post -Body $json -ContentType "application/json"
  }
  catch [System.Net.WebException] {
      Write-Error( "REST-API-Call failed for '$URL': $_" )
      throw $_
  }
}
