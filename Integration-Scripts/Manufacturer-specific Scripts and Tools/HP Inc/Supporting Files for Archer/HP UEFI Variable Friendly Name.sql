IF ([UEFI Variable Name]="SS_SB_KeyProt", "Sure Start Secure Boot Keys Protection",
IF ([UEFI Variable Name]="FW_RIPD", "Enhanced HP Firmware Runtime Intrusion Prevention and Detection",
IF ([UEFI Variable Name]="TL_Power_Off", "Power Off Upon Cover Removal",
IF ([UEFI Variable Name]="TL_Clear_TPM", "Clear TPM on boot after cover removal",
IF ([UEFI Variable Name]="SS_GPT_HDD", "Save/Restore GPT of System Hard Drive",
IF ([UEFI Variable Name]="SS_GPT_Policy", "Boot Sector (MBR/GPT) Recovery Policy",
IF ([UEFI Variable Name]="DMA_Protection", "DMA Protection",
IF ([UEFI Variable Name]="PreBoot_DMA", "Pre-boot DMA protection",
IF ([UEFI Variable Name]="Cover_Sensor", "Cover Removal Sensor",
IF ([UEFI Variable Name]="", "No Friendly Name", "No Friendly Name")
 )))))))))