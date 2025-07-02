**FREE
ctl-opt option(*srcstmt) dftactgrp(*no);

DCL-DS scdjobrec_t EXTNAME('QSYS2/SCHED_JOB') QUALIFIED;
END-DS;
DCL-DS scdjobrec likeds(scdjobrec_t);

dcl-s scddateparm varchar(20) inz;
dcl-s formattedOmitDates varchar(512);

dcl-pr syscmd int(10) ExtProc('system');
  *n Pointer Value Options(*String);
end-pr;

dcl-s cmdstr char(500) inz;
dcl-s ReturnCode Int(10);

dcl-s cur_sysnm varchar(10);
dcl-s ifsfnm char(200);
dcl-s cur_date date;
dcl-s cur_time time;
dcl-s logtxt char(1000);

exec sql values current server into :cur_sysnm;
exec sql values(current_date) into :cur_date;
exec sql values(current_time) into :cur_time;
ifsfnm = '/home/qsecofr/kgi_log/addmigscd_' + %trim(%scanrpl('-' : '' : %char(cur_date))) + 
         '_' + %trim(%scanrpl('.' : '' : %char(cur_time))) + '.log';
exec sql call QSYS2.IFS_WRITE(trim(:ifsfnm),
                                  '',
                                  OVERWRITE => 'REPLACE',
                                  FILE_CCSID => '950',
                                  END_OF_LINE => 'NONE');
logtxt = ' ' + %trim(%char(cur_date)) + 
         ' ' + %trim(%char(cur_time)) + 
         ' ' + %trim(cur_sysnm) + 
         ' ' + 'Add migration scheduled job start.';
exec sql call QSYS2.IFS_WRITE(trim(:ifsfnm),
                                  trim(:logtxt),
                                  OVERWRITE => 'APPEND',
                                  END_OF_LINE => 'CRLF');
exec sql  
    DECLARE scdjob CURSOR FOR
      Select scheduled_job_entry_number,
        scheduled_job_name,
        scheduled_date_value,
        Coalesce(scheduled_date, '1940-01-01') As scheduled_date,
        scheduled_time,
        Coalesce(scheduled_days, '') As scheduled_days,
        frequency,
        Coalesce(relative_days_of_month, '') As relative_days_of_month,
        recovery_action,
        status,
        job_queue_name,
        Coalesce(job_queue_library_name, '') As job_queue_library_name,
        Coalesce(job_queue_status, '') As job_queue_status,
        Coalesce(dates_omitted, '') As dates_omitted,
        Coalesce(description, '') As description,
        Coalesce(command_string, '') As command_string,
        Coalesce(user_profile_for_submitted_job, '') As user_profile_for_submitted_job,
        Coalesce(job_description_name, '') As job_description_name,
        Coalesce(job_description_library_name, '') As job_description_library_name,
        Coalesce(message_queue_name, '') As message_queue_name,
        Coalesce(message_queue_library_name, '') As message_queue_library_name,
        Coalesce(keep_entry, '') As keep_entry
      From ddscinfo.scdjobinfo
      order by scheduled_job_entry_number;

// 打開 Cursor
EXEC SQL OPEN scdjob;

// 第一次讀取資料 (在迴圈前)
EXEC SQL
    FETCH NEXT FROM scdjob INTO :scdjobrec.ENTRYNO,
                                :scdjobrec.SCDJOBNAME,
                                :scdjobrec.SCDDATEV,
                                :scdjobrec.SCDDATE,
                                :scdjobrec.SCDTIME,
                                :scdjobrec.SCDDAYS,
                                :scdjobrec.FREQUENCY,
                                :scdjobrec.RELDAYSMON,
                                :scdjobrec.RECOVERY,
                                :scdjobrec.status,
                                :scdjobrec.JOBQ,
                                :scdjobrec.JOBQLIB,
                                :scdjobrec.jobqstatus,
                                :scdjobrec.OMITDATES,
                                :scdjobrec.TEXT,
                                :scdjobrec.COMMAND,
                                :scdjobrec.SBMJOBUSR,
                                :scdjobrec.JOBD,
                                :scdjobrec.JOBDLIB,
                                :scdjobrec.MSGQ,
                                :scdjobrec.MSGQLIB,
                                :scdjobrec.KEEP;
DOW SQLCOD = 0; 
  if sqlcod = 0;
    cmdstr = 'ADDJOBSCDE'
              + ' JOB(' + %trim(scdjobrec.scdJobName) + ')'
              + ' CMD(' + %trim(scdjobrec.command) + ')'
              + ' FRQ(' + %trim(scdjobrec.frequency) + ')';
    if scdjobrec.SCDDATEV = 'SCHEDULED_DATE';
      cmdstr = %trimr(cmdstr) + ' SCDDATE(' + %scanrpl('/' : '' : %char(scdjobrec.SCDDATE : *YMD)) + ') ';
    elseif scdjobrec.SCDDATEV = 'SCHEDULED_DAYS';
      cmdstr = %trimr(cmdstr) + ' SCDDAY(' + %scanrpl(',' : ' ' : %trim(scdjobrec.SCDDAYS)) + ') ';
      scddateparm = '*NONE';
      cmdstr = %trimr(cmdstr) + ' SCDDATE(' + %trim(scddateparm) + ') ';
    else;
      scddateparm = %trim(scdjobrec.SCDDATEV);
      cmdstr = %trimr(cmdstr) + ' SCDDATE(' + %trim(scddateparm) + ') ';
    endif;
    cmdstr = %trimr(cmdstr) + ' SCDTIME(' + %scanrpl('.' : '' : %char(ScdJobRec.SCDTIME)) + ') ';
    if %trim(scdjobrec.FREQUENCY) = '*ONCE';
      cmdstr = %trimr(cmdstr) + ' SAVE(*' + %trim(scdjobrec.KEEP) + ')';
    endif;  
    if %trim(scdjobrec.RELDAYSMON) <> '';
      cmdstr = %trimr(cmdstr) + ' RELDAYMON(' + %trim(scdjobrec.RELDAYSMON) + ')';
    endif;        
    if %trim(scdjobrec.jobdlib) = '';
      cmdstr = %trimr(cmdstr) + ' JOBD(' + %trim(scdjobrec.JOBD) + ')';
    else;
      cmdstr = %trimr(cmdstr) + ' JOBD(' + %trim(scdjobrec.JOBDLIB) + '/' + %trim(scdjobrec.JOBD) + ')';
    endif;
    if %trim(scdjobrec.jobqlib) = '';
      cmdstr = %trimr(cmdstr) + ' JOBQ(' + %trim(scdjobrec.JOBQ) + ')';
    else;
      cmdstr = %trimr(cmdstr) + ' JOBQ(' + %trim(scdjobrec.JOBQLIB) + '/' + %trim(scdjobrec.JOBQ) + ')';
    endif;
    if %trim(scdjobrec.msgqlib) = '';
      cmdstr = %trimr(cmdstr) + ' MSGQ(' + %trim(scdjobrec.MSGQ) + ')';
    else;
      cmdstr = %trimr(cmdstr) + ' MSGQ(' + %trim(scdjobrec.MSGQLIB) + '/' + %trim(scdjobrec.MSGQ) + ')';
    endif;
    if %trim(scdjobrec.OMITDATES) <> '';
      formattedOmitDates = ProcessOmitDates(scdjobrec.OMITDATES);
      cmdstr = %trimr(cmdstr) + ' OMITDATE(' + %trim(formattedOmitDates) + ')';
    endif;
    if %trim(scdjobrec.TEXT) <> '';
      cmdstr = %trimr(cmdstr) + ' TEXT(''' + %trim(scdjobrec.text) + ''')';
    endif;
    cmdstr = %trimr(cmdstr)
              + ' RCYACN(' + %trim(scdjobrec.recovery) + ')'
              + ' USER(' + %trim(scdjobrec.sbmJobUsr) + ')';
      // snd-msg %trimr(cmdstr);
    ReturnCode = syscmd(cmdstr);
    If ReturnCode <> 0;
      // snd-msg '-- Add scheduled job error ' + ScdJobRec.SCDJOBNAME;
      logtxt = ' ' + %trim(%char(cur_date)) + 
         ' ' + %trim(%char(cur_time)) + 
         ' ' + %trim(cur_sysnm) + 
         ' ' + '-- Add scheduled job error ' + ScdJobRec.SCDJOBNAME;
      exec sql call QSYS2.IFS_WRITE(trim(:ifsfnm),
                                  trim(:logtxt),
                                  OVERWRITE => 'APPEND',
                                  END_OF_LINE => 'CRLF');
      // snd-msg 'Command: ';
      logtxt = ' ' + %trim(%char(cur_date)) + 
         ' ' + %trim(%char(cur_time)) + 
         ' ' + %trim(cur_sysnm) + 
         ' ' + 'Command: ' + %trim(cmdstr);
      exec sql call QSYS2.IFS_WRITE(trim(:ifsfnm),
                                  trim(:logtxt),
                                  OVERWRITE => 'APPEND',
                                  END_OF_LINE => 'CRLF');
    else;
      // Hold Job Schedule Entry
      clear cmdstr;
      if scdjobrec.status = 'HELD';
        cmdstr = 'HLDJOBSCDE JOB(' + %trim(scdjobrec.SCDJOBNAME) + ') ENTRYNBR(*ALL)';
        ReturnCode = syscmd(cmdstr);
        If ReturnCode <> 0;
        // snd-msg '-- Hold scheduled job error ' + ScdJobRec.SCDJOBNAME;
          logtxt = ' ' + %trim(%char(cur_date)) + 
         ' ' + %trim(%char(cur_time)) + 
         ' ' + %trim(cur_sysnm) + 
         ' ' + '-- Hold scheduled job error ' + ScdJobRec.SCDJOBNAME;
          exec sql call QSYS2.IFS_WRITE(trim(:ifsfnm),
                                  trim(:logtxt),
                                  OVERWRITE => 'APPEND',
                                  END_OF_LINE => 'CRLF');
        // snd-msg 'Command: ';
        // snd-msg '  ' + %trim(cmdstr);
          logtxt = ' ' + %trim(%char(cur_date)) + 
         ' ' + %trim(%char(cur_time)) + 
         ' ' + %trim(cur_sysnm) + 
         ' ' + 'Command: ' + %trim(cmdstr);
          exec sql call QSYS2.IFS_WRITE(trim(:ifsfnm),
                                  trim(:logtxt),
                                  OVERWRITE => 'APPEND',
                                  END_OF_LINE => 'CRLF');
        endif;
      endif;
      // Delete Job Schedule Entry
      clear cmdstr;
    // if scdjobrec.status = 'HELD';
      cmdstr = 'RMVJOBSCDE JOB(' + %trim(scdjobrec.SCDJOBNAME) + ') ENTRYNBR(*ALL)';
      ReturnCode = syscmd(cmdstr);
      If ReturnCode <> 0;
        // snd-msg '-- Delete scheduled job error ' + ScdJobRec.SCDJOBNAME;
        logtxt = ' ' + %trim(%char(cur_date)) + 
         ' ' + %trim(%char(cur_time)) + 
         ' ' + %trim(cur_sysnm) + 
         ' ' + '-- Delete scheduled job error ' + ScdJobRec.SCDJOBNAME;
        exec sql call QSYS2.IFS_WRITE(trim(:ifsfnm),
                                  trim(:logtxt),
                                  OVERWRITE => 'APPEND',
                                  END_OF_LINE => 'CRLF');
        // snd-msg 'Command: ';
        // snd-msg '  ' + %trim(cmdstr);
        logtxt = ' ' + %trim(%char(cur_date)) + 
         ' ' + %trim(%char(cur_time)) + 
         ' ' + %trim(cur_sysnm) + 
         ' ' + 'Command: ' + %trim(cmdstr);
        exec sql call QSYS2.IFS_WRITE(trim(:ifsfnm),
                                  trim(:logtxt),
                                  OVERWRITE => 'APPEND',
                                  END_OF_LINE => 'CRLF');
      endif;
    // endif;
    endif;
      
  else;
    // Dsply ('SQL Error: ' + %Char(SqlCod));
  endif;
  clear scdjobrec;
  clear cmdstr;
  // 讀取下一筆資料
  EXEC SQL
    FETCH NEXT FROM scdjob INTO :scdjobrec.ENTRYNO,
                                :scdjobrec.SCDJOBNAME,
                                :scdjobrec.SCDDATEV,
                                :scdjobrec.SCDDATE,
                                :scdjobrec.SCDTIME,
                                :scdjobrec.SCDDAYS,
                                :scdjobrec.FREQUENCY,
                                :scdjobrec.RELDAYSMON,
                                :scdjobrec.RECOVERY,
                                :scdjobrec.status,
                                :scdjobrec.JOBQ,
                                :scdjobrec.JOBQLIB,
                                :scdjobrec.jobqstatus,
                                :scdjobrec.OMITDATES,
                                :scdjobrec.TEXT,
                                :scdjobrec.COMMAND,
                                :scdjobrec.SBMJOBUSR,
                                :scdjobrec.JOBD,
                                :scdjobrec.JOBDLIB,
                                :scdjobrec.MSGQ,
                                :scdjobrec.MSGQLIB,
                                :scdjobrec.KEEP;

ENDDO;

EXEC SQL CLOSE scdjob;
logtxt = ' ' + %trim(%char(cur_date)) + 
         ' ' + %trim(%char(cur_time)) + 
         ' ' + %trim(cur_sysnm) + 
         ' ' + 'Add migration scheduled job finished.';
exec sql call QSYS2.IFS_WRITE(trim(:ifsfnm),
                                  trim(:logtxt),
                                  OVERWRITE => 'APPEND',
                                  END_OF_LINE => 'CRLF');
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