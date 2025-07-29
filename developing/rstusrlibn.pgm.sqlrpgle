**FREE
// Usage: CALL PGM(STEVE/RSTUSRLIB) PARM(('TAPMLB01'))
ctl-opt option(*srcstmt) dftactgrp(*no);
dcl-pi *n;
    tapdev char(10);
end-pi;
dcl-s logsts char(1); // T: Log Title  C: Log Continue  E: Log Ending
dcl-s logtxt char(600);
// Upper input parameter
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
    dcl-s logsts char(1); // T: Log Title  C: Log Continue  E: Log Ending
    dcl-s logtxt char(600);
    dcl-s cur_sysnm char(8);
    dcl-s ap_lib char(500);
    dcl-s omit_lib char(500) static;
    dcl-s objnm char(30); // object name will be renamed
    dcl-s option char(1);
    dcl-s volumeid char(6);
    // get system name
    if %len(%trim(cur_sysnm)) = 0;
        exec sql values current server into :cur_sysnm;
    endif;
    // ***** for Test only
    cur_sysnm = 'AS081N';
    // ***** for Test only
    logsts = 'C';
    logtxt = '* Current System is ' + %trim(cur_sysnm) + '.';
    writelog(logsts : logtxt);

    select;
        // volume: 101Y25 & F02Y25
        when %trim(cur_sysnm) = 'AS101N';
            clear ap_lib;
            clear omit_lib;

            // Volumeid 101Y25 start
            option = '2';
            volumeid = '101Y25';
            ap_lib = 'CCI SGKGIF SGKGIF029 SGKGIF000 SGKGIH SGKGIS SGKGIS029 SGKGIO ' + 
                     'SGKGIO029 WRKGIF SGRQS';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            
            option = '5';
            cur_sysnm = 'AS101N';
            objnm = 'CCI';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            
            option = '1';
            volumeid = '101Y25';
            omit_lib = '#LIBRARY DDSCINFO PMEDH* RMT* Q* ' +
                        'SYSIBM SYSIBMADM SYSPROC SYSTOOLS SGKGISN' +
                        'KCOFCMTF KCOFCMTT KCOFITN KCOFPRC KCOFUSR KCOFSCRT ' +
                        'KSOFFINF KSOFFIXF KSOFFINA KSOFFINFVR KSUSER FU1000427 ' +
                        'FUCOMM SMTPSPL S007389 GZIP';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            
            option = '5';
            cur_sysnm = 'AS101N';
            objnm = '$INFRA';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            
            option = '5';
            cur_sysnm = 'AS101N';
            objnm = 'MONLIB';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            
            option = '5';
            cur_sysnm = 'AS101N';            
            objnm = 'OCEANTOOLS';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            
            option = '5';
            cur_sysnm = 'AS101N';            
            objnm = 'SMSLIB';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);

            // Volumeid F02Y25 initial variable
            clear ap_lib;
            clear omit_lib;

            // Volumeid F02Y25 start
            option = '2';
            volumeid = 'F02Y25';
            ap_lib = 'KCOFCMTF KCOFCMTT KCOFITN KCOFPRC KCOFUSR KCOFSCRT ' +
                     'KSOFFINF KSOFFIXF KSOFFINA KSOFFINFVR KSUSER FU1000427 ' +
                     'FUCOMM SMTPSPL S007389 GZIP';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            
            option = '4';
            volumeid = 'F02Y25';
            objnm = 'PTM0000P PTM0000D';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            
            option = '3';
            volumeid = 'F02Y25';
            omit_lib = '#LIBRARY DDSCINFO HOYA* PMEDH* RMT* Q* ' +
                        'SYSIBM SYSIBMADM SYSPROC SYSTOOLS';
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
            
        // volume: F03Y25 & F04Y25
        when %trim(cur_sysnm) = 'KSF03N';
            
            // Volumeid F03Y25 initial variable
            clear ap_lib;
            clear omit_lib;

            // Volumeid F03Y25 start
            option = '2';
            volumeid = 'F03Y25';
            ap_lib = 'SGKGIF SGKGIF029 SGKGIF000 SGKGIH SGKGIS SGKGIS029 SGKGIO ' + 
                     'SGKGIO029 WRKGIF SGRQS CCI';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            
            option = '5';
            cur_sysnm = 'KSF03N';
            objnm = 'CCI';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            
            option = '1';
            volumeid = 'F03Y25';
            omit_lib = '#LIBRARY DDSCINFO PMEDH* RMT* Q* ' +
                        'SYSIBM SYSIBMADM SYSPROC SYSTOOLS SGKGISN' +
                        'KCOFCMTF KCOFCMTT KCOFITN KCOFPRC KCOFUSR KCOFSCRT ' +
                        'KSOFFINF KSOFFIXF KSOFFINA KSOFFINFVR KSUSER FU1000427 ' +
                        'FUCOMM SMTPSPL S007389 GZIP';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            
            option = '5';
            cur_sysnm = 'KSF03N';
            objnm = '$INFRA';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            
            option = '5';
            cur_sysnm = 'KSF03N';
            objnm = 'MONLIB';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            
            option = '5';
            cur_sysnm = 'KSF03N';            
            objnm = 'OCEANTOOLS';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            
            option = '5';
            cur_sysnm = 'KSF03N';            
            objnm = 'SMSLIB';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);

            // Volumeid F04Y25 start
            option = '2';
            volumeid = 'F04Y25';
            ap_lib = 'KCOFCMTF KCOFCMTT KCOFITN KCOFPRC KCOFUSR KCOFSCRT ' +
                     'KSOFFINF KSOFFIXF KSOFFINA KSOFFINFVR KSUSER FU1000427 ' +
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
        
        // volume: G01Y25 & 800Y25 & 500Y25 & 052Y25
        when %trim(cur_sysnm) = 'KSG01N';
            
            // Volumeid G01Y25 initial variable
            clear ap_lib;
            clear omit_lib;
            
            // AP Library start (800 library from 800Y25)
            option = '2';
            volumeid = '800Y25';
            ap_lib = 'KSOFFINA KSOFFINF KSOFFINF1 KSOFFINF2 KSOFFINF3 ' +
                    'KSOFFIXF KSOFFIXF1 KSOFFIXF2 KSOFFIXF3 ' +
                    'FU1000427 KSOSU ' +
                    'KSUSER KSUSER1 KSUSER2 KSUSER3 ' +
                    'KSOFFINFVR KSOFFINFV1 KSOFFINFV2 KSOFFINFV3 ';
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
            
            // AP Library start (052 library from 052Y25)
            option = '2';
            volumeid = '052Y25';
            ap_lib = 'BMBK1 BMBUS0F BMDWA0F BMDWCBF BMLIBAMF BMLIBA0F BMLIBA0O ' +
                    'BMLIBA0Q BMLIBA0S BMLIBA0T BMLIBCBF BMLIBCBO BMLIBCBQ BMLIBCBS ' +
                    'BMTEST BMUPDATEQ BMUPDATES BMUPDCBS BSIILIBF BSIILIBO BSIILIBS ' +
                    'GLPLUSF2AA';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            
            // Volumeid G01Y25 start
            option = '1';
            volumeid = 'G01Y25';
            omit_lib = '#LIBRARY DDSCINFO PMEDH* RMT* Q* ' +
                        'SYSIBM SYSIBMADM SYSPROC SYSTOOLS ' +
                        'SGKGISN OSKGISN FUKGISN VCKGISN FEKGISN';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
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
            option = '5';
            cur_sysnm = 'KSG01N';
            objnm = 'DDSCINFO';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            
            // Volumeid 800Y25 start
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
            
            // Volumeid 500Y25 start
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
            
            // Volumeid 052Y25 start
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
        
        // volume: 081Y25 & 500Y25 & 800Y25 & 052Y25
        when %trim(cur_sysnm) = 'AS081N';
            
            // Volumeid 081Y25initial variable
            clear ap_lib;
            clear omit_lib;

            // AP Library start (800 library from 500Y25)
            option = '2';
            volumeid = '500Y25';
            ap_lib = 'KSOFFINA KSOFFINF KSOFFINF1 KSOFFINF2 KSOFFINF3 ' +
                    'KSOFFIXF KSOFFIXF1 KSOFFIXF2 KSOFFIXF3 ' +
                    'FU1000427 KSOSU ' +
                    'KSUSER KSUSER1 KSUSER2 KSUSER3 ' +
                    'KSOFFINFVR KSOFFINFV1 KSOFFINFV2 KSOFFINFV3 ';
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
            
            // volumeid 081Y25 start
            option = '1';
            volumeid = '081Y25';
            omit_lib = '#LIBRARY DDSCINFO PMEDH* RMT* Q* ' +
                        'SYSIBM SYSIBMADM SYSPROC SYSTOOLS ' +
                        'SGKGISN OSKGISN FUKGISN VCKGISN FEKGISN';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            option = '5';
            cur_sysnm = 'AS081N';
            objnm = '$INFRA';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            option = '5';
            cur_sysnm = 'AS081N';
            objnm = 'CCI';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            option = '5';
            cur_sysnm = 'AS081N';
            objnm = 'MONLIB';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            option = '5';
            cur_sysnm = 'AS081N';
            objnm = 'OCEANTOOLS';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            option = '5';
            cur_sysnm = 'AS081N';
            objnm = 'SMSLIB';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            option = '5';
            cur_sysnm = 'AS081N';
            objnm = 'DDSCINFO';
            rstaction(option : cur_sysnm : tapdev : volumeid : ap_lib : omit_lib : objnm);
            
            // volumeid 500Y25 start
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
            cmdstr = 'DLTOBJ OBJ(QGPL/' + %trim(objnm) + ') ';
            logsts = 'C';
            logtxt = '-   Delete QGPL specific object: ';
            writelog(logsts : logtxt);
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