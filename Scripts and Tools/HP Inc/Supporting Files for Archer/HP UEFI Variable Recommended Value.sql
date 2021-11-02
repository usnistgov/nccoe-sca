IF ([UEFI Variable Name]="SS_SB_KeyProt", "Enable",
IF ([UEFI Variable Name]="FW_RIPD", "Enable",
IF ([UEFI Variable Name]="TL_Power_Off", "Enable",
IF ([UEFI Variable Name]="TL_Clear_TPM", "Depends on customer requirements",
IF ([UEFI Variable Name]="SS_GPT_HDD", "Enable",
IF ([UEFI Variable Name]="SS_GPT_Policy", "Recover in event of corruption",
IF ([UEFI Variable Name]="DMA_Protection", "Enabled",
IF ([UEFI Variable Name]="PreBoot_DMA", "Enabled",
IF ([UEFI Variable Name]="Cover_Sensor", "Administrator Credential or Administrator Password",
IF ([UEFI Variable Name]="", "No Recommended Values", "No Recommended Values")
 )))))))))