**FREE
ctl-opt option(*srcstmt) dftactgrp(*no);
dcl-pi *n;
    objschema char(10);
end-pi;
dcl-pr syscmd int(10) ExtProc('system');
    *n Pointer Value Options(*String);
end-pr;
dcl-ds lst qualified;
    sys_dname char(10);
    sys_oname char(10);
    objtype char(7);
    user_name char(10);
    OBJ_AUTH char(12);
    OWNER char(10);
    AUTL char(10);
    GROUP char(10);
    OBJOPER char(3);
    OBJMGT char(3);
    OBJEXIST char(3);
    OBJALTER char(3);
    OBJREF char(3);
    DATA_READ char(3);
    DATA_ADD char(3);
    DATA_UPD char(3);
    DATA_DEL char(3);
    DATA_EXEC char(3);
end-ds;
dcl-ds objaut qualified;
    oalib char(10);
    oaname char(10);
    oatype char(7);
    oausr char(10);
    oagrpn char(10);
    oaobja char(12);
    oaown char(10);
    oaanam char(10);
    oaopr char(3);
    oaomgt char(3);
    oaexs char(3);
    oaalt char(3);
    oaref char(3);
    oaread char(3);
    oaadd char(3);
    oaupd char(3);
    oadlt char(3);
    oaexec char(3);
end-ds;

dcl-s stmt char(1500);
dcl-s tot_count packed(5:0);
dcl-s logsts char(1); // T: Log Title  C: Log Continue  E: Log Ending
dcl-s logtxt char(1500);
dcl-s grtcmdstr char(800);
dcl-s rvkcmdstr char(800);
dcl-s cmdstr char(800);
dcl-s returnCode int(5);
//
objschema = %upper(%trim(objschema));
stmt = 'select oalib, oaname, ' +
                'oatype, oausr, ' +
                'oaobja, oaown, ' +
                'oaanam, oagrpn, ' + 
                'oaopr, oaomgt, ' + 
                'oaexs, oaalt, ' +
                'oaref, oaread, ' + 
                'oaadd, oaupd, ' + 
                'oadlt, oaexec ' + 
                'from ddscinfo.objaut where oalib = ''' + %trim(objschema) + '''';
exec sql prepare prelst from :stmt;
exec sql declare lst cursor for prelst;
exec sql open lst using :objschema;
exec sql fetch next from lst into :objaut.oalib, :objaut.oaname,
                                  :objaut.oatype, :objaut.oausr,
                                  :objaut.oaobja, :objaut.oaown,
                                  :objaut.oaanam, :objaut.oagrpn,
                                  :objaut.oaopr, :objaut.oaomgt,
                                  :objaut.oaexs, :objaut.oaalt,
                                  :objaut.oaref, :objaut.oaread,
                                  :objaut.oaadd, :objaut.oaupd,
                                  :objaut.oadlt, :objaut.oaexec;
dow sqlcod = 0;
    if sqlcod = 0;
        if objaut.oausr = '*PUBLIC';
            tot_count += 1;
        endif;
        exec sql values(select 
                        user_name, 
                        coalesce(OBJ_AUTH,'*NONE') as OBJ_AUTH, 
                        coalesce(OWNER,'*NONE') as OWNER, 
                        COALESCE(AUTL,'*NONE') as AUTL, 
                        coalesce(GROUP,' ') as GROUP, 
                        coalesce(OBJOPER,' ') as OBJOPER, 
                        coalesce(OBJMGT,' ') as OBJMGT, 
                        coalesce(OBJEXIST,' ') as OBJEXIST, 
                        coalesce(OBJALTER,' ') as OBJALTER, 
                        coalesce(OBJREF,' ') as OBJREF, 
                        coalesce(DATA_READ,' ') as DATA_READ, 
                        coalesce(DATA_ADD,' ') as DATA_ADD, 
                        coalesce(DATA_UPD,' ') as DATA_UPD, 
                        coalesce(DATA_DEL,' ') as DATA_DEL, 
                        coalesce(DATA_EXEC,' ') as DATA_EXEC 
                        from qsys2.object_privileges 
                        where sys_dname = :objaut.oalib and 
                                sys_oname = :objaut.oaname and
                                objtype = :objaut.oatype and
                                user_name = :objaut.oausr )
                into    :lst.user_name, 
                        :lst.OBJ_AUTH, :lst.OWNER, 
                        :lst.AUTL, :lst.GROUP, 
                        :lst.OBJOPER, :lst.OBJMGT, 
                        :lst.OBJEXIST, :lst.OBJALTER, 
                        :lst.OBJREF, :lst.DATA_READ, 
                        :lst.DATA_ADD, :lst.DATA_UPD, 
                        :lst.DATA_DEL, :lst.DATA_EXEC;
        if sqlcod = 0; 
            if %trim(objaut.oausr) = '*GROUP';
                objaut.oausr = %trim(objaut.oagrpn);
            endif;
            if %trim(objaut.oaown) <> %trim(lst.OWNER);
                cmdstr = 'CHGOBJOWN OBJ(' + %trim(objaut.oalib) + 
                                    '/' + %trim(objaut.oaname) + 
                                    ') OBJTYPE(' + %trim(objaut.oatype) + 
                                    ') NEWOWN(' + %trim(objaut.oaown) + ')';
                snd-msg %trim(cmdstr);
                logsts = 'C';
                logtxt = 'Command: ' + %trim(cmdstr);
                writelog(logsts : logtxt);
                returnCode = syscmd(cmdstr);
            endif;
            if %trim(objaut.oaanam) <> %trim(lst.AUTL);
                cmdstr = 'GRTOBJAUT OBJ(' + %trim(objaut.oalib) + 
                                    '/' + %trim(objaut.oaname) + 
                                    ') OBJTYPE(' + %trim(objaut.oatype) + 
                                    ') AUTL(' + %trim(objaut.oaanam) + ')';
                logsts = 'C';
                logtxt = 'Command: ' + %trim(cmdstr);
                writelog(logsts : logtxt);
                returnCode = syscmd(cmdstr);
            endif;
            if %scan('USER' : %trim(objaut.oaobja)) <> 1;
                if %trim(objaut.oaobja) <> %trim(lst.OBJ_AUTH);
                    cmdstr = 'GRTOBJAUT OBJ(' + %trim(objaut.oalib) + 
                                '/' + %trim(objaut.oaname) + 
                                ') OBJTYPE(' + %trim(objaut.oatype) + 
                                ') USER(' + %trim(objaut.oausr) + 
                                ') AUT(' + %trim(objaut.oaobja) + 
                                ') REPLACE(*YES)';
                    logsts = 'C';
                    logtxt = 'Command: ' + %trim(cmdstr);
                    writelog(logsts : logtxt);
                    returnCode = syscmd(cmdstr);
                endif;
            else; // = 'USER DEFINED'
                grtcmdstr = 'GRTOBJAUT OBJ(' + %trim(objaut.oalib) + 
                            '/' + %trim(objaut.oaname) + 
                            ') OBJTYPE(' + %trim(objaut.oatype) + 
                            ') USER(' + %trim(objaut.oausr) + 
                            ') AUT(';
                rvkcmdstr = 'RVKOBJAUT OBJ(' + %trim(objaut.oalib) + 
                            '/' + %trim(objaut.oaname) + 
                            ') OBJTYPE(' + %trim(objaut.oatype) + 
                            ') USER(' + %trim(objaut.oausr) + 
                            ') AUT(';
                if %trim(objaut.oaopr) = 'X';
                    objaut.oaopr = 'YES';
                    if %trim(objaut.oaopr) <> %trim(lst.OBJOPER);
                        snd-msg 'oaopr:' + %trim(objaut.oaopr) + '  ' + %trim(lst.OBJOPER);
                        grtcmdstr = %trimr(grtcmdstr) + ' *OBJOPR';
                    endif;
                else;
                    objaut.oaopr = 'NO';
                    if %trim(objaut.oaopr) <> %trim(lst.OBJOPER);
                        snd-msg 'oaopr:' + %trim(objaut.oaopr) + '  ' + %trim(lst.OBJOPER);
                        rvkcmdstr = %trimr(rvkcmdstr) + ' *OBJOPR';
                    endif;                    
                endif;
                if %trim(objaut.oaomgt) = 'X';
                    objaut.oaomgt = 'YES';
                    if %trim(objaut.oaomgt) <> %trim(lst.OBJMGT);
                        snd-msg 'oaomgt:' + %trim(objaut.oaomgt) + '  ' + %trim(lst.OBJMGT);
                        grtcmdstr = %trimr(grtcmdstr) + ' *OBJMGT';
                    endif;
                else;
                    objaut.oaomgt = 'NO';
                    if %trim(objaut.oaomgt) <> %trim(lst.OBJMGT);
                        snd-msg 'oaomgt:' + %trim(objaut.oaomgt) + '  ' + %trim(lst.OBJMGT);
                        rvkcmdstr = %trimr(rvkcmdstr) + ' *OBJMGT';
                    endif;                    
                endif;
                if %trim(objaut.oaexs) = 'X';
                    objaut.oaexs = 'YES';
                    if %trim(objaut.oaexs) <> %trim(lst.OBJEXIST);
                        snd-msg 'oaexs:' + %trim(objaut.oaexs) + '  ' + %trim(lst.OBJEXIST);
                        grtcmdstr = %trimr(grtcmdstr) + ' *OBJEXIST';
                    endif;
                else;
                    objaut.oaexs = 'NO';
                    if %trim(objaut.oaexs) <> %trim(lst.OBJEXIST);
                        snd-msg 'oaexs:' + %trim(objaut.oaexs) + '  ' + %trim(lst.OBJEXIST);
                        rvkcmdstr = %trimr(rvkcmdstr) + ' *OBJEXIST';
                    endif;                    
                endif;
                if %trim(objaut.oaalt) = 'X';
                    objaut.oaalt = 'YES';
                    if %trim(objaut.oaalt) <> %trim(lst.OBJALTER);
                        snd-msg 'oaalt:' + %trim(objaut.oaalt) + '  ' + %trim(lst.OBJALTER);
                        grtcmdstr = %trimr(grtcmdstr) + ' *OBJALTER';
                    endif;
                else;
                    objaut.oaalt = 'NO';
                    if %trim(objaut.oaalt) <> %trim(lst.OBJALTER);
                        snd-msg 'oaalt:' + %trim(objaut.oaalt) + '  ' + %trim(lst.OBJALTER);
                        rvkcmdstr = %trimr(rvkcmdstr) + ' *OBJALTER';
                    endif;                    
                endif;
                if %trim(objaut.oaref) = 'X';
                    objaut.oaref = 'YES';
                    if %trim(objaut.oaref) <> %trim(lst.OBJREF);
                        snd-msg 'oaref:' + %trim(objaut.oaref) + '  ' + %trim(lst.OBJREF);
                        grtcmdstr = %trimr(grtcmdstr) + ' *OBJREF';
                    endif;
                else;
                    objaut.oaref = 'NO';
                    if %trim(objaut.oaref) <> %trim(lst.OBJREF);
                        snd-msg 'oaref:' + %trim(objaut.oaref) + '  ' + %trim(lst.OBJREF);
                        rvkcmdstr = %trimr(rvkcmdstr) + ' *OBJREF';
                    endif;                    
                endif;
                if %trim(objaut.oaread) = 'X';
                    objaut.oaread = 'YES';
                    if %trim(objaut.oaread) <> %trim(lst.DATA_READ);
                        snd-msg 'oaread:' + %trim(objaut.oaread) + '  ' + %trim(lst.DATA_READ);
                        grtcmdstr = %trimr(grtcmdstr) + ' *READ';
                    endif;
                else;
                    objaut.oaread = 'NO';
                    if %trim(objaut.oaread) <> %trim(lst.DATA_READ);
                        snd-msg 'oaread:' + %trim(objaut.oaread) + '  ' + %trim(lst.DATA_READ);
                        rvkcmdstr = %trimr(rvkcmdstr) + ' *READ';
                    endif;                    
                endif;
                if %trim(objaut.oaadd) = 'X';
                    objaut.oaadd = 'YES';
                    if %trim(objaut.oaadd) <> %trim(lst.DATA_ADD);
                        snd-msg 'oaadd:' + %trim(objaut.oaadd) + '  ' + %trim(lst.DATA_ADD);
                        grtcmdstr = %trimr(grtcmdstr) + ' *ADD';
                    endif;
                else;
                    objaut.oaadd = 'NO';
                    if %trim(objaut.oaadd) <> %trim(lst.DATA_ADD);
                        snd-msg 'oaadd:' + %trim(objaut.oaadd) + '  ' + %trim(lst.DATA_ADD);
                        rvkcmdstr = %trimr(rvkcmdstr) + ' *ADD';
                    endif;                    
                endif;
                if %trim(objaut.oaupd) = 'X';
                    objaut.oaupd = 'YES';
                    if %trim(objaut.oaupd) <> %trim(lst.DATA_UPD);
                        snd-msg 'oaupd:' + %trim(objaut.oaupd) + '  ' + %trim(lst.DATA_UPD);
                        grtcmdstr = %trimr(grtcmdstr) + ' *UPD';
                    endif;
                else;
                    objaut.oaupd = 'NO';
                    if %trim(objaut.oaupd) <> %trim(lst.DATA_UPD);
                        snd-msg 'oaupd:' + %trim(objaut.oaupd) + '  ' + %trim(lst.DATA_UPD);
                        rvkcmdstr = %trimr(rvkcmdstr) + ' *UPD';
                    endif;                    
                endif;
                if %trim(objaut.oadlt) = 'X';
                    objaut.oadlt = 'YES';
                    if %trim(objaut.oadlt) <> %trim(lst.DATA_DEL);
                        snd-msg 'oadlt:' + %trim(objaut.oadlt) + '  ' + %trim(lst.DATA_DEL);
                        grtcmdstr = %trimr(grtcmdstr) + ' *DLT';
                    endif;
                else;
                    objaut.oadlt = 'NO';
                    if %trim(objaut.oadlt) <> %trim(lst.DATA_DEL);
                        snd-msg 'oadlt:' + %trim(objaut.oadlt) + '  ' + %trim(lst.DATA_DEL);
                        rvkcmdstr = %trimr(rvkcmdstr) + ' *DLT';
                    endif;                    
                endif;
                if %trim(objaut.oaexec) = 'X';
                    objaut.oaexec = 'YES';
                    if %trim(objaut.oaexec) <> %trim(lst.DATA_EXEC);
                        snd-msg 'oaexec:' + %trim(objaut.oaexec) + '  ' + %trim(lst.DATA_EXEC);
                        grtcmdstr = %trimr(grtcmdstr) + ' *EXECUTE';
                    endif;
                else;
                    objaut.oaexec = 'NO';
                    if %trim(objaut.oaexec) <> %trim(lst.DATA_EXEC);
                        snd-msg 'oaexec:' + %trim(objaut.oaexec) + '  ' + %trim(lst.DATA_EXEC);
                        rvkcmdstr = %trimr(rvkcmdstr) + ' *EXECUTE';
                    endif;                    
                endif;
                grtcmdstr = %trim(grtcmdstr) + ') REPLACE(*YES)';
                rvkcmdstr = %trim(rvkcmdstr) + ')';
                logsts = 'C';
                logtxt = 'Grant command: ' + %trim(grtcmdstr);
                writelog(logsts : logtxt);
                returnCode = syscmd(grtcmdstr);
                logsts = 'C';
                logtxt = 'Revoke command: ' + %trim(rvkcmdstr);
                writelog(logsts : logtxt);
                returnCode = syscmd(rvkcmdstr);  
                clear grtcmdstr;
                clear rvkcmdstr;
            endif;
        else; // file exist, current not exist, so grant
            grtcmdstr = 'GRTOBJAUT OBJ(' + %trim(objaut.oalib) + 
                            '/' + %trim(objaut.oaname) + 
                            ') OBJTYPE(' + %trim(objaut.oatype) + 
                            ') USER(' + %trim(objaut.oausr) + 
                            ') AUT(';
            rvkcmdstr = 'RVKOBJAUT OBJ(' + %trim(objaut.oalib) + 
                            '/' + %trim(objaut.oaname) + 
                            ') OBJTYPE(' + %trim(objaut.oatype) + 
                            ') USER(' + %trim(objaut.oausr) + 
                            ') AUT(';
            if %trim(objaut.oaopr) = 'X';
                objaut.oaopr = 'YES';
                grtcmdstr = %trimr(grtcmdstr) + ' *OBJOPR';
            else;
                objaut.oaopr = 'NO';
                rvkcmdstr = %trimr(rvkcmdstr) + ' *OBJOPR';
            endif;
            if %trim(objaut.oaomgt) = 'X';
                objaut.oaomgt = 'YES';
                grtcmdstr = %trimr(grtcmdstr) + ' *OBJMGT';
            else;
                objaut  = 'NO';
                rvkcmdstr = %trimr(rvkcmdstr) + ' *OBJMGT';
            endif;
            if %trim(objaut.oaexs) = 'X';
                objaut.oaexs = 'YES';
                grtcmdstr = %trimr(grtcmdstr) + ' *OBJEXIST';
            else;
                objaut.oaexs = 'NO';
                rvkcmdstr = %trimr(rvkcmdstr) + ' *OBJEXIST';
            endif;
            if %trim(objaut.oaalt) = 'X';
                objaut.oaalt = 'YES';
                grtcmdstr = %trimr(grtcmdstr) + ' *OBJALTER';
            else;
                objaut.oaalt = 'NO';
                rvkcmdstr = %trimr(rvkcmdstr) + ' *OBJALTER';
            endif;
            if %trim(objaut.oaref) = 'X';
                objaut.oaref = 'YES';
                grtcmdstr = %trimr(grtcmdstr) + ' *OBJREF';
            else;
                objaut.oaref = 'NO';
                rvkcmdstr = %trimr(rvkcmdstr) + ' *OBJREF';
            endif;
            if %trim(objaut.oaread) = 'X';
                objaut.oaread = 'YES';
                grtcmdstr = %trimr(grtcmdstr) + ' *READ';
            else;
                objaut.oaread = 'NO';
                rvkcmdstr = %trimr(rvkcmdstr) + ' *READ';
            endif;
            if %trim(objaut.oaadd) = 'X';
                objaut.oaadd = 'YES';
                grtcmdstr = %trimr(grtcmdstr) + ' *ADD';
            else;
                objaut.oaadd = 'NO';
                rvkcmdstr = %trimr(rvkcmdstr) + ' *ADD';
            endif;
            if %trim(objaut.oaupd) = 'X';
                objaut.oaupd = 'YES';
                grtcmdstr = %trimr(grtcmdstr) + ' *UPD';
            else;
                objaut.oaupd = 'NO';
                rvkcmdstr = %trimr(rvkcmdstr) + ' *UPD';
            endif;
            if %trim(objaut.oadlt) = 'X';
                objaut.oadlt = 'YES';
                grtcmdstr = %trimr(grtcmdstr) + ' *DLT';
            else;
                objaut.oadlt = 'NO';
                rvkcmdstr = %trimr(rvkcmdstr) + ' *DLT';
            endif;
            if %trim(objaut.oaexec) = 'X';
                objaut.oaexec = 'YES';
                grtcmdstr = %trimr(grtcmdstr) + ' *EXECUTE';
            else;
                objaut.oaexec = 'NO';
                rvkcmdstr = %trimr(rvkcmdstr) + ' *EXECUTE';
            endif;
            grtcmdstr = %trim(grtcmdstr) + ') REPLACE(*YES)';
            rvkcmdstr = %trim(rvkcmdstr) + ')';
            logsts = 'C';
            logtxt = 'Grant command: ' + %trim(grtcmdstr);
            writelog(logsts : logtxt);
            returnCode = syscmd(grtcmdstr);    
            clear grtcmdstr;
            clear rvkcmdstr;
        endif;
        clear lst;
        exec sql fetch next from lst into :objaut.oalib, :objaut.oaname,
                                  :objaut.oatype, :objaut.oausr,
                                  :objaut.oaobja, :objaut.oaown,
                                  :objaut.oaanam, :objaut.oagrpn,
                                  :objaut.oaopr, :objaut.oaomgt,
                                  :objaut.oaexs, :objaut.oaalt,
                                  :objaut.oaref, :objaut.oaread,
                                  :objaut.oaadd, :objaut.oaupd,
                                  :objaut.oadlt, :objaut.oaexec;
    endif;
enddo;
exec sql close lst;

clear objaut;
clear lst;
stmt = 'select sys_dname, sys_oname, objtype, USER_NAME ' +
            'from qsys2.object_privileges ' +
            'where sys_dname = ? ';
exec sql prepare nxtcurlst from :stmt;
exec sql declare curlst cursor for nxtcurlst;
exec sql open curlst using :objschema;
exec sql fetch next from curlst into :lst.sys_dname, :lst.sys_oname,
                                  :lst.objtype, :lst.user_name;
dow sqlcod = 0;
    if sqlcod = 0;
        if %trim(lst.sys_oname) = 'ADDMIGS73' and %trim(lst.user_name) = 'QSECOFR';
            snd-msg 'Warning!';
        endif;
        stmt = 'select oalib, oaname, ' +
                        'oatype, oausr ' +
                        'from ddscinfo.objaut ' +
                        'where oalib = ? and ' +
                        'oaname = ? and ' +
                        'oatype = ? and ' +
                        'oausr = ? ';
        exec sql prepare nxtfillst from :stmt;
        exec sql declare fillst cursor for nxtfillst;
        exec sql open fillst using :lst.sys_dname,:lst.sys_oname,:lst.objtype,:lst.user_name;
        exec sql fetch next from fillst into :objaut.oalib, :objaut.oaname,
                                  :objaut.oatype, :objaut.oausr;
        if sqlcod = 0; // current exist, file exist, compare
        else; // current exist, file not exist
            if %trim(lst.sys_oname) = 'ADDMIGS73' and %trim(lst.user_name) = 'QSECOFR';
                snd-msg 'Warning2!';
            endif;
            grtcmdstr = 'GRTOBJAUT OBJ(' + %trim(lst.sys_dname) + 
                            '/' + %trim(lst.sys_oname) + 
                            ') OBJTYPE(' + %trim(lst.objtype) + 
                            ') USER(' + %trim(lst.user_name) + 
                            ') AUT(';
            rvkcmdstr = 'RVKOBJAUT OBJ(' + %trim(lst.sys_dname) + 
                            '/' + %trim(lst.sys_oname) + 
                            ') OBJTYPE(' + %trim(lst.objtype) + 
                            ') USER(' + %trim(lst.user_name) + 
                            ') AUT(*ALL)';
            logsts = 'C';
            logtxt = 'Revoke command: ' + %trim(rvkcmdstr);
            writelog(logsts : logtxt);
            returnCode = syscmd(rvkcmdstr);
            clear grtcmdstr;
            clear rvkcmdstr;
        endif;
        clear objaut;
        exec sql close fillst;
        exec sql fetch next from curlst into :lst.sys_dname, :lst.sys_oname,
                                  :lst.objtype, :lst.user_name;
    endif;
enddo;
exec sql close curlst;
snd-msg 'tot_count: ' + %trim(%char(tot_count));
*inlr = *on;
return;

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
        logLocation = '/home/autcmp_' + %trim(cur_sysnm) + 
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