**FREE
ctl-opt option(*srcstmt) dftactgrp(*no);
// user-input parameter - Tape device name
dcl-pi *n;
    tapdev char(10);
end-pi;
//
dcl-s logsts char(1); // T: Log Title  C: Log Continue  E: Log Ending
dcl-s logtxt char(500);
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
rstusr(tapdev);
//
logsts = 'C';
logtxt = 'Restore User profiles end';
writelog(logsts : logtxt);

logsts = 'C';
logtxt = 'Restore User libraries start';
writelog(logsts : logtxt);
//
rstlib(tapdev);
//
logsts = 'C';
logtxt = 'Restore User libraries end';
writelog(logsts : logtxt);

clear logtxt;
logsts = 'E';
writelog(logsts : logtxt);

*inlr = *on;
return;

dcl-proc rstusr;
    dcl-pi *n;
        tapdev char(8);
    end-pi;
    dcl-pr syscmd int(10) ExtProc('system');
        *n Pointer Value Options(*String);
    end-pr;   
    dcl-s cmdstr char(512);
    dcl-s returnCode int(5);
    dcl-s stmt char(200);
    dcl-s logsts char(1); // T: Log Title  C: Log Continue  E: Log Ending
    dcl-s logtxt char(500);
    //
    dcl-ds usrsavinf qualified;
        objname varchar(10);
        save_volume varchar(71);
        save_seqnum packed(11:0);
    end-ds;
    dcl-ds users qualified;
        odobnm char(10);
    end-ds;
    dcl-s usraut char(200);
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
                    logtxt = '- Process user profile:' + %trim(users.odobnm);
                    writelog(logsts : logtxt);
                    // Restore *usrprf
                    cmdstr = '  RSTUSRPRF DEV(' + %trim(tapdev) +
                            ') USRPRF(' + %trim(usrsavinf.objname) +
                            ') VOL(' + %trim(usrsavinf.save_volume) +
                            ') SEQNBR(' + %trim(%char(usrsavinf.save_seqnum)) +
                            ') ALWOBJDIF(*ALL) SECDTA(*USRPRF)';
                    // exec sql call qsys2.qcmdexc(:cmdstr);
                    logsts = 'C';
                    logtxt = '-   Restore *USRPRF: ';
                    writelog(logsts : logtxt);
                    logtxt = '-     ' + %trim(cmdstr);
                    writelog(logsts : logtxt);
                    // Restore *pvtaut
                    cmdstr = '  RSTUSRPRF DEV(' + %trim(tapdev) +
                            ') USRPRF(' + %trim(usrsavinf.objname) +
                            ') VOL(' + %trim(usrsavinf.save_volume) +
                            ') SEQNBR(' + %trim(%char(usrsavinf.save_seqnum)) +
                            ') ALWOBJDIF(*ALL) SECDTA(*PVTAUT)';
                    // exec sql call qsys2.qcmdexc(:cmdstr);
                    logsts = 'C';
                    logtxt = '-   Restore *PVTAUT: ';
                    writelog(logsts : logtxt);
                    logtxt = '-     ' + %trim(cmdstr);
                    writelog(logsts : logtxt);
                    // Restore *pwdgrp
                    cmdstr = 'RSTUSRPRF DEV(' + %trim(tapdev) +
                            ') USRPRF(' + %trim(usrsavinf.objname) +
                            ') VOL(' + %trim(usrsavinf.save_volume) +
                            ') SEQNBR(' + %trim(%char(usrsavinf.save_seqnum)) +
                            ') ALWOBJDIF(*ALL) SECDTA(*PWDGRP)';
                    // exec sql call qsys2.qcmdexc(:cmdstr);
                    logsts = 'C';
                    logtxt = '-   Restore *PWDGRP: ';
                    writelog(logsts : logtxt);
                    logtxt = '-     ' + %trim(cmdstr);
                    writelog(logsts : logtxt);
                    // Add user to the list for authority restore
                    usraut = %trimr(usraut) + ' ' + %trim(usrsavinf.objname);
                    // After every 10 users, restore their authorities
                    if %rem(count : 10) = 0;
                        if %len(%trim(usraut)) > 0;
                            cmdstr = 'RSTAUT USRPRF(' + %trim(usraut) + ')';
                            // exec sql call qsys2.qcmdexc(:cmdstr);
                            logsts = 'C';
                            logtxt = '-   Restore authority: ';
                            writelog(logsts : logtxt);
                            logtxt = '-     ' + %trim(cmdstr);
                            writelog(logsts : logtxt);
                            clear usraut;
                        endif;
                    endif;
                endif;
            endif;
        endif;
        exec sql fetch next from curusrlst into :users.odobnm;
    enddo;
    // Process the final batch of users that were not a multiple of 10
    if %len(%trim(usraut)) > 0;
        cmdstr = 'RSTAUT USRPRF(' + %trim(usraut) + ')';
        // exec sql call qsys2.qcmdexc(:cmdstr);
        clear logtxt;
        logsts = 'C';
        logtxt = '-   Restore authority (Final): ';
        writelog(logsts : logtxt);
        logtxt = '-     ' + %trim(cmdstr);
        writelog(logsts : logtxt);
    endif;
    exec sql close curusrlst;
    return;
end-proc;

dcl-proc rstlib;
    dcl-pi *n ;
        tapdev char(8);
    end-pi;
    dcl-pr syscmd int(10) ExtProc('system');
        *n Pointer Value Options(*String);
    end-pr;   
    dcl-s cmdstr char(512);
    dcl-s returnCode int(5);
    dcl-s stmt char(200);
    dcl-s logsts char(1); // T: Log Title  C: Log Continue  E: Log Ending
    dcl-s logtxt char(500);
    dcl-s cur_sysnm char(8);
    dcl-s ap_lib char(500);
    dcl-s omit_lib char(100) static;
    dcl-s objnm char(30);
    dcl-s option char(1);
    dcl-s volumeid char(6);
    // initial variable
    omit_lib = '#LIBRARY DDSCINFO HOYA* ' +
               'PMEDH* RMT* Q* SYSIBM SYSIBMADM SYSPROC SYSTOOLS ';
    if %len(%trim(cur_sysnm)) = 0;
        exec sql values current server into :cur_sysnm;
    endif;
    // for Test only
    cur_sysnm = 'AS101N';
    logsts = 'C';
    logtxt = '* Current System is ' + %trim(cur_sysnm) + '.';
    writelog(logsts : logtxt);
    // Restore according to current system name
    select;
        // volume: 101Y25 & F02Y25
        when %trim(cur_sysnm) = 'AS101N';
            // initial variable
            clear ap_lib;
            // Begin
            option = '1';
            volumeid = '101Y25';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);

            option = '5';
            volumeid = '101Y25';
            objnm = '$INFRA';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);

            option = '5';
            volumeid = '101Y25';
            objnm = 'CCI';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);

            option = '5';
            volumeid = '101Y25';
            objnm = 'MONLIB';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);

            option = '5';
            volumeid = '101Y25';
            objnm = 'OCEANTOOLS';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);

            option = '5';
            volumeid = '101Y25';
            objnm = 'SMSLIB';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);

            option = '2';
            volumeid = 'F02Y25';
            ap_lib = 'KCOFCMTF KCOFCMTT KCOFITN KCOFPRC ' +
                     'KCOFUSR KCOFSCRT KSOFFINA KSOFFINF ' +
                     'KSOFFINFVR KSOFFIXF KSUSER FU1000427 ' +
                     'FUCOMM SMTPSPL S007389 GZIP';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);

            option = '4';
            volumeid = 'F02Y25';
            objnm = 'PTM0000P PTM0000D';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);

            option = '3';
            volumeid = 'F02Y25';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);

        // volume: F03Y25 & F04Y25
        when %trim(cur_sysnm) = 'KSF03N';
        // volume: G01Y25 & 800Y25 & 500Y25 & 052Y25
        when %trim(cur_sysnm) = 'KSG01N';
        // volume: G01Y25 & 500Y25 & 800Y25 & 052Y25
        when %trim(cur_sysnm) = 'AS081N';
        other;
            logsts = 'C';
            logtxt = '*** System is not in the scheduled list ***';
            writelog(logsts : logtxt);
    endsl;
    return;
end-proc;

dcl-proc rstaction;
    dcl-pi *n;
        option char(1);
        cur_sysnm char(8);
        tapdev char(8);
        volumeid char(6);
        ap_lib char(500);
        omit_lib char(100);
        objnm char(30);
    end-pi;
    dcl-s cmdstr char(512);
    dcl-s returnCode int(5);
    dcl-s stmt char(200);
    dcl-s sysnm_length packed(5:0);
    dcl-s objnm_length packed(5:0);
    dcl-s startPos packed(5:0);
    dcl-s strLength packed(5:0);

    //
    select;
        when option = '1'; // Restore system *allusr library
            cmdstr = 'RSTLIB SAVLIB(*ALLUSR) ' +
                     'DEV(' + %trim(tapdev) + ') ' +
                     'VOL(' + %trim(volumeid) + ') OMITLIB(' + %trim(omit_lib) + ') ' +
                     'OPTION(*NEW) MBROPT(*ALL) ALWOBJDIF(*ALL) OUTPUT(*PRINT)';
            logsts = 'C';
            logtxt = '-   Restore Major system *allusr libraries: ';
            writelog(logsts : logtxt);
            logtxt = '-     ' + %trim(cmdstr);
            writelog(logsts : logtxt);

        when option = '2'; // Restore minor system AP library
            cmdstr = 'RSTLIB SAVLIB(' + %trim(ap_lib) + ') '+
                     'DEV(' + %trim(tapdev) + ') ' +
                     'VOL(' + %trim(volumeid) + ') ' +
                     'OPTION(*NEW) MBROPT(*ALL) ALWOBJDIF(*ALL) OUTPUT(*PRINT)';
            logsts = 'C';
            logtxt = '-   Restore Minor system AP libraries: ';
            writelog(logsts : logtxt);
            logtxt = '-     ' + %trim(cmdstr);
            writelog(logsts : logtxt);

        when option = '3'; // Restore minor system other library
            cmdstr = 'RSTLIB SAVLIB(*ALLUSR) '+
                     'DEV(' + %trim(tapdev) + ') ' +
                     'VOL(' + %trim(volumeid) + ') OMITLIB(' + %trim(omit_lib) + ') ' +
                     'OPTION(*NEW) MBROPT(*ALL) ALWOBJDIF(*ALL) OUTPUT(*PRINT)';
            logsts = 'C';
            logtxt = '-   Restore Minor system other libraries: ';
            writelog(logsts : logtxt);
            logtxt = '-     ' + %trim(cmdstr);
            writelog(logsts : logtxt);

        when option = '4'; // Restore QGPL specific object
            cmdstr = 'RSTOBJ OBJ(' + %trim(objnm) + ') SAVLIB(QGPL) ' +
                     'DEV(' + %trim(tapdev) + ') ' +
                     'VOL(' + %trim(volumeid) + ') ' +
                     'OPTION(*NEW) MBROPT(*ALL) ' +
                     'ALWOBJDIF(*ALL) OUTPUT(*PRINT)';
            logsts = 'C';
            logtxt = '-   Restore QGPL specific object: ';
            writelog(logsts : logtxt);
            logtxt = '-     ' + %trim(cmdstr);
            writelog(logsts : logtxt);

        when option = '5'; // Rename specific library name
            clear objnm_length;
            clear sysnm_length;
            clear strLength;
            clear startPos;
            objnm_length = %len(%trim(objnm));
            sysnm_length = %len(%trim(cur_sysnm));
            if objnm_length > sysnm_length;
                strLength = 3;
            else;
                strLength = 10 - objnm_length;
                if strLength > sysnm_length;
                    strLength = sysnm_length;
                endif;
            endif;
            startPos = 6 - strLength + 1;
            cmdstr = 'RNMOBJ OBJ(QSYS/' + %trim(objnm) +
                    ') OBJTYPE(*LIB) NEWOBJ(' + %trim(objnm) +
                    %subst(%trim(cur_sysnm) : startPos : strLength - 1) + ')';
            logsts = 'C';
            logtxt = '-   Rename Major system specific libraries: ';
            writelog(logsts : logtxt);
            logtxt = '-     ' + %trim(cmdstr);
            writelog(logsts : logtxt);
        other;
    endsl;
    return;
end-proc;

dcl-proc writelog;
    dcl-pi *n;
        logsts char(1); // T: Log Title  C: Log Continue  E: Log Ending
        logtxt char(500);
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
    return;
end-proc;

dcl-proc dlyjob;
    dcl-s cmdstr char(512);
    cmdstr = 'DLYJOB DLY(2)';
    exec sql call qsys2.qcmdexc(:cmdstr);
    return;
end-proc;
