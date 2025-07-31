**FREE
// CALL PGM(STEVE/RSTUSRLIB) PARM(('TAPMLB01'))
ctl-opt option(*srcstmt) dftactgrp(*no);
// user-input parameter - Tape device name
dcl-pi *n;
    tapdev char(10);
end-pi;
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

clear logtxt;
logsts = 'E';
writelog(logsts : logtxt);
*inlr = *on;
return;

dcl-proc rstlib;
    dcl-pi *n ;
        tapdev char(8);
    end-pi;
    // dcl-pr syscmd int(10) ExtProc('system');
    //     *n Pointer Value Options(*String);
    // end-pr;   
    // dcl-s cmdstr char(800);
    // dcl-s returnCode int(5);
    dcl-s logsts char(1); // T: Log Title  C: Log Continue  E: Log Ending
    dcl-s logtxt char(600);
    dcl-s cur_sysnm char(8) static;
    dcl-s ap_lib char(500);
    dcl-s omit_lib char(500) static;
    dcl-s objnm char(30);
    dcl-s option char(1);
    dcl-s volumeid char(6);
    // get current system name
    if %len(%trim(cur_sysnm)) = 0;
        exec sql values current server into :cur_sysnm;
    endif;
    // test only
    cur_sysnm = 'KSG01N';
    // test only
    logsts = 'C';
    logtxt = '* Current System is ' + %trim(cur_sysnm) + '.';
    writelog(logsts : logtxt);
    // Restore according to current system name
        if %trim(cur_sysnm) = 'KSG01N';
            
            // restore df800 ap library
            option = '2';
            volumeid = '800Y25';
            ap_lib =    'KSOFFINA KSOFFINF KSOFFINF1 KSOFFINF2 KSOFFINF3 ' +
                        'KSOFFIXF KSOFFIXF1 KSOFFIXF2 KSOFFIXF3 ' +
                        'FU1000427 KSOSU ' +
                        'KSUSER KSUSER1 KSUSER2 KSUSER3 ' +
                        'KSOFFINFVR KSOFFINFV1 KSOFFINFV2 KSOFFINFV3 ';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            
            // restore df800 qgpl object
            option = '4';
            volumeid = '800Y25';
            objnm = 'PTM0000P PTM0000D';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            
            // restore df500 ap library
            option = '2';
            volumeid = '500Y25';
            ap_lib = 'PMSCBF PMSCBL DF500 CCI GZIP ' +
                     'SGKGIF SGKGIF029 SGKGIF000 SGKGIS SGKGIS029 SGKGIO SGKGIO029 ' +
                     'SGRQS SGRQS029 WRKGIF ' +
                     'OSKGIF OSKGIF029 OSKGIF000 OSKGIS OSKGIS029 OSKGIO OSKGIO029 ' +
                     'OSRQS WOKGIF ' +
                     'FUKGIF FUKGIF029 FUKGIF000 FUKGIS FUKGIS029 FUKGIO FUKGIO029 ' +
                     'FURQS FURQS029 ' +
                     'VCKGIF VCKGIF029 VCKGIF000 VCKGIS VCKGIS029 VCKGIO VCKGIO029 ' +
                     'VCRQS VCRQS029 ' +
                     'FEKGIF FEKGIF029 FEKGIF000 FEKGIS FEKGIS029 FEKGIO FEKGIO029 ' +
                     'FERQS';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);

            // rename df500 library            
            option = '5';
            cur_sysnm = 'DF500N';
            objnm = 'CCI';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);

            // restore as052 ap library
            option = '2';
            volumeid = '052Y25';
            ap_lib = 'BMBK1 BMBUS0F ' +
                     'BMDWA0F BMDWCBF ' +
                     'BMLIBAMF BMLIBA0F BMLIBA0O BMLIBA0Q BMLIBA0S BMLIBA0T ' +
                     'BMLIBCBF BMLIBCBO BMLIBCBQ BMLIBCBS ' +
                     'BMTEST BMUPDATEQ BMUPDATES BMUPDCBS ' +
                     'BSIILIBF BSIILIBO BSIILIBS GLPLUSF2AA';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);

            // restore ksg01 allusr library
            option = '1';
            volumeid = 'G01Y25';
            omit_lib =  '#* Q* SYSIBM SYSIBMADM SYSPROC SYSTOOLS ' +
                        'DDSCINFO HOYA* PMEDH* RMT* LAKEVIEW* ' +
                        'SGKGISN OSKGISN FUKGISN VCKGISN FEKGISN ';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);

            // rename ksg01 library
            option = '5';
            cur_sysnm = 'KSG01N';
            objnm = '$INFRA';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            option = '5';
            cur_sysnm = 'KSG01N';
            objnm = 'CCI';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            option = '5';
            cur_sysnm = 'KSG01N';
            objnm = 'MONLIB';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            option = '5';
            cur_sysnm = 'KSG01N';
            objnm = 'OCEANTOOLS';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            option = '5';
            cur_sysnm = 'KSG01N';
            objnm = 'SMSLIB';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            
            // restore df800 allusr library
            option = '3';
            volumeid = '800Y25';
            omit_lib =  '#* Q* SYSIBM SYSIBMADM SYSPROC SYSTOOLS ' +
                        'DDSCINFO HOYA* PMEDH* RMT* LAKEVIEW* ' +
                        'SGKGISN OSKGISN FUKGISN VCKGISN FEKGISN ';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);

            // rename df800 library
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
            
            // restore df500 allusr library
            option = '3';
            volumeid = '500Y25';
            omit_lib =  '#* CCI Q* SYSIBM SYSIBMADM SYSPROC SYSTOOLS ' +
                        'DDSCINFO HOYA* PMEDH* RMT* LAKEVIEW* ' +
                        'SGKGISN OSKGISN FUKGISN VCKGISN FEKGISN ';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);

            // rename df500 library
            option = '5';
            cur_sysnm = 'DF500N';
            objnm = '$INFRA';
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
            
            // restore as052 allusr library
            option = '3';
            volumeid = '052Y25';
            omit_lib =  '#* Q* SYSIBM SYSIBMADM SYSPROC SYSTOOLS ' +
                        'DDSCINFO HOYA* PMEDH* RMT* LAKEVIEW* ' +
                        'SGKGISN OSKGISN FUKGISN VCKGISN FEKGISN ';

            // rename as052 library    
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

        else;
            logsts = 'C';
            logtxt = '*** System is not in the scheduled list ***';
            writelog(logsts : logtxt);
        endif;
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
            
            logsts = 'C';
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
            
            logsts = 'C';
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
            
            logsts = 'C';
            logtxt = '-     ' + %trim(cmdstr);
            writelog(logsts : logtxt);

        when option = '4'; // Restore QGPL specific object
            cmdstr = 'DLTOBJ OBJ(QGPL/' + %subst(%trim(objnm) : 1 : 8) + ') OBJTYPE(*FILE)';
            logsts = 'C';
            logtxt = '-   Delete QGPL specific object: ';
            writelog(logsts : logtxt);

            logsts = 'C';
            logtxt = '-     ' + %trim(cmdstr);
            writelog(logsts : logtxt);

            cmdstr = 'DLTOBJ OBJ(QGPL/' + %subst(%trim(objnm) : 10 : 8) + ') OBJTYPE(*FILE)';
            logsts = 'C';
            logtxt = '-   Delete QGPL specific object: ';
            writelog(logsts : logtxt);
            
            logsts = 'C';
            logtxt = '-     ' + %trim(cmdstr);
            writelog(logsts : logtxt);

            cmdstr = 'RSTOBJ OBJ(' + %trim(objnm) + ') SAVLIB(QGPL) ' +
                     'DEV(' + %trim(tapdev) + ') ' +
                     'VOL(' + %trim(volumeid) + ') ' +
                     'OPTION(*NEW) MBROPT(*ALL) ' +
                     'ALWOBJDIF(*ALL) OUTPUT(*PRINT)';
            logsts = 'C';
            logtxt = '-   Restore QGPL specific object: ';
            writelog(logsts : logtxt);
            
            logsts = 'C';
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
            
            logsts = 'C';
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
        logLocation = '/tmp/rstusrlibn' +
                        '_' + %trim(cur_sysnm) + 
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

