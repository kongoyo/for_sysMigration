/********************************************************************/
/*                                                                  */
/* 5770SS1 V7R5M0 220415     RTVCLSRC Output     25/07/18 02:44:32  */
/*                                                                  */
/* Program name . . . . . . . . . . . . . . :   COLOBJAUT         PN*/
/* Library name . . . . . . . . . . . . . . :   DDSCINFO          PL*/
/* Original source file . . . . . . . . . . :   STVSRC            SN*/
/* Library name . . . . . . . . . . . . . . :   STEVE             SL*/
/* Original source member . . . . . . . . . :   COLOBJAUT         SM*/
/* Source file change                                               */
/*   date/time  . . . . . . . . . . . . . . :   25/06/08 15:03:30 SC*/
/* Patch option . . . . . . . . . . . . . . :   *NOPATCH          PO*/
/* User profile . . . . . . . . . . . . . . :   *USER             UP*/
/* Text . . . : Loop read 2 files in CL                           TX*/
/* Owner  . . . . . . . . . . . . . . . . . :   IBMECS            OW*/
/* User mod flag  . . . . . . . . . . . . . :   *YES              UM*/
/* Retrieve included source . . . . . . . . :   *NO               RI*/
/*                                                                ED*/
/********************************************************************/
             PGM        PARM(&ULIB)
             DCLF       FILE(QTEMP/OBJLST) OPNID(OBJLST)
             DCLF       FILE(QTEMP/LIBLST) OPNID(LIBLST)
             DCL        VAR(&ULIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&STMT) TYPE(*CHAR) LEN(255)
             DCL        VAR(&FIRSTIND) TYPE(*CHAR) LEN(1) VALUE('Y')
             MONMSG     MSGID(CPF0000 CPA0000 MCH0000 SQL0000)
             DLTOBJ     OBJ(QTEMP/OBJLST) OBJTYPE(*FILE)
             MONMSG     MSGID(CPF2105)
             DLTOBJ     OBJ(QTEMP/LIBLST) OBJTYPE(*FILE)
             MONMSG     MSGID(CPF2105)
             DLTOBJ     OBJ(DDSCINFO/OBJAUT) OBJTYPE(*FILE)
             MONMSG     MSGID(CPF2105)
             IF         COND(&ULIB *EQ '*ALLUSR') THEN(DO)
             DSPOBJD    OBJ(%UPPER(&ULIB)) OBJTYPE(*LIB) +
                          OUTPUT(*OUTFILE) OUTFILE(QTEMP/LIBLST)
             MONMSG     MSGID(CPF0000) EXEC(DO)
             SNDPGMMSG  MSG('UNABLE TO PROCESS THE INPUT LIBRARY ... +
                          ' *CAT %UPPER(&ULIB))
             GOTO       CMDLBL(ABNOREND)
             ENDDO
             ENDDO
             ELSE       CMD(DO)
             DSPOBJD    OBJ(QSYS/%UPPER(&ULIB)) OBJTYPE(*LIB) +
                          OUTPUT(*OUTFILE) OUTFILE(QTEMP/LIBLST)
             MONMSG     MSGID(CPF0000) EXEC(DO)
             SNDPGMMSG  MSG('UNABLE TO PROCESS THE INPUT LIBRARY ... +
                          ' *CAT %UPPER(&ULIB))
             GOTO       CMDLBL(ABNOREND)
             ENDDO
             ENDDO

 LIBBEG:     RCVF       OPNID(LIBLST)
             MONMSG     MSGID(CPF0864) EXEC(DO)
             CLOSE      OPNID(LIBLST)
             GOTO       CMDLBL(EOF)
             ENDDO
             SNDPGMMSG  MSG('PROCESSING LIBRARY ... ' *CAT +
                          &LIBLST_ODOBNM)
             DSPOBJD    OBJ(&LIBLST_ODOBNM/*ALL) OBJTYPE(*ALL) +
                          OUTPUT(*OUTFILE) OUTFILE(QTEMP/OBJLST)
 OBJBEG:     RCVF       OPNID(OBJLST)
             MONMSG     MSGID(CPF0864) EXEC(DO)
             CLOSE      OPNID(OBJLST)
             GOTO       CMDLBL(OBJEOF)
             ENDDO
             IF         COND(&OBJLST_ODLBNM *EQ 'QSYS' *AND +
                          &OBJLST_ODOBNM *EQ 'QTEMP') THEN(DO)
             SNDPGMMSG  MSG('DO NOT PROCESS OBJECT QSYS/QTEMP!')
             ENDDO
             ELSE       CMD(DO)
             DSPOBJAUT  OBJ(&OBJLST_ODLBNM/&OBJLST_ODOBNM) +
                          OBJTYPE(&OBJLST_ODOBTP) OUTPUT(*OUTFILE) +
                          OUTFILE(DDSCINFO/OBJAUT) OUTMBR(*FIRST *ADD)
             ENDDO
             IF         COND(&FIRSTIND *EQ 'Y') THEN(DO)
             CHGPF      FILE(DDSCINFO/OBJAUT) SIZE(*NOMAX)
             CHGVAR     VAR(&FIRSTIND) VALUE('N')
             ENDDO
             GOTO       CMDLBL(OBJBEG)
 OBJEOF:     GOTO       CMDLBL(LIBBEG)
 EOF:        SNDPGMMSG  MSG('OBJECT AUTHORITY COLLECTION FINISHED!')
 ABNOREND:   ENDPGM
