             PGM
             DCL        VAR(&TAPDEV) TYPE(*CHAR) LEN(10)
             DCL        VAR(&TAPVOL) TYPE(*CHAR) LEN(6)
             DCL        VAR(&SYSNM) TYPE(*CHAR) LEN(8)

             RTVNETA    SYSNAME(&SYSNM)

             IF         COND(&SYSNM *EQ 'AS101N') THEN(DO)
             CHGVAR     VAR(&TAPDEV) VALUE('AS101_MY')
             CHGVAR     VAR(&TAPVOL) VALUE('101Y25')
             DSPTAP     DEV(&TAPDEV) VOL(&TAPVOL) OUTPUT(*PRINT)
             RSTLIB     SAVLIB(SGKGIF SGKGIF029 SGKGIF000 SGKGIH +
                          SGKGIS SGKGIS029 SGKGO SGKGIO029 WRKGIF +
                          SGRQS) DEV(&TAPDEV) VOL(&TAPVOL) +
                          OPTION(*NEW) MBROPT(*ALL) ALWOBJDIF(*ALL) +
                          OUTPUT(*PRINT)
             RSTLIB     SAVLIB(CCI) DEV(&TAPDEV) VOL(&TAPVOL) +
                          OPTION(*NEW) MBROPT(*ALL) ALWOBJDIF(*ALL) +
                          RSTLIB(CCIAS101) OUTPUT(*PRINT)
             RSTLIB     SAVLIB(*ALLUSR) DEV(&TAPDEV) VOL(&TAPVOL) +
                          OMITLIB(#* Q* SYSIBM SYSIBMADM SYSPROC +
                          SYSTOOLS DDSCINFO HOYA* LAKEVIEW* PMEDH* +
                          RMT* SGKGISN KCOFCMTF KCOFCMTT KCOFITN +
                          KCOFPRC KCOFUSR KCOFSCRT KSOFFINF +
                          KSOFFIXF KSOFFINA KSOFFINFVR KSUSER +
                          FU1000427 FUCOMM SMTPSPL S007389 GZIP +
                          $INFRA CCI MONLIB OCEANTOOLS SMSLIB) +
                          OPTION(*NEW) MBROPT(*ALL) ALWOBJDIF(*ALL) +
                          OUTPUT(*PRINT)
             RSTLIB     SAVLIB($INFRA) DEV(&TAPDEV) VOL(&TAPVOL) +
                          OPTION(*NEW) MBROPT(*ALL) ALWOBJDIF(*ALL) +
                          RSTLIB($INFRAS101) OUTPUT(*PRINT)
             RSTLIB     SAVLIB(MONLIB) DEV(&TAPDEV) VOL(&TAPVOL) +
                          OPTION(*NEW) MBROPT(*ALL) ALWOBJDIF(*ALL) +
                          RSTLIB(MONLIBS101) OUTPUT(*PRINT)
             RSTLIB     SAVLIB(OCEANTOOLS) DEV(&TAPDEV) VOL(&TAPVOL) +
                          OPTION(*NEW) MBROPT(*ALL) ALWOBJDIF(*ALL) +
                          RSTLIB(OCEANTO101) OUTPUT(*PRINT)
             RSTLIB     SAVLIB(SMSLIB) DEV(&TAPDEV) VOL(&TAPVOL) +
                          OPTION(*NEW) MBROPT(*ALL) ALWOBJDIF(*ALL) +
                          RSTLIB(SMSLIBS101) OUTPUT(*PRINT)
             ENDDO
             ELSE       CMD(IF COND(&SYSNM *EQ 'KSF03N') THEN(DO)) +
             CHGVAR     VAR(&TAPDEV) VALUE('KSF03_MY')
             CHGVAR     VAR(&TAPVOL) VALUE('F03Y25')
             DSPTAP     DEV(&TAPDEV) VOL(&TAPVOL) OUTPUT(*PRINT)
             RSTLIB     SAVLIB(SGKGIF SGKGIF029 SGKGIF000 SGKGIH +
                          SGKGIS SGKGIS029 SGKGO SGKGIO029 WRKGIF +
                          SGRQS) DEV(&TAPDEV) VOL(&TAPVOL) +
                          OPTION(*NEW) MBROPT(*ALL) ALWOBJDIF(*ALL) +
                          OUTPUT(*PRINT)
             RSTLIB     SAVLIB(CCI) DEV(&TAPDEV) VOL(&TAPVOL) +
                          OPTION(*NEW) MBROPT(*ALL) ALWOBJDIF(*ALL) +
                          RSTLIB(CCIKSF03) OUTPUT(*PRINT)
             RSTLIB     SAVLIB(*ALLUSR) DEV(&TAPDEV) VOL(&TAPVOL) +
                          OMITLIB(#* Q* SYSIBM SYSIBMADM SYSPROC +
                          SYSTOOLS DDSCINFO HOYA* LAKEVIEW* PMEDH* +
                          RMT* SGKGISN KCOFCMTF KCOFCMTT KCOFITN +
                          KCOFPRC KCOFUSR KCOFSCRT KSOFFINF +
                          KSOFFIXF KSOFFINA KSOFFINFVR KSUSER +
                          FU1000427 FUCOMM SMTPSPL S007389 GZIP +
                          $INFRA CCI MONLIB OCEANTOOLS SMSLIB) +
                          OPTION(*NEW) MBROPT(*ALL) ALWOBJDIF(*ALL) +
                          OUTPUT(*PRINT)
             RSTLIB     SAVLIB($INFRA) DEV(&TAPDEV) VOL(&TAPVOL) +
                          OPTION(*NEW) MBROPT(*ALL) ALWOBJDIF(*ALL) +
                          RSTLIB($INFRASF03) OUTPUT(*PRINT)
             RSTLIB     SAVLIB(MONLIB) DEV(&TAPDEV) VOL(&TAPVOL) +
                          OPTION(*NEW) MBROPT(*ALL) ALWOBJDIF(*ALL) +
                          RSTLIB(MONLIBSF03) OUTPUT(*PRINT)
             RSTLIB     SAVLIB(OCEANTOOLS) DEV(&TAPDEV) VOL(&TAPVOL) +
                          OPTION(*NEW) MBROPT(*ALL) ALWOBJDIF(*ALL) +
                          RSTLIB(OCEANTOF03) OUTPUT(*PRINT)
             RSTLIB     SAVLIB(SMSLIB) DEV(&TAPDEV) VOL(&TAPVOL) +
                          OPTION(*NEW) MBROPT(*ALL) ALWOBJDIF(*ALL) +
                          RSTLIB(SMSLIBSF03) OUTPUT(*PRINT)
             ENDDO
             ELSE       CMD(DO)
             CHGVAR     VAR(&TAPDEV) VALUE(&SYSNM)
             SNDPGMMSG  MSG('System not supported. System is ' *CAT +
                          &SYSNM *CAT '.')
             ENDDO
             ENDPGM