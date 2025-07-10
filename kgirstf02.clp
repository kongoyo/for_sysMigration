             PGM        PARM(&TAP)
             DCL        VAR(&TAP) TYPE(*CHAR) LEN(10)

             MONMSG     MSGID(CPF0000 CPA0000 SQL0000 MCH0000)

          /* AS101 RENAME LIBRARIES */

             RNMOBJ     OBJ(QSYS/$INFRA) OBJTYPE(*LIB) +
                          NEWOBJ($INFRAS101)
             RNMOBJ     OBJ(QSYS/CCI) OBJTYPE(*LIB) NEWOBJ(CCIAS101)
             RNMOBJ     OBJ(QSYS/MONLIB) OBJTYPE(*LIB) +
                          NEWOBJ(MONLIBS101)
             RNMOBJ     OBJ(QSYS/OCEANTOOLS) OBJTYPE(*LIB) +
                          NEWOBJ(OCEANTS101)
             RNMOBJ     OBJ(QSYS/SMSLIB) OBJTYPE(*LIB) +
                          NEWOBJ(SMSLIBS101)

          /* KSF02 RESTORE AP USER PROFILES */

             RSTUSRPRF  DEV(&TAP) USRPRF(FUCOMM FUITKS F0* KCOFOWN +
                          KCOFSCRT KOFADM KSOFUSR S920 S92001) +
                          ENDOPT(*REWIND) ALWOBJDIF(*ALL) +
                          SECDTA(*USRPRF)

             RSTUSRPRF  DEV(&TAP) USRPRF(FUCOMM FUITKS F0* KCOFOWN +
                          KCOFSCRT KOFADM KSOFUSR S920 S92001) +
                          ENDOPT(*REWIND) ALWOBJDIF(*ALL) +
                          SECDTA(*PVTAUT)

             RSTUSRPRF  DEV(&TAP) USRPRF(FUCOMM FUITKS F0* KCOFOWN +
                          KCOFSCRT KOFADM KSOFUSR S920 S92001) +
                          ENDOPT(*REWIND) ALWOBJDIF(*ALL) +
                          SECDTA(*PWDGRP)

          /* KSF02 RESTORE AP SELECTED LIBRARY AND OBJECT */

             RSTLIB     SAVLIB(KCOFCMTF KCOFCMTT KCOFITN KCOFPRC +
                          KCOFUSR KCOFSCRT KSOFFINA KSOFFINF +
                          KSOFFINFVR KSOFFIXF KSUSER FU1000427 +
                          FUCOMM SMTPSPL S007389 GZIP) DEV(&TAP) +
                          OPTION(*ALL) MBROPT(*ALL) ALWOBJDIF(*ALL) +
                          OUTPUT(*PRINT)

             RSTOBJ     OBJ(PTM0000P PTM000D) SAVLIB(QGPL) DEV(&TAP) +
                          MBROPT(*ALL) ALWOBJDIF(*ALL) OUTPUT(*PRINT)

          /* KSF02 RESTORE OTHER LIBRARIES */

             RSTLIB     SAVLIB(*ALLUSR) DEV(&TAP) OPTION(*NEW) +
                          MBROPT(*ALL) ALWOBJDIF(*ALL) OUTPUT(*PRINT)

          /* KSF02 RESTORE AUTHORITY */

             RSTAUT     USRPRF(FUCOMM FUITKS F0* KCOFOWN KCOFSCRT +
                          KOFADM KSOFUSR S920 S92001)

          /* KSF02 RENAME LIBRARIES */

             RNMOBJ     OBJ(QSYS/$INFRA) OBJTYPE(*LIB) +
                          NEWOBJ($INFRASF02)
             RNMOBJ     OBJ(QSYS/CCI) OBJTYPE(*LIB) NEWOBJ(CCIKSF02)
             RNMOBJ     OBJ(QSYS/MONLIB) OBJTYPE(*LIB) +
                          NEWOBJ(MONLIBSF02)
             RNMOBJ     OBJ(QSYS/OCEANTOOLS) OBJTYPE(*LIB) +
                          NEWOBJ(OCEANTSF02)
             RNMOBJ     OBJ(QSYS/SMSLIB) OBJTYPE(*LIB) +
                          NEWOBJ(SMSLIBSF02)

             ENDPGM
