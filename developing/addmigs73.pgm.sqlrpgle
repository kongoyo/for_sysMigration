**FREE
ctl-opt option(*srcstmt) actgrp(*caller) ;

dcl-pr syscmd int(10) ExtProc('system');
  *n Pointer Value Options(*String);
end-pr;

dcl-ds ScdJobRec EXTNAME('DDSCINFO/SCDJOBINF') QUALIFIED;
end-ds;

// declare Null Indicators
dcl-s  ScdDateNullInd int(5) ;
dcl-s  ReldmonNullInd int(5) ;
dcl-s  textNullInd int(5) ;
dcl-s  commandNullInd int(5) ;
dcl-s  jobqlNullInd int(5) ;
dcl-s  jobdlNullInd int(5) ;
dcl-s  msgqlNullInd int(5) ;
dcl-s  jobqNullInd int(5) ;
dcl-s  jobdNullInd int(5) ;
dcl-s  msgqNullInd int(5) ;
dcl-s  keepNullInd int(5) ;
dcl-s  omitdNullInd int(5) ;
dcl-s  scddaysNullInd int(5) ;

// declare command parameters
dcl-s cmdstr char(5000) inz;
dcl-s ReturnCode Int(10);
dcl-s scddateparm varchar(20) inz;
dcl-s formattedOmitDates varchar(512) inz;
dcl-s msgqparm varchar(21) inz;
dcl-s jobdparm varchar(21) inz;
dcl-s jobqparm varchar(21) inz;
dcl-s escapedText varchar(50) inz;

// Cursor
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
        FROM DDSCINFO.SCDJOBINFO;

EXEC SQL
    OPEN scdjob;

dow SQLCOD = 0;
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

  if sqlcod = 0 ;
    snd-msg '----- Record Begin -----';
    cmdstr = 'ADDJOBSCDE ';
    cmdstr = %trimr(cmdstr) + ' JOB(' + %trim(ScdJobRec.SCDJOBNAME) + ') ';
    cmdstr = %trimr(cmdstr) + ' CMD(' + %trim(ScdJobRec.COMMAND) + ') ';
    cmdstr = %trimr(cmdstr) + ' FRQ(' + %trim(ScdJobRec.FREQUENCY) + ') ';
    //
    if ScdJobRec.SCDDATEV = 'SCHEDULED_DATE';
      cmdstr = %trimr(cmdstr) + ' SCDDATE(' + %scanrpl('/' : '' : %char(ScdJobRec.SCDDATE : *YMD)) + ') ';
    elseif ScdJobRec.SCDDATEV = 'SCHEDULED_DAYS';
      cmdstr = %trimr(cmdstr) + ' SCDDAY(' + %scanrpl(',' : ' ' : %trim(ScdJobRec.SCDDAYS)) + ') ';
      scddateparm = '*NONE';
      cmdstr = %trimr(cmdstr) + ' SCDDATE(' + %trim(scddateparm) + ') ';
    else;
      scddateparm = %trim(ScdJobRec.SCDDATEV);
      cmdstr = %trimr(cmdstr) + ' SCDDATE(' + %trim(scddateparm) + ') ';
    endif;
    //
    cmdstr = %trimr(cmdstr) + ' SCDTIME(' + %scanrpl('.' : '' : %char(ScdJobRec.SCDTIME)) + ') ';
    //
    If ReldmonNullInd <> -1 and %trim(ScdJobRec.RELDAYSMON) <> '';
      cmdstr = %trimr(cmdstr) + ' RELDAYMON(' + %trim(ScdJobRec.RELDAYSMON) + ') ';
    EndIf;
    //
    If keepNullInd <> -1 and %trim(ScdJobRec.KEEP) <> '';
      cmdstr = %trimr(cmdstr) + ' SAVE(*' + %trim(ScdJobRec.KEEP) + ') ';
    EndIf;
    //
    If omitdNullInd <> -1 and %trim(ScdJobRec.OMITDATES) <> '';
      formattedOmitDates = ProcessOmitDates(%char(ScdJobRec.OMITDATES));
      cmdstr = %trimr(cmdstr) + ' OMITDATE(' + %trim(formattedOmitDates) + ') ';
    EndIf;
    //
    cmdstr = %trimr(cmdstr) + ' RCYACN(' + %trim(ScdJobRec.RECOVERY) + ') ';
    //
    If jobdlNullInd <> -1;
      cmdstr = %trimr(cmdstr) + ' JOBD(' + %trim(ScdJobRec.JOBDLIB) + '/' + %trim(ScdJobRec.JOBD) + ') ';
    else;
      cmdstr = %trimr(cmdstr) + ' JOBD(' + %trim(ScdJobRec.JOBD) + ') ';
    EndIf;
    //
    If jobqlNullInd <> -1;
      cmdstr = %trimr(cmdstr) + ' JOBQ(' + %trim(ScdJobRec.JOBQLIB) + '/' + %trim(ScdJobRec.JOBQ) + ') ';
    else;
      cmdstr = %trimr(cmdstr) + ' JOBQ(' + %trim(ScdJobRec.JOBQ) + ') ';
    EndIf;
    //
    If msgqlNullInd <> -1;
      cmdstr = %trimr(cmdstr) + ' MSGQ(' + %trim(ScdJobRec.MSGQLIB) + '/' + %trim(ScdJobRec.MSGQ) + ') ';
    else;
      cmdstr = %trimr(cmdstr) + ' MSGQ(' + %trim(ScdJobRec.MSGQ) + ') ';
    EndIf;
    //
    cmdstr = %trimr(cmdstr) + ' USER(' + %trim(ScdJobRec.SBMJOBUSR) + ') ';
    //
    If textNullInd <> -1 and %trim(ScdJobRec.TEXT) <> '';
      cmdstr = %trimr(cmdstr) + ' TEXT(''' + %trim(ScdJobRec.TEXT) + ''')';
    EndIf;
    //
    snd-msg 'Process ' + ScdJobRec.SCDJOBNAME;
    ReturnCode = syscmd(cmdstr);
    If ReturnCode <> 0;
      snd-msg 'Command: ';
      snd-msg '  ' + cmdstr;
    endif;
    //
    snd-msg '----- Record End -----';
    sqlcod = 0;
  endif;
enddo;

EXEC SQL
    CLOSE scdjob;

*INLR = *ON;
RETURN;

dcl-proc ProcessOmitDates;
  dcl-pi ProcessOmitDates varchar(512);
    in_omitDates varchar(512) const;
  end-pi;

  dcl-s current_date varchar(10) inz;
  dcl-s start_pos int(10) inz(1);
  dcl-s comma_pos int(10) inz;
  dcl-s remaining_string varchar(512);
  dcl-s result_string varchar(512) inz;

  remaining_string = in_omitDates;

  dow %len(%trim(remaining_string)) > 0;
    comma_pos = %scan(',' : remaining_string : start_pos);
    if comma_pos = 0;
      current_date = %trim(remaining_string);
      remaining_string = '';
    else;
      current_date = %subst(remaining_string : start_pos : comma_pos - start_pos);
      remaining_string = %subst(remaining_string : comma_pos + 1);
    endif;
    result_string = %trim(result_string) + ' ' + %subst(%trim(%scanrpl('-' : '' : current_date)) : 3 : 6);
  enddo;

  if %subst(%trim(result_string) : 1 : 1) = ' ';
    result_string = %trim(%subst(%trim(result_string) : 2));
  endif;
  return result_string;
end-proc;
