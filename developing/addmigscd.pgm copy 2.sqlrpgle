**FREE
ctl-opt option(*srcstmt) actgrp(*caller) ;

// Copy a new table from qsys2.scheduled_job_info to DDSCINFO.SCDJOBINF
// declare data structure
DCL-DS ScdJobRec_t EXTNAME('DDSCINFO/SCDJOBINF') QUALIFIED;
END-DS;
DCL-DS ScdJobRec likeds(ScdJobRec_t);

dcl-s scdtimh char(2) inz;
dcl-s scdtimm char(2) inz;
dcl-s scdtims char(2) inz;

// declare Null Indicators
Dcl-S  ScdDateNullInd int(5) ;
Dcl-S  ReldmonNullInd int(5) ;
Dcl-S  textNullInd int(5) ;
Dcl-S  commandNullInd int(5) ;
Dcl-S  jobqlNullInd int(5) ;
Dcl-S  jobdlNullInd int(5) ;
Dcl-S  msgqlNullInd int(5) ;
Dcl-S  jobqNullInd int(5) ;
Dcl-S  jobdNullInd int(5) ;
Dcl-S  msgqNullInd int(5) ;
Dcl-S  keepNullInd int(5) ;
Dcl-S  omitdNullInd int(5) ;
Dcl-S  scddaysNullInd int(5) ;

// Prototype for QCMDEXC API
dcl-pr QCMDCHK extpgm ;
    *n char(500) options(*varsize) const ;
    *n packed(15:5) const ;
end-pr;

// Prototype for QCMDCHK API
dcl-pr QCMDEXC extpgm ;
    *n char(500) options(*varsize) const ;
    *n packed(15:5) const ;
end-pr;

dcl-s cmdstr char(500) inz;
dcl-s cmdlen packed(15:5) inz;

// 宣告 Cursor
EXEC SQL
    DECLARE scdjob CURSOR FOR
        SELECT
            COALESCE ( SCHEDULED_JOB_ENTRY_NUMBER , 0 ),    /* INTEGER       */
            COALESCE ( SCHEDULED_JOB_NAME , '' ),           /* VARCHAR(10)   */
            COALESCE ( SCHEDULED_DATE_VALUE , '' ),         /* VARCHAR(14)   */
            SCHEDULED_DATE,                                 /* DATE          */
            COALESCE ( SCHEDULED_TIME , '00:00:00' ),       /* TIME          */
            SCHEDULED_DAYS,                                 /* VARCHAR(34)   */
            FREQUENCY,                                      /* VARCHAR(8)    */
            RELATIVE_DAYS_OF_MONTH,                         /* VARCHAR(13)   */
            RECOVERY_ACTION,                                /* VARCHAR(7)    */
            JOB_QUEUE_NAME,                                 /* VARCHAR(10)   */
            JOB_QUEUE_LIBRARY_NAME,                         /* VARCHAR(10)   */
            DATES_OMITTED,                                  /* VARCHAR(219)  */
            DESCRIPTION,                                    /* VARCHAR(50)   */
            COMMAND_STRING,                                 /* VARCHAR(512)  */
            USER_PROFILE_FOR_SUBMITTED_JOB,                 /* VARCHAR(10)   */
            JOB_DESCRIPTION_NAME,                           /* VARCHAR(10)   */
            JOB_DESCRIPTION_LIBRARY_NAME,                   /* VARCHAR(10)   */
            MESSAGE_QUEUE_NAME,                             /* VARCHAR(10)   */
            MESSAGE_QUEUE_LIBRARY_NAME,                     /* VARCHAR(10)   */
            KEEP_ENTRY                                      /* VARCHAR(3)    */
        FROM DDSCINFO.SCDJOBINF;

// 打開 Cursor
EXEC SQL
    OPEN scdjob;

// 第一次讀取資料 (在迴圈前)
EXEC SQL
    FETCH NEXT FROM scdjob INTO :ScdJobRec.ENTRYNO,
                                :ScdJobRec.SCDJOBNAME,
                                :ScdJobRec.SCDDATEV,
                                :ScdJobRec.SCDDATE :ScdDateNullInd,
                                :ScdJobRec.SCDTIME,
                                :ScdJobRec.SCDDAYS :scddaysNullInd,
                                :ScdJobRec.FREQUENCY,
                                :ScdJobRec.RELDAYSMON :ReldmonNullInd,
                                :ScdJobRec.RECOVERY,
                                :ScdJobRec.JOBQ :jobqNullInd,
                                :ScdJobRec.JOBQLIB :jobqlNullInd,
                                :ScdJobRec.OMITDATES :omitdNullInd,
                                :ScdJobRec.TEXT :textNullInd,
                                :ScdJobRec.COMMAND :commandNullInd,
                                :ScdJobRec.SBMJOBUSR,
                                :ScdJobRec.JOBD :jobdNullInd,
                                :ScdJobRec.JOBDLIB :jobdlNullInd,
                                :ScdJobRec.MSGQ :msgqNullInd,
                                :ScdJobRec.MSGQLIB :msgqlNullInd,
                                :ScdJobRec.KEEP :keepNullInd;

// 迴圈處理資料
DOW SQLCOD = 0; // 當 SQLCOD 為 0 時表示成功讀取到資料
    snd-msg '----- Record Begin -----';
  // --- 在這裡處理每一筆記錄 ---
  // ... 下面會詳細說明欄位處理 ...
    if sqlcode = 0;
        snd-msg ' < scheduled date > ';
        If ScdDateNullInd <> -1;
        else;
        endif;

        snd-msg ' < scheduled time > ';
        scdtimh = %subst(%char(scdjobrec.scdtime):1:2);
        scdtimm = %subst(%char(scdjobrec.scdtime):4:2);
        scdtims = %subst(%char(scdjobrec.scdtime):7:2);

        // scdtimhh = %subst(%char(scdtimhms):1:2);
        // scdtimmm = %subst(scdtimhms:3:2);
        // scdtimmm = %subst(scdtimhms:5:2);

        snd-msg ' < Process command string > ';
        cmdstr = 'ADDJOBSCDE '
                + 'JOB(' + %trim(scdjobrec.scdJobName) + ') '
                + 'CMD(' + %trim(scdjobrec.command) + ') '
                + 'FRQ(' + %trim(scdjobrec.frequency) + ') '
                + 'SCDDATE(' + %trim(%char(scdjobrec.scdDate)) + ') '
                + 'SCDDAY(' + %trim(scdjobrec.SCDDAYS) + ') '
                + 'SCDTIME(' + scdtimh + scdtimm + scdtims + ') '
                + 'RELDAYMON(' + %trim(scdjobrec.RELDAYSMON) + ') '
                + 'SAVE(' + %trim(scdjobrec.KEEP) + ') '
                + 'OMITDATE(' + %trim(scdjobrec.OMITDATES) + ') '
                + 'RCYACN(' + %trim(scdjobrec.recovery) + ') '
                + 'JOBD(' + %trim(scdjobrec.JOBDLIB) + '/' + %trim(scdjobrec.JOBD) + ') '
                + 'JOBQ(' + %trim(scdjobrec.JOBqLIB) + '/' + %trim(scdjobrec.JOBq) + ') '
                + 'USER(' + %trim(scdjobrec.sbmJobUsr) + ') '
                + 'MSGQ(' + %trim(scdjobrec.msgqLIB) + '/' + %trim(scdjobrec.msgq) + ') '
                + 'TEXT(''' + %trim(scdjobrec.text) + ''')';

        snd-msg cmdstr;

        monitor;
            exec sql
                CALL QSYS2.QCMDEXC(:cmdstr);
        ON-EXCP 'CPF0006';
            dsply ('QCMDEXC Error: ');
        endmon;

    elseIf SqlCod = 100;
        // SQLCODE 100 表示沒有更多資料
        snd-msg 'No more record need to process ...';
    else;
       // 處理其他錯誤
       Dsply ('SQL Error: ' + %Char(SqlCod));
    endif;
    snd-msg '----- Record End -----';

  // 讀取下一筆資料
  EXEC SQL
    FETCH NEXT FROM scdjob INTO :ScdJobRec.ENTRYNO,
                                :ScdJobRec.SCDJOBNAME,
                                :ScdJobRec.SCDDATEV,
                                :ScdJobRec.SCDDATE :ScdDateNullInd,
                                :ScdJobRec.SCDTIME,
                                :ScdJobRec.SCDDAYS :scddaysNullInd,
                                :ScdJobRec.FREQUENCY,
                                :ScdJobRec.RELDAYSMON :ReldmonNullInd,
                                :ScdJobRec.RECOVERY,
                                :ScdJobRec.JOBQ :jobqNullInd,
                                :ScdJobRec.JOBQLIB :jobqlNullInd,
                                :ScdJobRec.OMITDATES :omitdNullInd,
                                :ScdJobRec.TEXT :textNullInd,
                                :ScdJobRec.COMMAND :commandNullInd,
                                :ScdJobRec.SBMJOBUSR,
                                :ScdJobRec.JOBD :jobdNullInd,
                                :ScdJobRec.JOBDLIB :jobdlNullInd,
                                :ScdJobRec.MSGQ :msgqNullInd,
                                :ScdJobRec.MSGQLIB :msgqlNullInd,
                                :ScdJobRec.KEEP :keepNullInd;
ENDDO;

EXEC SQL
    CLOSE scdjob;

*INLR = *ON;
RETURN;
