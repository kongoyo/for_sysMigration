**FREE
ctl-opt option(*srcstmt) dftactgrp(*no);
// user-input parameter - Tape device name
dcl-pi *n;
    tapdev char(10);
end-pi;
//
dcl-s logsts char(1); // T: Log Title  C: Log Continue  E: Log Ending
dcl-s logtxt char(200);
// Gather required information
tapdev = %upper(%trim(tapdev));
// Main procedure
clear logtxt;
logsts = 'T';
writelog(logsts : logtxt);

logsts = 'C';
logtxt = 'Restore User profiles start';
writelog(logsts : logtxt);
//
rstexsusr(tapdev);
//
logsts = 'C';
logtxt = 'Restore User profiles end';
writelog(logsts : logtxt);

logsts = 'C';
logtxt = 'Restore User libraries start';
writelog(logsts : logtxt);
//
// rstusrlib(%trim(tapdev));
//
logsts = 'C';
logtxt = 'Restore User libraries end';
writelog(logsts : logtxt);

clear logtxt;
logsts = 'E';
writelog(logsts : logtxt);

*inlr = *on;
return;

dcl-proc rstexsusr;
    dcl-pi *n;
        tapdev char(8);
    end-pi;
    dcl-ds usrsavinf qualified;
        objname varchar(10);
        save_volume varchar(71);
        save_seqnum packed(11:0);
    end-ds;
    dcl-ds users qualified;
        odobnm char(10);
    end-ds;
    dcl-pr syscmd int(10) ExtProc('system');
        *n Pointer Value Options(*String);
    end-pr;   
    dcl-s cmdstr char(512);
    dcl-s returnCode int(5);
    dcl-s usraut char(200);
    dcl-s stmt char(200);
    dcl-s logsts char(1); // T: Log Title  C: Log Continue  E: Log Ending
    dcl-s logtxt char(200);
    dcl-s count packed(5:0); // User count
    dcl-s isVolumeExist char(1);
    // initial variable
    count = 0;
    // Declare cursor for table qsys2.users()
    clear stmt;
    stmt = 'select odobnm from table(qsys2.users())';
    exec sql prepare preusrlst from :stmt;
    exec sql declare curusrlst cursor for preusrlst;
    exec sql open curusrlst;
    exec sql fetch next from curusrlst into :users.odobnm;

    dow sqlcod = 0;
        // Filter out system profiles (those starting with 'Q')
        if %scan('Q' : users.odobnm : 1) <> 1;
            exec sql select
                        coalesce(objname,'') as objname,
                        coalesce(save_volume,'') as save_volume,
                        coalesce(save_sequence_number,0) as save_seqnum
                    into :usrsavinf.objname, :usrsavinf.save_volume, :usrsavinf.save_seqnum
                    from table(qsys2.object_statistics(
                    object_schema => 'QSYS',
                    objtypelist => '*USRPRF',
                    object_name => trim(:users.odobnm))) ;
            // Action section: Only proceed if there is save media information
            if %trim(usrsavinf.save_volume) <> '' and 
                usrsavinf.save_seqnum <> 0;
                clear cmdstr;
                clear isVolumeExist;
                // Check if the correct tape volume is in the drive
                cmdstr = 'CHKTAP DEV(' + %trim(tapdev) +
                            ') VOL(' + %trim(usrsavinf.save_volume) +
                            ') SEQNBR(' + %trim(%char(usrsavinf.save_seqnum)) +
                            ') ENDOPT(*REWIND)';
                returnCode = syscmd(cmdstr);
                if returnCode = 0;
                    count += 1;
                    logsts = 'C';
                    logtxt = 'Process user profile:' + %trim(users.odobnm);
                    writelog(logsts : logtxt);
                    // Restore *usrprf
                    cmdstr = 'RSTUSRPRF DEV(' + %trim(tapdev) +
                            ') USRPRF(' + %trim(usrsavinf.objname) +
                            ') VOL(' + %trim(usrsavinf.save_volume) +
                            ') SEQNBR(' + %trim(%char(usrsavinf.save_seqnum)) +
                            ') ALWOBJDIF(*ALL) SECDTA(*USRPRF)';
                    exec sql call qsys2.qcmdexc(:cmdstr);
                    logsts = 'C';
                    logtxt = '1st Command: ' + %trim(cmdstr);
                    writelog(logsts : logtxt);
                    // Restore *pvtaut
                    cmdstr = 'RSTUSRPRF DEV(' + %trim(tapdev) +
                            ') USRPRF(' + %trim(usrsavinf.objname) +
                            ') VOL(' + %trim(usrsavinf.save_volume) +
                            ') SEQNBR(' + %trim(%char(usrsavinf.save_seqnum)) +
                            ') ALWOBJDIF(*ALL) SECDTA(*PVTAUT)';
                    exec sql call qsys2.qcmdexc(:cmdstr);
                    logsts = 'C';
                    logtxt = '2nd Command: ' + %trim(cmdstr);
                    writelog(logsts : logtxt);
                    // Restore *pwdgrp
                    cmdstr = 'RSTUSRPRF DEV(' + %trim(tapdev) +
                            ') USRPRF(' + %trim(usrsavinf.objname) +
                            ') VOL(' + %trim(usrsavinf.save_volume) +
                            ') SEQNBR(' + %trim(%char(usrsavinf.save_seqnum)) +
                            ') ALWOBJDIF(*ALL) SECDTA(*PWDGRP)';
                    exec sql call qsys2.qcmdexc(:cmdstr);
                    logsts = 'C';
                    logtxt = '3rd Command: ' + %trim(cmdstr);
                    writelog(logsts : logtxt);
                    // Add user to the list for authority restore
                    usraut = %trimr(usraut) + ' ' + %trim(usrsavinf.objname);
                    // After every 10 users, restore their authorities
                    if %rem(count : 10) = 0;
                        if %len(%trim(usraut)) > 0;
                            cmdstr = 'RSTAUT USRPRF(' + %trim(usraut) + ')';
                            exec sql call qsys2.qcmdexc(:cmdstr);
                            logsts = 'C';
                            logtxt = '4th Command: ' + %trim(cmdstr);
                            writelog(logsts : logtxt);
                            clear usraut;
                        endif;
                    endif;
                endif;
            endif;
            // If tape exists, proceed with restore
        endif;
        exec sql fetch next from curusrlst into :users.odobnm;
    enddo;

    // Process the final batch of users that were not a multiple of 10
    if %len(%trim(usraut)) > 0;
        cmdstr = 'RSTAUT USRPRF(' + %trim(usraut) + ')';
        exec sql call qsys2.qcmdexc(:cmdstr);
        logsts = 'C';
        logtxt = '4th Command (Final): ' + %trim(cmdstr);
        writelog(logsts : logtxt);
    endif;

    clear logtxt;
    logsts = 'E';
    writelog(logsts : logtxt);
    exec sql close curusrlst;
end-proc;

// dcl-proc rstusrlib;
//     //
//     // Log Title
//     logsts = 'T';
//     writelog(logsts : logtxt : cur_sysnm);
//     // Restore existing user profiles
//     rstexsusr(tapdev);
//     // Restore user libraries and omit specific libraries
//     // KSG01 & AS081: SGKGISN、OSKGISN、FUKGISN、VCKGISN、FEKGISN
//     // AS101 & KSF03: SGKGISN only
//     rstlib(cur_sysnm);
//     // Log Ending
//     logsts = 'E';
//     writelog(logsts : logtxt : cur_sysnm);
//     *inlr = *on;
//     return;
// end-proc;

// dcl-proc rstlib;
//     dcl-pi *n;
//         cur_sysnm char(8);
//     end-pi;
// end-proc;

dcl-proc writelog;
    dcl-pi *n;
        logsts char(1); // T: Log Title  C: Log Continue  E: Log Ending
        logtxt char(200);
    end-pi;
    dcl-s cur_date date;
    dcl-s cur_time time;
    dcl-s cur_sysnm char(8);
    dcl-s logLocation char(200) static;
    //
    exec sql values(current_date) into :cur_date;
    exec sql values(current_time) into :cur_time;
    if %len(%trim(cur_sysnm)) = 0;
        exec sql values current server into :cur_sysnm;
    endif;
    if %len(%trim(logLocation)) = 0;
        logLocation = '/home/rstusrlib' + 
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
end-proc;

dcl-proc dlyjob;
    dcl-s cmdstr char(512);
    cmdstr = 'DLYJOB DLY(2)';
    exec sql call qsys2.qcmdexc(:cmdstr);
end-proc;
