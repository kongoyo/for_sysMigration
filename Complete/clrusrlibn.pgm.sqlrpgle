**FREE
// CALL PGM(STEVE/CLRUSRLIBN) PARM(('*ALLUSR'))
// parameter: *ALL *ALLUSR or specific library
//
ctl-opt option(*srcstmt) dftactgrp(*no);

Dcl-Pi *N;
    exe_schema char(10) const;
End-Pi;
dcl-ds liblst qualified;
    objname char(10);
end-ds;
dcl-s logsts char(1); // T: Log Title  C: Log Continue  E: Log Ending
dcl-s logtxt char(1500);
dcl-s rpyoption char(3);
dcl-s cmdstr char(500);
dcl-s returnCode int(5);
dcl-s stmt char(1500);

// Main procedure
clear logtxt;
logsts = 'T';
writelog(logsts : logtxt);

clear logtxt;
logsts = 'C';
logtxt = 'Process clear user libraries start';
writelog(logsts : logtxt);

clear logtxt;
logsts = 'C';
logtxt = '------------------------------';
writelog(logsts : logtxt);
//
rpyoption = 'STR';
for_reply_List(rpyoption);

// Generate db_relatiion_table
exec sql set option commit = *none;

clear stmt;
stmt = 'drop table qtemp.pfdbr if exists';
exec sql prepare prepfdbr from :stmt;
exec sql execute prepfdbr;

clear cmdstr;
cmdstr = 'DSPDBR FILE(*ALLUSR/*ALL) OUTPUT(*OUTFILE) OUTFILE(QTEMP/PFDBR)';
process_Command(cmdstr:returnCode);

clear stmt;
stmt = 'drop table qtemp.pfdbrlst if exists';
exec sql prepare prepfdbrlst from :stmt;
exec sql execute prepfdbrlst;

clear stmt;
stmt = 'create table qtemp.pfdbrlst as ' +
        '( select whsysn, whrli, whreli ' + 
        'from qtemp.pfdbr ' +
        'where whreli <> '''' and ' +
        'whrli not like ''Q%'' and ' +
        'whrli not like ''SYS%'' and ' +        
        'whreli <> whrli ) with data';
exec sql prepare precrtdbrlst from :stmt;
exec sql execute precrtdbrlst;

// Get Library Name
snd-msg '***** Get Library Name *****';

clear stmt;
stmt = 'select ' +
           'coalesce(objname, '''') as objname ' +
           'from table (qsys2.object_statistics(' +
           'object_schema => ''' + %trim(%upper(exe_schema)) + ''', objtypelist => ''*LIB''' +
           '))';
exec sql prepare preliblst from :stmt;
exec sql declare liblst cursor for preliblst;
exec sql open liblst;
exec sql fetch from liblst into :liblst;
dow sqlcod = 0;
    if sqlcod = 0;
        if liblst.objname <> '#COBLIB' and
                liblst.objname <> '#LIBRARY' and
                liblst.objname <> '#RPGLIB' and
                %scan('Q' : liblst.objname : 1) <> 1 and
                liblst.objname <> 'SYSIBM' and
                liblst.objname <> 'SYSIBMADM' and
                liblst.objname <> 'SYSPROC' and
                liblst.objname <> 'SYSTOOLS' and
                %scan('DDSCINFO' : liblst.objname : 1) <> 1 and
                %scan('RMT' : liblst.objname : 1) <> 1 and
                %scan('HOYA' : liblst.objname : 1) <> 1 and
                %scan('PMEDH' : liblst.objname : 1) <> 1 and 
                %scan('SGKGISN' : liblst.objname : 1) <> 1 and
                %scan('FUKGISN' : liblst.objname : 1) <> 1 and
                %scan('OSKGISN' : liblst.objname : 1) <> 1 and  
                %scan('VCKGISN' : liblst.objname : 1) <> 1 and 
                %scan('FEKGISN' : liblst.objname : 1) <> 1;

            // snd-msg %trim(liblst.objname);
            check_db_relation(liblst.objname);
            
        endif;
        exec sql fetch from liblst into :liblst.objname;
    endif;
enddo;
exec sql close liblst;

rpyoption = 'END';
for_reply_List(rpyoption);

clear logtxt;
logsts = 'C';
logtxt = '------------------------------';
writelog(logsts : logtxt);

clear logtxt;
logsts = 'C';
logtxt = 'Process clear user libraries end';
writelog(logsts : logtxt);

clear logtxt;
logsts = 'E';
writelog(logsts : logtxt);

*inlr = *on;
return;

dcl-proc check_db_relation;
    dcl-pi *n;
        exe_schema char(10);
    end-pi;
    dcl-ds pflst qualified;
        whrli char(10);
        whreli char(10);
    end-ds;
    dcl-ds whreli likeds(pflst);
    dcl-s stmt char(1500);

    // snd-msg 'check_db_relation: ' + %trim(exe_schema);
    clear stmt;
    stmt = 'select distinct whrli, whreli ' + 
            'from qtemp.pfdbrlst ' +
            'where whrli = ? ';
    exec sql prepare prepflst from :stmt;
    exec sql declare pflst cursor for prepflst;
    exec sql open pflst using :exe_schema;
    exec sql fetch from pflst into :pflst;
    dow sqlcod = 0;
        if sqlcod = 0;
            clear_usrlib(pflst.whreli);
            exec sql fetch from pflst into :pflst;
        endif;
    enddo;
    exec sql close pflst;

    clear stmt;
    stmt = 'select distinct whrli, whreli ' + 
            'from qtemp.pfdbrlst ' +
            'where whreli = ? ';
    exec sql prepare prewhreli from :stmt;
    exec sql declare whreli cursor for prewhreli;
    exec sql open whreli using :exe_schema;
    exec sql fetch from whreli into :whreli;
    if sqlcod <> 0;
        clear_usrlib(exe_schema);
        exec sql fetch from whreli into :whreli;
    endif;
    exec sql close whreli;
    // clear_usrlib(exe_schema);

    return;
end-proc;

dcl-proc for_reply_List;
    dcl-pi *n;
        option char(3);
    end-pi;
    dcl-pr syscmd int(10) ExtProc('system');
        *n Pointer Value Options(*String);
    end-pr;
    dcl-s rplylst_seqnum char(10) static;
    dcl-s rplylst_msgid char(7) static;
    dcl-s rplylst_reply varchar(32) static;
    dcl-s cmdstr char(500);
    dcl-s returnCode int(5);
    // change job to log msg
    cmdstr = 'CHGJOB LOG(4 00 *MSG) LOGCLPGM(*YES) INQMSGRPY(*SYSRPYL)';
    returnCode = syscmd(cmdstr);
    // If it doesn't exist, add it to auto-reply with 'I' (Ignore)
    select;
        when option = 'STR';
            // Check if reply list entry for CPA7025 exists
            exec sql drop table qtemp.replylst if exists;
            exec sql create table qtemp.replylst as (
                        Select cast(sequence_number as char(10)) as sequence_number,
                                message_id, message_reply
                        From qsys2.reply_list_info
                        Where message_id in ('CPA7025')) with data;
            if sqlcod = 0;
                exec sql select sequence_number, message_id, message_reply
                    into :rplylst_seqnum, :rplylst_msgid, :rplylst_reply
                    from qtemp.replylst
                    fetch first 1 row only;
                if sqlcod = 0;
                    snd-msg 'Before: ' + %trim(rplylst_reply);
                    clear cmdstr;
                    cmdstr = 'CHGRPYLE SEQNBR(' + %trim(rplylst_seqnum) + 
                                ') MSGID(*SAME) RPY(I)';
                    returnCode = syscmd(cmdstr);
                else;
                    clear cmdstr;
                    cmdstr = 'ADDRPYLE SEQNBR(9898) MSGID(CPA7025) RPY(I)';
                    returnCode = syscmd(cmdstr);
                endif;
            endif;
        when option = 'END';
            // Check if reply list entry for CPA7025 exists
            exec sql select sequence_number, message_id, message_reply
                    into :rplylst_seqnum, :rplylst_msgid, :rplylst_reply
                    from qtemp.replylst
                    fetch first 1 row only;
            if sqlcod =0;                    
                clear cmdstr;
                snd-msg 'After: ' + %trim(rplylst_reply);
                cmdstr = 'CHGRPYLE SEQNBR(' + %trim(rplylst_seqnum) + 
                            ') MSGID('+ %trim(rplylst_msgid) +
                            ') RPY(' + %trim(rplylst_reply) + ')';
                returnCode = syscmd(cmdstr);
            else; 
                clear cmdstr;
                cmdstr = 'RMVRPYLE SEQNBR(9898)';
                returnCode = syscmd(cmdstr);
            endif;
        other;
    endsl;

    return;
end-proc;

dcl-proc clear_usrlib;
    dcl-pi *n;
        exe_schema char(10);
    end-pi;
    dcl-ds objlst qualified;
        objname char(10);
    end-ds;
    dcl-s stmt char(1500);
    dcl-s cmdstr char(500);
    dcl-s returnCode int(5);

    clear stmt;
    stmt = 'select ' +
                'coalesce(objname, '''') as objname ' +
                'from table (qsys2.object_statistics(' +
                'object_schema => ''' + %trim(exe_schema) + ''', ' + 
                'objtypelist => ''*JRN''))';
    exec sql prepare preobjlst from :stmt;
    exec sql declare objlst cursor for preobjlst;
    exec sql open objlst;
    exec sql fetch from objlst into :objlst;
                //
    dow sqlcod = 0;
        if sqlcod = 0;
                    // Process Journals & receivers
            clear cmdstr;
            cmdstr = 'ENDJRNPF FILE(*ALL) ' +
                                    'JRN(' + %trim(exe_schema) + 
                                    '/' + %trim(objlst.objname) + ')';
            process_Command(cmdstr:returnCode);
            exec sql fetch from objlst into :objlst.objname;
        endif;
    enddo;
    exec sql close objlst;
                // Process Clear Library
    clear cmdstr;
    cmdstr = 'CLRLIB LIB(' + %trim(exe_schema) + ')';
    process_Command(cmdstr:returnCode);

    clear cmdstr;
    cmdstr = 'DLTLIB LIB(' + %trim(exe_schema) + ')';
    process_Command(cmdstr:returnCode);

    return;
end-proc;

dcl-proc process_Command;
    dcl-pi *n;
        cmdstr char(500);
        returnCode int(5);
    end-pi;
    dcl-s composedCmd char(600);
    dcl-pr syscmd int(10) ExtProc('system');
        *n Pointer Value Options(*String);
    end-pr;

    // composedCmd = 'SBMJOB CMD(' + %trim(cmdstr) + ') ' +                
    //                 'JOB(*JOBD) ' +             
    //                 'LOG(*JOBD *JOBD *SECLVL) ' +
    //                 'LOGCLPGM(*YES) ' +          
    //                 'JOBMSGQFL(*PRTWRAP) ' +     
    //                 'INQMSGRPY(*SYSRPYL)';
    if %scan('DSPDBR' : %trim(cmdstr) : 1) = 1;
        composedCmd = %trim(cmdstr);
        returnCode = syscmd(composedCmd);
    else;
        composedCmd = 'SBMJOB CMD(' + %trim(cmdstr) + ') ' +                
                    'JOB(*JOBD) ' +             
                    'LOG(*JOBD *JOBD *SECLVL) ' +
                    'LOGCLPGM(*YES) ' +          
                    'JOBMSGQFL(*PRTWRAP) ' +     
                    'INQMSGRPY(*SYSRPYL)';
    endif;
    // returnCode = syscmd(composedCmd);
    clear logtxt;
    logsts = 'C';
    logtxt = 'Command: ' + %trim(composedCmd);
    writelog(logsts : logtxt);
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
        logLocation = '/home/clrusrlibn' +
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
