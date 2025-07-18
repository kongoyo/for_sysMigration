**FREE
// CALL PGM(STEVE/RSTUSRLIB) PARM(('TAPMLB01'))
// rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
//   option 1 : restore major system library
//     required parm : option : tapdev : volumeid : omit_lib
//   option 2 : restore minor system AP library
//     required parm : option : tapdev : volumeid : ap_lib
//   option 3 : restore minor system other library
//     required parm : option : tapdev : volumeid : omit_lib 
//   option 4 : restore QGPL specific object
//     required parm : option : tapdev : volumeid : objnm
//   option 5 : rename specific library name
//     required parm : option : cur_sysnm : objnm
//
// writelog(logsts : logtxt);
//   logsts T : Log Title
//   logsts C : Log Continue
//   logsts E : Log Ending
//
ctl-opt option(*srcstmt) dftactgrp(*no);
// user-input parameter - Tape device name
dcl-pi *n;
    tapdev char(10);
end-pi;
//
dcl-s logsts char(1); // T: Log Title  C: Log Continue  E: Log Ending
dcl-s logtxt char(600);
// Gather required information
tapdev = %upper(%trim(tapdev));
// Main procedure
clear logtxt;
logsts = 'T';
writelog(logsts : logtxt);

logsts = 'C';
logtxt = 'Restore User libraries start';
writelog(logsts : logtxt);
rstlib(tapdev);
logsts = 'C';
logtxt = 'Restore User libraries end';
writelog(logsts : logtxt);

// logsts = 'C';
// logtxt = 'Restore User profiles start';
// writelog(logsts : logtxt);
// rstusr(tapdev);
// logsts = 'C';
// logtxt = 'Restore User profiles end';
// writelog(logsts : logtxt);

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
    dcl-s cmdstr char(800);
    dcl-s returnCode int(5);
    dcl-s stmt char(200);
    dcl-s logsts char(1); // T: Log Title  C: Log Continue  E: Log Ending
    dcl-s logtxt char(600);
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
    dcl-s cmdstr char(800);
    dcl-s returnCode int(5);
    dcl-s logsts char(1); // T: Log Title  C: Log Continue  E: Log Ending
    dcl-s logtxt char(600);
    dcl-s cur_sysnm char(8);
    dcl-s ap_lib char(500);
    dcl-s omit_lib char(500) static;
    dcl-s objnm char(30);
    dcl-s option char(1);
    dcl-s volumeid char(6);
    // initial variable
    // omit_lib = '#LIBRARY DDSCINFO HOYA* PMEDH* RMT* Q* ' +
    //            'SYSIBM SYSIBMADM SYSPROC SYSTOOLS';
    if %len(%trim(cur_sysnm)) = 0;
        exec sql values current server into :cur_sysnm;
    endif;
    // ***** for Test only
    // cur_sysnm = 'KSG01N';
    // ***** for Test only
    logsts = 'C';
    logtxt = '* Current System is ' + %trim(cur_sysnm) + '.';
    writelog(logsts : logtxt);
    // Restore according to current system name
    select;
        // volume: 101Y25 & F02Y25
        when %trim(cur_sysnm) = 'AS101N';
            // Volumeid 101Y25 initial variable
            clear ap_lib;
            clear omit_lib;
            // Volumeid 101Y25 start
            // option = '2';
            // volumeid = '101Y25';
            // ap_lib = 'CCI SGKGIF SGKGIF029 SGKGIF000 SGKGIH SGKGIS SGKGIS029 SGKGIO ' + 
            //          'SGKGIO029 WRKGIF SGRQS';
            // rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            // option = '5';
            // cur_sysnm = 'AS101N';
            // objnm = 'CCI';
            // rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            // option = '1';
            // volumeid = '101Y25';
            // omit_lib = '#LIBRARY DDSCINFO HOYA* PMEDH* RMT* Q* ' +
            //             'SYSIBM SYSIBMADM SYSPROC SYSTOOLS SGKGISN';
            // rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            // option = '5';
            // cur_sysnm = 'AS101N';
            // objnm = '$INFRA';
            // rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            // option = '5';
            // cur_sysnm = 'AS101N';
            // objnm = 'MONLIB';
            // rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            // option = '5';
            // cur_sysnm = 'AS101N';            
            // objnm = 'OCEANTOOLS';
            // rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            // option = '5';
            // cur_sysnm = 'AS101N';            
            // objnm = 'SMSLIB';
            // rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            // Volumeid 101Y25 end

            Volumeid F02Y25 initial variable
            clear ap_lib;
            clear omit_lib;
            Volumeid F02Y25 start
            option = '2';
            volumeid = 'F02Y25';
            ap_lib = 'KCOFCMTF KCOFCMTT KCOFITN KCOFPRC KCOFUSR KCOFSCRT ' +
                     'KSOFFINA KSOFFINF KSOFFINFVR KSOFFIXF KSUSER FU1000427 ' +
                     'FUCOMM SMTPSPL S007389 GZIP';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            option = '4';
            volumeid = 'F02Y25';
            objnm = 'PTM0000P PTM0000D';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            option = '3';
            volumeid = 'F02Y25';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            option = '5';
            cur_sysnm = 'KSF02N';
            objnm = '$INFRA';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            option = '5';
            cur_sysnm = 'KSF02N';
            objnm = 'CCI';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            option = '5';
            cur_sysnm = 'KSF02N';
            objnm = 'MONLIB';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            option = '5';
            cur_sysnm = 'KSF02N';
            objnm = 'OCEANTOOLS';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            option = '5';
            cur_sysnm = 'KSF02N';
            objnm = 'SMSLIB';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            option = '5';
            cur_sysnm = 'KSF02N';
            objnm = 'DDSC';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            option = '5';
            cur_sysnm = 'KSF02N';
            objnm = 'DDSCINFO';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            Volumeid F02Y25 end

        // volume: F03Y25 & F04Y25
        when %trim(cur_sysnm) = 'KSF03N';
            // initial variable
            clear ap_lib;
            clear omit_lib;
            // Volumeid F03Y25 start
            // option = '2';
            // volumeid = 'F03Y25';
            // ap_lib = 'SGKGIF SGKGIF029 SGKGIF000 SGKGIH SGKGIS SGKGIS029 SGKGIO ' + 
            //          'SGKGIO029 WRKGIF SGRQS CCI';
            // rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            // option = '5';
            // cur_sysnm = 'KSF03N';
            // objnm = 'CCI';
            // rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            // option = '1';
            // volumeid = 'F03Y25';
            // omit_lib = '#LIBRARY DDSCINFO PMEDH* RMT* Q* ' +
            //             'SYSIBM SYSIBMADM SYSPROC SYSTOOLS SGKGISN';
            // rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            // option = '5';
            // cur_sysnm = 'KSF03N';
            // objnm = '$INFRA';
            // rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            // option = '5';
            // cur_sysnm = 'KSF03N';
            // objnm = 'MONLIB';
            // rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            // option = '5';
            // cur_sysnm = 'KSF03N';            
            // objnm = 'OCEANTOOLS';
            // rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            // option = '5';
            // cur_sysnm = 'KSF03N';            
            // objnm = 'SMSLIB';
            // rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            // Volumeid F03Y25 end
            // Volumeid F04Y25 start
            option = '2';
            volumeid = 'F04Y25';
            ap_lib = 'KCOFCMTF KCOFCMTT KCOFITN KCOFPRC ' +
                     'KCOFUSR KCOFSCRT KSOFFINA KSOFFINF ' +
                     'KSOFFINFVR KSOFFIXF KSUSER FU1000427 ' +
                     'FUCOMM SMTPSPL S007389 GZIP';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);

            option = '4';
            volumeid = 'F04Y25';
            objnm = 'PTM0000P PTM0000D';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);

            option = '3';
            volumeid = 'F04Y25';
            omit_lib = '#LIBRARY DDSCINFO HOYA* PMEDH* RMT* Q* ' +
                        'SYSIBM SYSIBMADM SYSPROC SYSTOOLS';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);

            option = '5';
            cur_sysnm = 'KSF04N';
            objnm = '$INFRA';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);

            option = '5';
            cur_sysnm = 'KSF04N';
            objnm = 'CCI';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);

            option = '5';
            cur_sysnm = 'KSF04N';
            objnm = 'MONLIB';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);

            option = '5';
            cur_sysnm = 'KSF04N';
            objnm = 'OCEANTOOLS';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);

            option = '5';
            cur_sysnm = 'KSF04N';
            objnm = 'SMSLIB';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            // Volumeid F04Y25 end
        // volume: G01Y25 & 800Y25 & 500Y25 & 052Y25
        when %trim(cur_sysnm) = 'KSG01N';
            // initial variable
            clear ap_lib;
            clear omit_lib;
            // AP Library start (800 library from 800Y25)
            option = '2';
            volumeid = '800Y25';
            ap_lib = 'KSOFFINA KSOFFINF KSOFFINFVR KSUSER FU1000427 KSOFFIXF ' +
                    'KSOFFINF1 KSOFFINFV1 KSUSER1 KSOSU KSOFFIXF1 ' +
                    'KSOFFINF2 KSOFFINFV2 KSUSER2 KSOFFIXF2' +
                    'KSOFFINF3 KSOFFINFV3 KSUSER3 KSOFFIXF3';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);

            option = '4';
            volumeid = '800Y25';
            objnm = 'PTM0000P PTM0000D';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            // AP Library start (500 library from 500Y25)
            option = '2';
            volumeid = '500Y25';
            ap_lib = 'PMSCBF PMSCBL DF500 SGKGIF SGKGIF029 SGKGIF000 ' +
                     'SGKGIS SGKGIS029 SGKGIO SGKGIO029 WRKGIF SGRQS ' + 
                     'SGRQS029 GZIP OSKGIF OSKGIF029 OSKGIF000 OSKGIS ' +
                     'OSKGIS029 OSKGIO OSKGIO029 OSRQS WOKGIF FUKGIF ' +
                     'FUKGIF029 FUKGIF000 FUKGIS FUKGIS029 FUKGIO FUKGIO029 ' +
                     'FURQS FURQS029 VCKGIF VCKGIF029 VCKGIF000 VCKGIS ' +
                     'VCKGIS029 VCKGIO VCKGIO029 VCRQS VCRQS029 FEKGIF ' +
                     'FEKGIF029 FEKGIF000 FEKGIS FEKGIS029 FEKGIO FEKGIO029 FERQS';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            AP Library start (052 library from 052Y25)
            option = '2';
            volumeid = '052Y25';
            ap_lib = 'BMBK1 BMBUS0F BMDWA0F BMDWCBF BMLIBAMF BMLIBA0F BMLIBA0O ' +
                    'BMLIBA0Q BMLIBA0S BMLIBA0T BMLIBCBF BMLIBCBO BMLIBCBQ BMLIBCBS ' +
                    'BMTEST BMUPDATEQ BMUPDATES BMUPDCBS BSIILIBF BSIILIBO BSIILIBS ' +
                    'GLPLUSF2AA';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            
            // // G01Y25 start
            // option = '1';
            // volumeid = 'G01Y25';
            // omit_lib = '#LIBRARY DDSCINFO PMEDH* RMT* Q* ' +
            //             'SYSIBM SYSIBMADM SYSPROC SYSTOOLS ' +
            //             'SGKGISN OSKGISN FUKGISN VCKGISN FEKGISN';
            // rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            // option = '5';
            // cur_sysnm = 'KSG01N';
            // objnm = '$INFRA';
            // rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            // option = '5';
            // cur_sysnm = 'KSG01N';
            // objnm = 'CCI';
            // rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            // option = '5';
            // cur_sysnm = 'KSG01N';
            // objnm = 'MONLIB';
            // rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            // option = '5';
            // cur_sysnm = 'KSG01N';
            // objnm = 'OCEANTOOLS';
            // rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            // option = '5';
            // cur_sysnm = 'KSG01N';
            // objnm = 'SMSLIB';
            // rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            // option = '5';
            // cur_sysnm = 'KSG01N';
            // objnm = 'DDSCINFO';
            // rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            
            // 800Y25 start
            option = '3';
            volumeid = '800Y25';
            omit_lib = '#LIBRARY DDSCINFO HOYA* PMEDH* RMT* Q* ' +
                        'SYSIBM SYSIBMADM SYSPROC SYSTOOLS';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            option = '5';
            cur_sysnm = 'DF800N';
            objnm = '$INFRA';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            option = '5';
            cur_sysnm = 'DF800N';
            objnm = 'CCI';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            option = '5';
            cur_sysnm = 'DF800N';
            objnm = 'MONLIB';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            option = '5';
            cur_sysnm = 'DF800N';
            objnm = 'OCEANTOOLS';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            option = '5';
            cur_sysnm = 'DF800N';
            objnm = 'SMSLIB';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            option = '5';
            cur_sysnm = 'DF800N';
            objnm = 'DDSCINFO';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            
            // 500Y25 start
            option = '3';
            volumeid = '500Y25';
            omit_lib = '#LIBRARY DDSCINFO HOYA* PMEDH* RMT* Q* ' +
                        'SYSIBM SYSIBMADM SYSPROC SYSTOOLS';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            option = '5';
            cur_sysnm = 'DF500N';
            objnm = '$INFRA';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            option = '5';
            cur_sysnm = 'DF500N';
            objnm = 'CCI';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            option = '5';
            cur_sysnm = 'DF500N';
            objnm = 'MONLIB';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            option = '5';
            cur_sysnm = 'DF500N';
            objnm = 'OCEANTOOLS';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            option = '5';
            cur_sysnm = 'DF500N';
            objnm = 'SMSLIB';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            option = '5';
            cur_sysnm = 'DF500N';
            objnm = 'DDSCINFO';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            
            // 052Y25 start
            option = '3';
            volumeid = '052Y25';
            omit_lib = '#LIBRARY DDSCINFO HOYA* PMEDH* RMT* Q* ' +
                        'SYSIBM SYSIBMADM SYSPROC SYSTOOLS';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            option = '5';
            cur_sysnm = 'AS052N';
            objnm = '$INFRA';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            option = '5';
            cur_sysnm = 'AS052N';
            objnm = 'CCI';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            option = '5';
            cur_sysnm = 'AS052N';
            objnm = 'MONLIB';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            option = '5';
            cur_sysnm = 'AS052N';
            objnm = 'OCEANTOOLS';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            option = '5';
            cur_sysnm = 'AS052N';
            objnm = 'SMSLIB';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            option = '5';
            cur_sysnm = 'AS052N';
            objnm = 'DDSCINFO';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
        
        // volume: G01Y25 & 500Y25 & 800Y25 & 052Y25
        when %trim(cur_sysnm) = 'AS081N';
            // initial variable
            clear ap_lib;
            clear omit_lib;
            // AP Library start (800 library from 500Y25)
            option = '2';
            volumeid = '500Y25';
            ap_lib = 'KCOFCMTF KCOFCMTT KCOFITN KCOFPRC ' +
                     'KCOFUSR KCOFSCRT KSOFFINA KSOFFINF ' +
                     'KSOFFINFVR KSOFFIXF KSUSER FU1000427 ' +
                     'FUCOMM SMTPSPL S007389 GZIP';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            option = '4';
            volumeid = '500Y25';
            objnm = 'PTM0000P PTM0000D';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            // AP Library start (500 library from 800Y25)
            option = '2';
            volumeid = '800Y25';
            ap_lib = 'PMSCBF PMSCBL DF500 SGKGIF SGKGIF029 SGKGIF000 ' +
                     'SGKGIS SGKGIS029 SGKGIO SGKGIO029 WRKGIF SGRQS ' + 
                     'SGRQS029 GZIP OSKGIF OSKGIF029 OSKGIF000 OSKGIS ' +
                     'OSKGIS029 OSKGIO OSKGIO029 OSRQS WOKGIF FUKGIF ' +
                     'FUKGIF029 FUKGIF000 FUKGIS FUKGIS029 FUKGIO FUKGIO029 ' +
                     'FURQS FURQS029 VCKGIF VCKGIF029 VCKGIF000 VCKGIS ' +
                     'VCKGIS029 VCKGIO VCKGIO029 VCRQS VCRQS029 FEKGIF ' +
                     'FEKGIF029 FEKGIF000 FEKGIS FEKGIS029 FEKGIO FEKGIO029 FERQS';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            // AP Library start (052 library from 052Y25)
            option = '2';
            volumeid = '052Y25';
            ap_lib = 'BMBK1 BMBUS0F BMDWA0F BMDWCBF BMLIBAMF BMLIBA0F BMLIBA0O ' +
                    'BMLIBA0Q BMLIBA0S BMLIBA0T BMLIBCBF BMLIBCBO BMLIBCBQ BMLIBCBS ' +
                    'BMTEST BMUPDATEQ BMUPDATES BMUPDCBS BSIILIBF BSIILIBO BSIILIBS ' +
                    'GLPLUSF2AA';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            // 081Y25 start
            // option = '1';
            // volumeid = '081Y25';
            // omit_lib = '#LIBRARY DDSCINFO PMEDH* RMT* Q* ' +
            //             'SYSIBM SYSIBMADM SYSPROC SYSTOOLS ' +
            //             'SGKGISN OSKGISN FUKGISN VCKGISN FEKGISN';
            // rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            // option = '5';
            // cur_sysnm = 'AS081N';
            // objnm = '$INFRA';
            // rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            // option = '5';
            // cur_sysnm = 'AS081N';
            // objnm = 'CCI';
            // rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            // option = '5';
            // cur_sysnm = 'AS081N';
            // objnm = 'MONLIB';
            // rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            // option = '5';
            // cur_sysnm = 'AS081N';
            // objnm = 'OCEANTOOLS';
            // rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            // option = '5';
            // cur_sysnm = 'AS081N';
            // objnm = 'SMSLIB';
            // rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            // option = '5';
            // cur_sysnm = 'AS081N';
            // objnm = 'DDSCINFO';
            // rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            
            // 500Y25 start
            option = '3';
            volumeid = '500Y25';
            omit_lib = '#LIBRARY DDSCINFO HOYA* PMEDH* RMT* Q* ' +
                        'SYSIBM SYSIBMADM SYSPROC SYSTOOLS ';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            option = '5';
            cur_sysnm = 'DF500N';
            objnm = '$INFRA';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            option = '5';
            cur_sysnm = 'DF500N';
            objnm = 'CCI';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            option = '5';
            cur_sysnm = 'DF500N';
            objnm = 'MONLIB';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            option = '5';
            cur_sysnm = 'DF500N';
            objnm = 'OCEANTOOLS';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            option = '5';
            cur_sysnm = 'DF500N';
            objnm = 'SMSLIB';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            option = '5';
            cur_sysnm = 'DF500N';
            objnm = 'DDSCINFO';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            
            // 800Y25 start
            option = '3';
            volumeid = '800Y25';
            omit_lib = '#LIBRARY DDSCINFO HOYA* PMEDH* RMT* Q* ' +
                        'SYSIBM SYSIBMADM SYSPROC SYSTOOLS ';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            option = '5';
            cur_sysnm = 'DF800N';
            objnm = '$INFRA';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            option = '5';
            cur_sysnm = 'DF800N';
            objnm = 'CCI';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            option = '5';
            cur_sysnm = 'DF800N';
            objnm = 'MONLIB';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            option = '5';
            cur_sysnm = 'DF800N';
            objnm = 'OCEANTOOLS';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            option = '5';
            cur_sysnm = 'DF800N';
            objnm = 'SMSLIB';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            option = '5';
            cur_sysnm = 'DF800N';
            objnm = 'DDSCINFO';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            
            // 052Y25 start
            option = '3';
            volumeid = '052Y25';
            omit_lib = '#LIBRARY DDSCINFO HOYA* PMEDH* RMT* Q* ' +
                        'SYSIBM SYSIBMADM SYSPROC SYSTOOLS ';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            option = '5';
            cur_sysnm = 'AS052N';
            objnm = '$INFRA';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            option = '5';
            cur_sysnm = 'AS052N';
            objnm = 'CCI';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            option = '5';
            cur_sysnm = 'AS052N';
            objnm = 'MONLIB';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            option = '5';
            cur_sysnm = 'AS052N';
            objnm = 'OCEANTOOLS';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            option = '5';
            cur_sysnm = 'AS052N';
            objnm = 'SMSLIB';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            option = '5';
            cur_sysnm = 'AS052N';
            objnm = 'DDSCINFO';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
        
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
        omit_lib char(500);
        objnm char(30);
    end-pi;
    dcl-s cmdstr char(800);
    dcl-s sysnm_length packed(5:0);
    dcl-s objnm_length packed(5:0);
    dcl-s startPos packed(5:0);
    dcl-s strLength packed(5:0);
    dcl-s renamed_objnm char(10);
    //
    select;
        when option = '1'; // Restore major system *allusr library
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
            cur_sysnm = %subst(%trim(cur_sysnm) : 1 : 5);
            objnm_length = %len(%trim(objnm));
            sysnm_length = %len(%trim(cur_sysnm));
            if objnm_length >= 7;
                renamed_objnm = %subst(%trim(objnm) : 1 : 7) + %subst(%trim(cur_sysnm) : 3 : 3);
            else;
                strLength = 10 - objnm_length;
                if strLength > sysnm_length;
                    strLength = sysnm_length;
                endif;
                startPos = 5 - strLength + 1;
                renamed_objnm = %trim(objnm) + %subst(%trim(cur_sysnm) : startPos : strLength);
            endif;
            cmdstr = 'RNMOBJ OBJ(QSYS/' + %trim(objnm) +
                    ') OBJTYPE(*LIB) NEWOBJ(' + %trim(renamed_objnm) + ')';
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
    dcl-s cmdstr char(800);
    cmdstr = 'DLYJOB DLY(2)';
    exec sql call qsys2.qcmdexc(:cmdstr);
    return;
end-proc;
