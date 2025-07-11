**FREE
// CALL PGM(STEVE/CHGNWCFG)
// writelog(logsts : logtxt);
//   logsts T : Log Title
//   logsts C : Log Continue
//   logsts E : Log Ending
//
ctl-opt option(*srcstmt) dftactgrp(*no);
//
dcl-s logsts char(1); // T: Log Title  C: Log Continue  E: Log Ending
dcl-s logtxt char(600);
// Main procedure
clear logtxt;
logsts = 'T';
writelog(logsts : logtxt);

logsts = 'C';
logtxt = 'Gather required information start';
gather_info();
logsts = 'C';
logtxt = 'Gather required information start';
writelog(logsts : logtxt);

logsts = 'C';
logtxt = 'submit remote command start';
writelog(logsts : logtxt);
// rstusr(tapdev);
logsts = 'C';
logtxt = 'submit remote command end';
writelog(logsts : logtxt);

clear logtxt;
logsts = 'E';
writelog(logsts : logtxt);
*inlr = *on;
return;

dcl-proc gather_info;
    dcl-pi *n;
        target_sysnm char(8); // Input : target system name
        isNew char(1);
        ipaddr char(15);
        hostnme1 char(50);
        hostnme2 char(50);
        ctlnm char(10);
    end-pi;
    logsts = 'C';
    logtxt = 'Gathering target system information start';
    writelog(logsts : logtxt);

    %







    if %trim(cur_sysnm) = '';
    exec sql values current server into :cur_sysnm;
endif;
    // for Test Only
cur_sysnm = 'KSG01N';
    // for Test Only
    // New & old system name 
new_sysnm = %trim(cur_sysnm);
org_sysnm = %trim(%scanrpl('N' : '' : cur_sysnm));
    // New & old IP address
exec sql select internet into :org_ip 
                from qusrsys.qatochost
                where hostnme1 = :org_sysnm or hostnme2 = :org_sysnm fetch first 1 rows only;
exec sql select internet_address into :new_ip
                from qsys2.netstat_interface_info 
                where line_description = '*VIRTUALIP' order by internet_address 
                fetch first 1 rows only;
    // New & old CTLD name
org_ctlnm = 'TCP' + %trim(org_sysnm);
new_ctlnm = %trim(org_ctlnm) + 'N';
    // New & old Host table entry
cur_hostnme1 = %trim(cur_sysnm);
cur_hostnme2 = %trim(cur_sysnm) + '.KGI.COM.TW';
org_hostnme1 = %trim(org_sysnm);
org_hostnme2 = %trim(org_sysnm) + '.APPN.SNA.IBM.COM';
new_hostnme1 = %trim(new_sysnm);
new_hostnme2 = %trim(new_sysnm) + '.APPN.SNA.IBM.COM';




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
    logLocation = '/home/chgnwcfg' + 
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
