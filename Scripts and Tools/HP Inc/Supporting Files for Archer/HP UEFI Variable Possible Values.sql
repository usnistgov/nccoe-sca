IF ([UEFI Variable Name]="SS_SB_KeyProt", "[Disable, Enable]",
IF ([UEFI Variable Name]="FW_RIPD", "[Disable, Enable]",
IF ([UEFI Variable Name]="TL_Power_Off", "[Disable, Enable]",
IF ([UEFI Variable Name]="TL_Clear_TPM", "[Disable, Enable]",
IF ([UEFI Variable Name]="SS_GPT_HDD", "[Disable, Enable]",
IF ([UEFI Variable Name]="SS_GPT_Policy", "[Local user control, Recover in event of corruption]",
IF ([UEFI Variable Name]="DMA_Protection", "[Disabled, Enabled]",
IF ([UEFI Variable Name]="PreBoot_DMA", "[Thunderbolt Only, All PCI-e Devices]",
IF ([UEFI Variable Name]="Cover_Sensor", "[Disable, Notify user, Administrator Credential, Administrator Password]",
IF ([UEFI Variable Name]="", "No Possible Values", "No Possible Values")
 )))))))))