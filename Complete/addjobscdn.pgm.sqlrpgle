**FREE
// CALL PGM(STEVE/ADDJOBSCDN)
// writelog(logsts : logtxt);
//   logsts T : Log Title
//   logsts C : Log Continue
//   logsts E : Log Ending
//
ctl-opt option(*srcstmt) dftactgrp(*no);
//
dcl-pi *n;
    libnm char(10);
    filenm char(10);
end-pi;
//
dcl-s logsts char(1); // T: Log Title  C: Log Continue  E: Log Ending
dcl-s logtxt char(600);
// Main procedure
clear logtxt;
logsts = 'T';
writelog(logsts : logtxt);

logsts = 'C';
logtxt = 'Add Job scheduled start';
writelog(logsts : logtxt);

read_from_file(libnm : filenm);

logsts = 'C';
logtxt = 'Add Job scheduled end';
writelog(logsts : logtxt);

clear logtxt;
logsts = 'E';
writelog(logsts : logtxt);
*inlr = *on;
return;

dcl-proc read_from_file;
    dcl-pi *n;
        libnm char(10);
        filenm char(10);
    end-pi;
    dcl-ds scdjob extname('QSYS2/SCHED_JOB') qualified;
    end-ds;
    dcl-s stmt char(1000);
    //
    stmt = 'SELECT ' +
            'SCHEDULED_JOB_ENTRY_NUMBER, ' +
            'SCHEDULED_JOB_NAME, ' +
            'SCHEDULED_DATE_VALUE, ' +
            'coalesce(SCHEDULED_DATE,''1940-01-01'') as SCHEDULED_DATE, ' +
            'SCHEDULED_TIME, ' +
            'coalesce(SCHEDULED_DAYS,'''') as SCHEDULED_DAYS, ' +
            'FREQUENCY, ' +
            'coalesce(RELATIVE_DAYS_OF_MONTH,'''') as RELATIVE_DAYS_OF_MONTH, ' +
            'RECOVERY_ACTION, ' +
            'STATUS, ' +
            'JOB_QUEUE_NAME, ' +
            'JOB_QUEUE_LIBRARY_NAME, ' +
            'DATES_OMITTED, ' +
            'DESCRIPTION, ' +
            'COMMAND_STRING, ' +
            'USER_PROFILE_FOR_SUBMITTED_JOB, ' +
            'JOB_DESCRIPTION_NAME, ' +
            'JOB_DESCRIPTION_LIBRARY_NAME, ' +
            'MESSAGE_QUEUE_NAME, ' +
            'MESSAGE_QUEUE_LIBRARY_NAME, ' +
            'KEEP_ENTRY ' +
            'FROM ' + %trim(libnm) + '.' + %trim(filenm);
    snd-msg %trim(stmt);
    //
    exec sql prepare prescdjob from :stmt;
    exec sql declare scdjob cursor for prescdjob;
    exec sql open scdjob;
    exec sql fetch next from scdjob into :scdjob;
    dow sqlcod = 0;
        if sqlcod = 0;
            snd-msg scdjob.scdjobname;
        endif;
        exec sql fetch next from scdjob into :scdjob;
    enddo;
    exec sql close scdjob;
    return;
end-proc;

// dcl-proc prepare_cmd;
//     dcl-ds scdjobinf extname('QSYS2/SCHED_JOB') qualified;
//     end-ds;
//     dcl-s cmdstr char(800);
//     dcl-s logsts char(1); // T: Log Title  C: Log Continue  E: Log Ending
//     dcl-s logtxt char(600);
    

// end-proc;

dcl-proc writelog;
    dcl-pi *n;
        logsts char(1); // T: Log Title  C: Log Continue  E: Log Ending
        logtxt char(600);
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
