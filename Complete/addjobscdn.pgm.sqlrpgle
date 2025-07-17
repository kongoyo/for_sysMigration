**FREE
// CALL PGM(STEVE/ADDJOBSCDN) PARM(('DDSCINFO') ('SCDJOBINF') ('Y') ('Y') ('N'))
// PARM : 
//      scheduled_job_lib_name
//      scheduled_jop_obj_name
//      add_scheduled_job_entry(Y/N)
//      hold_scheduled_job_entry(Y/N)
//      delete_scheduled_job_entry(Y/N)
//
ctl-opt option(*srcstmt) dftactgrp(*no);
//
dcl-pi *n;
    list_libnm char(10); 
    list_filnm char(10);
    add_ind char(1); 
    hld_ind char(1);  
    dlt_ind char(1); 
end-pi;
//
dcl-s logsts char(1); // T: Log Title  C: Log Continue  E: Log Ending
dcl-s logtxt char(1500);
// Main procedure
clear logtxt;
logsts = 'T';
writelog(logsts : logtxt);

logsts = 'C';
logtxt = 'Process Job scheduled start';
writelog(logsts : logtxt);

read_from_file(list_libnm : list_filnm : add_ind : hld_ind : dlt_ind);

logsts = 'C';
logtxt = 'Process Job scheduled end';
writelog(logsts : logtxt);

clear logtxt;
logsts = 'E';
writelog(logsts : logtxt);
*inlr = *on;
return;

dcl-proc read_from_file;
    dcl-pi *n;
        list_libnm char(10);
        list_filnm char(10);
        add_ind char(1);
        hld_ind char(1);
        dlt_ind char(1);
    end-pi;
    dcl-s stmt char(1500);
    dcl-s scdentryno packed(6:0);
    dcl-s scdjobname char(10);
    dcl-s scddatev char(14);
    dcl-s scddate char(10);
    dcl-s scdtime char(8);
    dcl-s scddays char(34);
    dcl-s frequency char(8);
    dcl-s reldaysmon char(13);
    dcl-s recovery char(7);
    dcl-s status char(9);
    dcl-s jobqname char(10);
    dcl-s jobqlname char(10);
    dcl-s datesomite char(219);
    dcl-s description varchar(50) ccsid(937);
    dcl-s cmd char(512);
    dcl-s usrprf_sbmjob char(10);
    dcl-s jobdname char(10);
    dcl-s jobdlname char(10);
    dcl-s msgqname char(10);
    dcl-s msgqlname char(10);
    dcl-s keepentry char(3);
    dcl-s count packed(5:0);
    dcl-s add_errcount packed(5:0);
    dcl-s hld_errcount packed(5:0);
    dcl-s dlt_errcount packed(5:0);
    dcl-s cmdstr char(800);
    //
    clear count;
    clear add_errcount;
    clear hld_errcount;
    clear dlt_errcount;
    //
    stmt = 'SELECT ' +
            // 'SCHEDULED_JOB_ENTRY_NUMBER, ' +
            'SCHEDULED_JOB_NAME, ' +
            'SCHEDULED_DATE_VALUE, ' +
            'coalesce(cast(SCDDATE as char(10)),'''') as scddate, ' +
            'coalesce(cast(SCDTIME as char(8)),'''') as scdtime, ' +
            'coalesce(SCHEDULED_DAYS,'''') as SCHEDULED_DAYS, ' +
            'FREQUENCY, ' +
            'coalesce(RELATIVE_DAYS_OF_MONTH,'''') as RELATIVE_DAYS_OF_MONTH, ' +
            'RECOVERY_ACTION, ' +
            'STATUS, ' +
            'JOB_QUEUE_NAME, ' +
            'coalesce(JOB_QUEUE_LIBRARY_NAME,'''') as JOB_QUEUE_LIBRARY_NAME, ' +
            'coalesce(DATES_OMITTED,'''') as DATES_OMITTED, ' +
            'coalesce(cast(description AS varchar(50) CCSID 937),'''') as description, ' +
            'COMMAND_STRING, ' +
            'USER_PROFILE_FOR_SUBMITTED_JOB, ' +
            'JOB_DESCRIPTION_NAME, ' +
            'coalesce(JOB_DESCRIPTION_LIBRARY_NAME,'''') as JOB_DESCRIPTION_LIBRARY_NAME, ' +
            'MESSAGE_QUEUE_NAME, ' +
            'coalesce(MESSAGE_QUEUE_LIBRARY_NAME,'''') as MESSAGE_QUEUE_LIBRARY_NAME, ' +
            'coalesce(KEEP_ENTRY,'''') as KEEP_ENTRY ' +
            'FROM ' + %trim(list_libnm) + '.' + %trim(list_filnm);
    //
    // logsts = 'C';
    // logtxt = %trim(stmt);
    // writelog(logsts : logtxt);
    //
    exec sql prepare prescdjob from :stmt;
    exec sql declare scdjob cursor for prescdjob;
    exec sql open scdjob;
    exec sql fetch next from scdjob into :scdjobname, :scddatev, :scddate, :scdtime, :scddays, 
                                :frequency, :reldaysmon, :recovery, :status, :jobqname, :jobqlname, :datesomite, 
                                :description, :cmd, :usrprf_sbmjob, :jobdname, :jobdlname, :msgqname, :msgqlname, 
                                :keepentry;
    dow sqlcod = 0;
        if sqlcod = 0;
            count += 1;
            //
            prepare_cmd(cmdstr : scdjobname : scddatev : scddate : scdtime : scddays : 
                        frequency : reldaysmon : recovery : status : jobqname : jobqlname : datesomite : 
                        description : cmd : usrprf_sbmjob : jobdname : jobdlname : msgqname : msgqlname : 
                        keepentry);
            if add_ind = 'Y';
                execute_cmd(cmdstr : add_errcount);
            endif;
            // Hold job if status is HELD (and hld_status='Y'), or always if hld_status='N'
            if (hld_ind = 'Y' and status = 'HELD') or (hld_ind = 'N');
                clear scdentryno;
                exec sql SELECT char(scheduled_job_entry_number)
                            INTO :scdentryno
                            FROM QSYS2.SCHED_JOB
                            WHERE scheduled_job_name = :scdjobname
                            ORDER BY scheduled_job_entry_number DESC
                            FETCH FIRST 1 ROWS ONLY;
                if sqlcod = 0;
                    hold_jobscd(scdjobname : scdentryno : hld_errcount);
                else;
                    logsts = 'C';
                    logtxt = '*** WARNING *** : Could not find entry number for job ' + 
                             %trim(scdjobname) + ' to hold it.';
                    writelog(logsts : logtxt);
                endif;
            endif;
            if dlt_ind = 'Y';
                exec sql SELECT char(scheduled_job_entry_number)
                            INTO :scdentryno
                            FROM QSYS2.SCHED_JOB
                            WHERE scheduled_job_name = :scdjobname
                            ORDER BY scheduled_job_entry_number DESC
                            FETCH FIRST 1 ROWS ONLY;
                if sqlcod = 0;
                    delete_jobscd(scdjobname : scdentryno : dlt_errcount);
                else;
                    dlt_errcount += 1;
                    logsts = 'C';
                    logtxt = '*** WARNING *** : Could not find entry number for job ' + 
                             %trim(scdjobname) + ' to remove it.';
                    writelog(logsts : logtxt);
                endif;
            endif;
        endif;
        exec sql fetch next from scdjob into :scdjobname, :scddatev, :scddate, :scdtime, :scddays, 
                                :frequency, :reldaysmon, :recovery, :status, :jobqname, :jobqlname, :datesomite, 
                                :description, :cmd, :usrprf_sbmjob, :jobdname, :jobdlname, :msgqname, :msgqlname, 
                                :keepentry;
    enddo;
    exec sql close scdjob;
    snd-msg 'Count: ' + %trim(%char(count));
    snd-msg 'Add Error Count: ' + %trim(%char(add_errcount));
    snd-msg 'Hld Error Count: ' + %trim(%char(hld_errcount));
    snd-msg 'Dlt Error Count: ' + %trim(%char(dlt_errcount));
    //
    return;
end-proc;

dcl-proc prepare_cmd;
    dcl-pi *n;
        cmdstr char(800);
        scdjobname char(10);
        scddatev char(14);
        scddate char(10);
        scdtime char(8);
        scddays char(34);
        frequency char(8);
        reldaysmon char(13);
        recovery char(7);
        status char(9);
        jobqname char(10);
        jobqlname char(10);
        datesomit char(219);
        description varchar(50) ccsid(937);
        cmd char(512);
        usrprf_sbmjob char(10);
        jobdname char(10);
        jobdlname char(10);
        msgqname char(10);
        msgqlname char(10);
        keepentry char(3);
    end-pi;
    dcl-s formattedOmitDates char(512);
    dcl-s scddateparm char(10);
    dcl-s logsts char(1); // T: Log Title  C: Log Continue  E: Log Ending
    dcl-s logtxt char(1500);
    dcl-s errcnt packed(5:0);
    //
    logsts = 'C';
    logtxt = 'Prepare command for add job scheduled entry...' + %trim(scdjobname);
    writelog(logsts : logtxt);
    //
    cmdstr = 'ADDJOBSCDE'
              + ' JOB(' + %trim(scdjobname) + ')'
              + ' CMD(' + %trim(cmd) + ')'
              + ' FRQ(' + %trim(frequency) + ')';
    if scddatev = 'SCHEDULED_DATE';
        cmdstr = %trimr(cmdstr) + ' SCDDATE(' + %scanrpl('/' : '' : %trim(scddate)) + ') ';
    elseif scddatev = 'SCHEDULED_DAYS';
        cmdstr = %trimr(cmdstr) + ' SCDDAY(' + %scanrpl(',' : ' ' : %trim(scddays)) + ') ';
        scddateparm = '*NONE';
        cmdstr = %trimr(cmdstr) + ' SCDDATE(' + %trim(scddateparm) + ') ';
    else;
        scddateparm = %trim(scddatev);
        cmdstr = %trimr(cmdstr) + ' SCDDATE(' + %trim(scddateparm) + ') ';
    endif;
    cmdstr = %trimr(cmdstr) + ' SCDTIME(' + %scanrpl(':' : '' : %char(scdtime)) + ') ';
    if %trim(keepentry) <> '';
        cmdstr = %trimr(cmdstr) + ' SAVE(*' + %trim(keepentry) + ')';
    endif;
    if %trim(reldaysmon) <> '';
        cmdstr = %trimr(cmdstr) + ' RELDAYMON(' + %trim(reldaysmon) + ')';
    endif;        
    if %trim(jobdlname) = '';
        cmdstr = %trimr(cmdstr) + ' JOBD(' + %trim(jobdname) + ')';
    else;
        cmdstr = %trimr(cmdstr) + ' JOBD(' + %trim(jobdlname) + '/' + %trim(jobdname) + ')';
    endif;
    if %trim(jobqlname) = '';
        cmdstr = %trimr(cmdstr) + ' JOBQ(' + %trim(jobqname) + ')';
    else;
        cmdstr = %trimr(cmdstr) + ' JOBQ(' + %trim(jobqlname) + '/' + %trim(jobqname) + ')';
    endif;
    if %trim(msgqlname) = '';
        cmdstr = %trimr(cmdstr) + ' MSGQ(' + %trim(msgqname) + ')';
    else;
        cmdstr = %trimr(cmdstr) + ' MSGQ(' + %trim(msgqlname) + '/' + %trim(msgqname) + ')';
    endif;
    if %trim(datesomit) <> '';
        formattedOmitDates = ProcessOmitDates(datesomit);
        cmdstr = %trimr(cmdstr) + ' OMITDATE(' + %trim(formattedOmitDates) + ')';
    endif;
    if %trim(description) <> '';
        cmdstr = %trimr(cmdstr) + ' TEXT(''' + %trim(description) + ''')';
    endif;
    cmdstr = %trimr(cmdstr)
              + ' RCYACN(' + %trim(recovery) + ')'
              + ' USER(' + %trim(usrprf_sbmjob) + ')';
    return;
end-proc;

dcl-proc execute_cmd;
    dcl-pi *n;
        cmdstr char(800);
        errcount packed(5:0);
    end-pi;
    dcl-pr syscmd int(10) ExtProc('system');
        *n Pointer Value Options(*String);
    end-pr;
    dcl-s ReturnCode int(10);
    //
    logsts = 'C';
    logtxt = 'Execute add job scheduled entry...';
    writelog(logsts : logtxt);
    //
    ReturnCode = syscmd(cmdstr);
    If ReturnCode <> 0;
        errcount += 1;
        logsts = 'C';
        logtxt = '*** ERROR *** : Add scheduled job error'; 
        writelog(logsts : logtxt);
        logsts = 'C';
        logtxt = '-- ' + %trim(cmdstr); 
        writelog(logsts : logtxt);
    endif;
    return;   
end-proc;

dcl-proc hold_jobscd;
    dcl-pi *n;
        scdjobname char(10);
        scdentryno packed(6:0);
        errcount packed(5:0);
    end-pi;
    dcl-pr syscmd int(10) ExtProc('system');
        *n Pointer Value Options(*String);
    end-pr;
    dcl-s ReturnCode int(10);
    dcl-s cmdstr char(800);
    //
    logsts = 'C';
    logtxt = 'Execute hold job scheduled entry...';
    writelog(logsts : logtxt);
    //
    cmdstr = 'HLDJOBSCDE JOB(' + %trim(scdjobname) + ') ENTRYNBR(' + %char(%editc(scdentryno : 'X')) + ')';
    ReturnCode = syscmd(cmdstr);
    If ReturnCode <> 0;
        errcount += 1;
        logsts = 'C';
        logtxt = '*** ERROR *** : Hold scheduled job error'; 
        writelog(logsts : logtxt);
        logsts = 'C';
        logtxt = '-- ' + %trim(cmdstr); 
        writelog(logsts : logtxt);
    endif;
    return;   
end-proc;

dcl-proc delete_jobscd;
    dcl-pi *n;
        scdjobname char(10);
        scdentryno packed(6:0);
        errcount packed(5:0);
    end-pi;
    dcl-pr syscmd int(10) ExtProc('system');
        *n Pointer Value Options(*String);
    end-pr;
    dcl-s ReturnCode int(10);
    dcl-s cmdstr char(800);
    //
    logsts = 'C';
    logtxt = 'Execute remove job scheduled entry...';
    writelog(logsts : logtxt);
    //
    cmdstr = 'RMVJOBSCDE JOB(' + %trim(scdjobname) + ') ENTRYNBR(' + %char(%editc(scdentryno : 'X')) + ')';
    ReturnCode = syscmd(cmdstr);
    If ReturnCode <> 0;
        errcount += 1;
        logsts = 'C';
        logtxt = '*** ERROR *** : Remove scheduled job error';
        writelog(logsts : logtxt);
        logsts = 'C';
        logtxt = '-- ' + %trim(cmdstr);
        writelog(logsts : logtxt);
    endif;
    return;
end-proc;

dcl-proc writelog;
    dcl-pi *n;
        logsts char(1); // T: Log Title  C: Log Continue  E: Log Ending
        logtxt char(1500);
    end-pi;
    dcl-s cur_date date;
    dcl-s cur_time time;
    dcl-s cur_sysnm char(8) static;
    dcl-s logLocation char(200) static;
    //
    exec sql values(current_date) into :cur_date;
    exec sql values(current_time) into :cur_time;
    if %len(%trim(cur_sysnm)) = 0;
        exec sql values current server into :cur_sysnm;
    endif;
    if %len(%trim(logLocation)) = 0;
        logLocation = '/home/addjobscdn' + 
                        '_' + %trim(%scanrpl('-' : '' : %char(cur_date))) + 
                        '_' + %trim(%scanrpl('.' : '' : %char(cur_time))) + '.log';
    endif;
    select;
        when logsts = 'T';
            exec sql call QSYS2.IFS_WRITE_UTF8(trim(:logLocation),
                            '',
                            OVERWRITE => 'REPLACE',
                            END_OF_LINE => 'NONE');
            if %len(%trim(logtxt)) = 0;
                logtxt = '--- Process start ---';
            endif;
            exec sql call QSYS2.IFS_WRITE_UTF8(trim(:logLocation), 
                            ' ' || trim(char(:cur_date)) ||
                            ' ' || trim(char(:cur_time)) ||
                            ' ' || trim(:cur_sysnm) ||
                            ' ' || trim(:logtxt), 
                            END_OF_LINE => 'CRLF');
        when logsts = 'C';
            if %len(%trim(logtxt)) = 0;
                logtxt = '--- Process continue ---';
            endif;
            exec sql call QSYS2.IFS_WRITE_UTF8(trim(:logLocation), 
                            ' ' || trim(char(:cur_date)) ||
                            ' ' || trim(char(:cur_time)) ||
                            ' ' || trim(:cur_sysnm) ||
                            ' ' || trim(:logtxt), 
                            OVERWRITE => 'APPEND',
                            END_OF_LINE => 'CRLF');
        when logsts = 'E';
            if %len(%trim(logtxt)) = 0;
                logtxt = '--- Process finished ---';
            endif;
            exec sql call QSYS2.IFS_WRITE_UTF8(trim(:logLocation), 
                            ' ' || trim(char(:cur_date)) ||
                            ' ' || trim(char(:cur_time)) ||
                            ' ' || trim(:cur_sysnm) ||
                            ' ' || trim(:logtxt), 
                            OVERWRITE => 'APPEND',
                            END_OF_LINE => 'CRLF');
        other;
            snd-msg 'Write Log failed.';
    endsl;
    return;
end-proc;

dcl-proc dlyjob;
    dcl-s cmdstr char(800);
    cmdstr = 'DLYJOB DLY(2)';
    exec sql call qsys2.qcmdexc(:cmdstr);
    return;
end-proc;

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