**FREE
// CALL PGM(STEVE/AUTCMPN)
// scan current system object
// get object restore volume and determine which original system to check for authority
// get object authority from file
// if found, then change current system object authority
//
ctl-opt option(*srcstmt) dftactgrp(*no);
//
dcl-s logsts char(1); // T: Log Title  C: Log Continue  E: Log Ending
dcl-s logtxt char(1500);
// object authority related parameters
dcl-s sys_dname char(10);
dcl-s sys_oname char(10);
dcl-s objtype char(7);
dcl-s user_name char(10);
dcl-s obj_auth char(12);
dcl-s owner char(10);
dcl-s autl char(10);
dcl-s group char(10);
dcl-s autl_mgmt char(3);
dcl-s obj_owner char(3);
dcl-s objoper char(3);
dcl-s objmgt char(3);
dcl-s objexist char(3);
dcl-s object_alter char(3);
dcl-s object_reference char(3);
dcl-s data_read char(3);
dcl-s data_add char(3);
dcl-s data_upd char(3);
dcl-s data_del char(3);
dcl-s data_execute char(3);
dcl-s text_description char(50);
// object authority from file
dcl-s oalib char(10);
dcl-s oaname char(10);
dcl-s oatype char(7);
dcl-s oausr char(10);
dcl-s oagrpn char(10);
dcl-s oaobja char(12);
dcl-s oaown char(10);
dcl-s oapgrp char(10);
dcl-s oaanam char(10);
dcl-s oaamgt char(3);
dcl-s oaopr char(3);
dcl-s oaomgt char(3);
dcl-s oaexs char(3);
dcl-s oaalt char(3);
dcl-s oaref char(3);
dcl-s oaread char(3);
dcl-s oaadd char(3);
dcl-s oaupd char(3);
dcl-s oadlt char(3);
dcl-s oaexec char(3);
//
dcl-s stmt char(1500);
dcl-s tot_count packed(5:0);
dcl-s err_count packed(5:0);
dcl-s chg_count packed(5:0);
dcl-s list_libfilnm char(21);
dcl-s save_volume char(6);
// Main procedure
clear tot_count;
clear chg_count;
clear err_count;
//
clear logtxt;
logsts = 'T';
writelog(logsts : logtxt);
//
clear logtxt;
logsts = 'C';
logtxt = 'Authority comparison job start';
writelog(logsts : logtxt);
//
stmt = 'select sys_dname, sys_oname, objtype ' +
            'from qsys2.object_privileges ' +
            'where user_name = ''*PUBLIC'' ' +
            // 'object_schema = ''QSYS'' and ' + 
            // 'objtype = ''*AUTL'' ' + 
            // 'where object_schema <> ''#COBLIB'' and ' +
            // 'object_schema <> ''#LIBRARY'' and ' +
            // 'object_schema <> ''#RPGLIB'' and ' +
            // 'object_schema <> ''DDSCINFO'' and ' +
            // 'object_schema not like ''Q%'' and ' +
            // 'object_schema <> ''SYSIBM'' and ' +
            // 'object_schema <> ''SYSIBMADM'' and ' +
            // 'object_schema <> ''SYSPROC'' and ' +
            // 'object_schema <> ''SYSTOOLS'' and ' +
            'order by sys_dname, sys_oname';
            //
exec sql prepare preautcur from :stmt;
exec sql declare autcur cursor for preautcur;
exec sql open autcur;
exec sql fetch next from autcur into :sys_dname,:sys_oname,:objtype;
dow sqlcod = 0;
    if sqlcod = 0;
        tot_count += 1;
        //
        get_rst_vol(sys_dname : sys_oname : objtype : save_volume);
        //
        clear logtxt;
        logsts = 'C';
        logtxt = 'Query from current system: ' + sys_dname + ' . ' + sys_oname + 
                    ' . ' + objtype + ' . ' + user_name + ' . Volume: ' + save_volume;
        writelog(logsts : logtxt);
        // defined file
        save_volume = '';
        list_libfilnm = 'DDSCINFO.OBJAUT' + %trim(save_volume);
        // search from file
        stmt = 'select oalib, oaname, oatype, oausr, oagrpn, oaobja, oaown,' +
                'oaanam, oapgrp, oaamgt, oaopr, oaomgt, oaexs, oaalt, oaref,' +
                'oaread, oaadd, oaupd, oadlt, oaexec ' +
                'from ' + %trim(list_libfilnm) + ' ' +
                'where oalib = ? ' +
                'and oaname = ? ' +
                'and oatype = ? ' +
                'order by oausr';                   
        exec sql prepare preautfile from :stmt;
        exec sql values(:stmt) into :oalib,:oaname,:oatype,:oausr,:oagrpn,:oaobja,:oaown,
                                    :oaanam,:oapgrp,:oaamgt,:oaopr,:oaomgt,:oaexs,:oaalt,:oaref,
                                    :oaread,:oaadd,:oaupd,:oadlt,:oaexec;
        dow sqlcod = 0;
            if sqlcod = 0;
                //
                clear logtxt;
                logsts = 'C';
                logtxt = 'Query from file          : ' + oalib  + ' . ' + oaname + ' . ' + oatype + ' . ' + oausr;
                writelog(logsts : logtxt);
                //
                check_owner(oalib : oaname : oatype : oaown : chg_count : err_count);
                check_autl(oalib : oaname : oatype : oaanam : chg_count : err_count);
                if %trim(objtype) = '*AUTL';
                    check_autlist(oalib : oaname : oatype : oausr : oaobja : oaamgt : chg_count : err_count);
                else;
                    check_objaut(oalib : oaname : oatype : oaobja : oaopr : oaomgt : 
                            oaexs : oaalt : oaref : oaread : oaadd : oaupd : oadlt : 
                            oaexec : chg_count : err_count);
                endif;
                //  
            endif;
            exec sql fetch next from autfile into :oalib,:oaname,:oatype,:oausr,:oagrpn,:oaobja,:oaown,
                                    :oaanam,:oapgrp,:oaamgt,:oaopr,:oaomgt,:oaexs,:oaalt,:oaref,
                                    :oaread,:oaadd,:oaupd,:oadlt,:oaexec;
        enddo;
        exec sql close autfile;
        //
    endif;
    exec sql fetch next from autcur into :sys_dname,:sys_oname,:objtype;
enddo;
exec sql close autcur;
snd-msg 'Total Count: ' + %trim(%char(tot_count));
snd-msg 'Changed Count: ' + %trim(%char(chg_count));
snd-msg 'Error Count: ' + %trim(%char(err_count));
//
clear logtxt;
logsts = 'C';
logtxt = 'Authority comparison job end';
writelog(logsts : logtxt);
//
clear logtxt;
logsts = 'E';
writelog(logsts : logtxt);
*inlr = *on;
return;

dcl-proc get_rst_vol;
    dcl-pi *n;
        sys_dname char(10);
        sys_oname char(10);
        objtype char(7);
        save_volume char(6);
    end-pi;
    dcl-s stmt char(1500);
    dcl-s cur_sysnm char(8) static;

    //
    exec sql values(select coalesce(save_volume,'') as save_volume 
                    from table(qsys2.object_statistics(
                    object_schema => :sys_dname,
                    objtypelist => :objtype,
                    object_name => :sys_oname)))
                    into :save_volume;
    if save_volume = '';
        exec sql values current server into :cur_sysnm;
        save_volume = %subst(%trim(cur_sysnm) : 3 : 3);
    else;
        save_volume = %subst(%trim(save_volume) : 1 : 3);
    endif;
    //
    return;
end-proc;

dcl-proc check_owner;
    dcl-pi *n;
        oalib char(10);
        oaname char(10);
        oatype char(7);
        oaown char(10);
        chg_count packed(5:0);
        err_count packed(5:0);
    end-pi;
    dcl-pr syscmd int(10) ExtProc('system');
        *n Pointer Value Options(*String);
    end-pr;
    //
    dcl-s cmdstr char(500) inz('');
    dcl-s returnCode int(3);
    dcl-s logsts char(1); // T: Log Title  C: Log Continue  E: Log Ending
    dcl-s logtxt char(1500);
    dcl-s owner char(10);
    //
    exec sql values(select coalesce(owner,'') as owner from qsys2.object_privileges
                        where object_schema = :oalib
                        and object_name = :oaname
                        and object_type = :oatype
                        fetch first 1 row only)
                into :owner;
    if %trim(owner) <> %trim(oaown);
        chg_count += 1;
        cmdstr = 'CHGOBJOWN OBJ(' + %trim(oalib) + '/' +
                    %trim(oaname) + ') OBJTYPE(' + %trim(oatype) +
                    ') NEWOWN(' + %trim(oaown) + ')' ;
        // returnCode = syscmd(cmdstr);
        clear logtxt;
        logsts = 'C';
        logtxt = '-  Owner Diff : Before - ' + %trim(owner) + ' After - ' + %trim(oaown);
        writelog(logsts : logtxt);
        if returnCode <> 0;
            err_count += 1;
            clear logtxt;
            logsts = 'C';
            logtxt = '*** ERROR *** : ' + %trim(cmdstr);
            writelog(logsts : logtxt);
        endif;
    endif;
    return;
end-proc;

dcl-proc check_autl;
    dcl-pi *n;
        oalib char(10);
        oaname char(10);
        oatype char(7);
        oaanam char(10);
        chg_count packed(5:0);
        err_count packed(5:0);
    end-pi;
    dcl-pr syscmd int(10) ExtProc('system');
        *n Pointer Value Options(*String);
    end-pr;
    //
    dcl-s cmdstr char(500) inz('');
    dcl-s returnCode int(3);
    dcl-s logsts char(1); // T: Log Title  C: Log Continue  E: Log Ending
    dcl-s logtxt char(1500);
    dcl-s autl char(10);
    //
    exec sql values(select coalesce(autl,'*NONE') as autl from qsys2.object_privileges
                        where object_schema = :oalib
                        and object_name = :oaname
                        and object_type = :oatype
                        fetch first 1 row only)
                into :autl;
    if %trim(autl) <> %trim(oaanam);
        chg_count += 1;
        cmdstr = 'GRTOBJAUT OBJ(' + %trim(sys_dname) + '/' +
                    %trim(sys_oname) + ') OBJTYPE(' + %trim(objtype) +
                    ') AUTL(' + %trim(oaanam) + ')' ;
        // returnCode = syscmd(cmdstr);
        clear logtxt;
        logsts = 'C';
        logtxt = '-  Authority List Diff : Before - ' + %trim(autl) + ' After - ' + %trim(oaanam);
        writelog(logsts : logtxt);
        if returnCode <> 0;
            err_count += 1;
            clear logtxt;
            logsts = 'C';
            logtxt = '*** ERROR *** : ' + %trim(cmdstr);
            writelog(logsts : logtxt);
        endif;
    endif;
    return;
end-proc;

dcl-proc check_autlist;
    dcl-pi *n;
        oalib char(10);
        oaname char(10);
        oatype char(7);
        oausr char(10);
        oaobja char(12);
        oaamgt char(3);
        chg_count packed(5:0);
        err_count packed(5:0);
    end-pi;
    dcl-pr syscmd int(10) ExtProc('system');
        *n Pointer Value Options(*String);
    end-pr;
    //
    dcl-s cmdstr char(500) inz('');
    dcl-s returnCode int(3);
    dcl-s user_name char(10);
    dcl-s obj_auth char(12);
    dcl-s auth_mgmt char(3);
    exec sql values(select user_name, obj_auth, autl_mgmt 
                    from qsys2.object_privileges
                    where object_schema = :oalib
                    and object_name = :oaname
                    and objtype = '*AUTL'
                    and user_name = :oausr)
                    into :user_name,:obj_auth,:auth_mgmt;
    if user_name = '';
        chg_count += 1;
        clear cmdstr;
        cmdstr = 'ADDAUTLE AUTL(' + %trim(oaname) + ') USER(' + %trim(oausr) +
                    ') AUT(';
        if %trim(oaamgt) = 'X';
            cmdstr = %trimr(cmdstr) + ' *AUTLMGT';
        endif;
        if %trim(oaopr) = 'X';
            cmdstr = %trimr(cmdstr) + ' *OBJOPR';
        endif;
        if %trim(oaomgt) = 'X';
            cmdstr = %trimr(cmdstr) + ' *OBJMGT';
        endif;
        if %trim(oaexs) = 'X';
            cmdstr = %trimr(cmdstr) + ' *OBJEXIST';
        endif;
        if %trim(oaalt) = 'X';
            cmdstr = %trimr(cmdstr) + ' *OBJALTER';
        endif;
        if %trim(oaref) = 'X';
            cmdstr = %trimr(cmdstr) + ' *OBJREF';
        endif;
        if %trim(oaread) = 'X';
            cmdstr = %trimr(cmdstr) + ' *READ';
        endif;
        if %trim(oaadd) = 'X';
            cmdstr = %trimr(cmdstr) + ' *ADD';
        endif;
        if %trim(oaupd) = 'X';
            cmdstr = %trimr(cmdstr) + ' *UPD';
        endif;
        if %trim(oadlt) = 'X';
            cmdstr = %trimr(cmdstr) + ' *DLT';
        endif;
        if %trim(oaexec) = 'X';
            cmdstr = %trimr(cmdstr) + ' *EXECUTE';
        endif;
        cmdstr = %trimr(cmdstr) + ')';
        // returnCode = syscmd(cmdstr);
        clear logtxt;
        logsts = 'C';
        logtxt = '-  *AUTL Authority not found : After - ' + %trim(oausr);
        writelog(logsts : logtxt);
        if returnCode <> 0;
            err_count += 1;
            clear logtxt;
            logsts = 'C';
            logtxt = '*** ERROR *** : ' + %trim(cmdstr);
            writelog(logsts : logtxt);
        endif;
    else;
        if %trim(oaobja) <> %trim(obj_auth) or %trim(oaamgt) <> %trim(auth_mgmt);
            chg_count += 1;
            clear cmdstr;
            cmdstr = 'CHGAUTLE AUTL(' + %trim(oaname) + ') USER(' + %trim(oausr) +
                    ') AUT(';
            if %trim(oaamgt) = 'X';
                cmdstr = %trimr(cmdstr) + ' *AUTLMGT';
            endif;
            if %trim(oaopr) = 'X';
                cmdstr = %trimr(cmdstr) + ' *OBJOPR';
            endif;
            if %trim(oaomgt) = 'X';
                cmdstr = %trimr(cmdstr) + ' *OBJMGT';
            endif;
            if %trim(oaexs) = 'X';
                cmdstr = %trimr(cmdstr) + ' *OBJEXIST';
            endif;
            if %trim(oaalt) = 'X';
                cmdstr = %trimr(cmdstr) + ' *OBJALTER';
            endif;
            if %trim(oaref) = 'X';
                cmdstr = %trimr(cmdstr) + ' *OBJREF';
            endif;
            if %trim(oaread) = 'X';
                cmdstr = %trimr(cmdstr) + ' *READ';
            endif;
            if %trim(oaadd) = 'X';
                cmdstr = %trimr(cmdstr) + ' *ADD';
            endif;
            if %trim(oaupd) = 'X';
                cmdstr = %trimr(cmdstr) + ' *UPD';
            endif;
            if %trim(oadlt) = 'X';
                cmdstr = %trimr(cmdstr) + ' *DLT';
            endif;
            if %trim(oaexec) = 'X';
                cmdstr = %trimr(cmdstr) + ' *EXECUTE';
            endif;
            cmdstr = %trimr(cmdstr) + ')';
            // returnCode = syscmd(cmdstr);
            clear logtxt;
            logsts = 'C';
            logtxt = '-  *AUTL Authority Diff : ' + %trim(oaname);
            writelog(logsts : logtxt);
            if returnCode <> 0;
                err_count += 1;
                clear logtxt;
                logsts = 'C';
                logtxt = '*** ERROR *** : ' + %trim(cmdstr);
                writelog(logsts : logtxt);
            endif;
        endif;
    endif;
    return;
end-proc;

dcl-proc check_objaut;
    dcl-pi *n;
        oalib char(10);
        oaname char(10);
        oatype char(7);
        oaobja char(12);
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
        chg_count packed(5:0);
        err_count packed(5:0);
    end-pi;
    dcl-pr syscmd int(10) ExtProc('system');
        *n Pointer Value Options(*String);
    end-pr;
    //
    dcl-s cmdstr char(500) inz('');
    dcl-s returnCode int(3);
    dcl-s logsts char(1); // T: Log Title  C: Log Continue  E: Log Ending
    dcl-s logtxt char(1500);
    dcl-s objtype char(7);
    dcl-s user_name char(10);
    dcl-s obj_auth char(12);
    dcl-s objoper char(3);
    dcl-s objmgt char(3);
    dcl-s objexist char(3);
    dcl-s object_alter char(3);
    dcl-s object_reference char(3);
    dcl-s data_read char(3);
    dcl-s data_add char(3);
    dcl-s data_upd char(3);
    dcl-s data_del char(3);
    dcl-s data_execute char(3);
    //
    if %trim(obj_auth) <> %trim(oaobja) or %trim(objoper) <> %trim(oaopr) or %trim(objmgt) <> %trim(oaomgt) or 
                %trim(objexist) <> %trim(oaexs) or %trim(object_alter) <> %trim(oaalt) or %trim(object_reference) <> %trim(oaref) or 
                %trim(data_read) <> %trim(oaread) or %trim(data_add) <> %trim(oaadd) or %trim(data_upd) <> %trim(oaupd) or 
                %trim(data_del) <> %trim(oadlt) or %trim(data_execute) <> %trim(oaexec);
        select;
            when oaobja <> 'USER DEFINED';
                clear cmdstr;
                cmdstr = 'GRTOBJAUT OBJ(' + %trim(sys_dname) + '/' +
                        %trim(sys_oname) + ') OBJTYPE(' + 
                        %trim(objtype) + ') USER(' + 
                        %trim(user_name) + ') AUT(' + 
                        %trim(obj_auth) + ')' ;
                        // returnCode = syscmd(cmdstr);
                clear logtxt;
                logsts = 'C';
                logtxt = '-  Authority Diff : Before - ' + %trim(obj_auth) + ' After - ' + %trim(oaobja);
                writelog(logsts : logtxt);
                clear logtxt;
                logsts = 'C';
                logtxt = '-  Changed command : ' + %trim(cmdstr);
                writelog(logsts : logtxt);
                if returnCode <> 0;
                    clear logtxt;
                    logsts = 'C';
                    logtxt = '*** ERROR *** : ' + %trim(cmdstr);
                    writelog(logsts : logtxt);
                endif;

            when oaobja = 'USER DEFINED';
                clear cmdstr;
                cmdstr = 'GRTOBJAUT OBJ(' + %trim(sys_dname) + '/' +
                        %trim(sys_oname) + ') OBJTYPE(' + 
                        %trim(objtype) + ') USER(' + 
                        %trim(user_name) + ') AUT(';
                if %trim(oaopr) = 'X';
                    cmdstr = %trimr(cmdstr) + ' *OBJOPR';
                endif;
                if %trim(oaomgt) = 'X';
                    cmdstr = %trimr(cmdstr) + ' *OBJMGT';
                endif;
                if %trim(oaexs) = 'X';
                    cmdstr = %trimr(cmdstr) + ' *OBJEXIST';
                endif;
                if %trim(oaalt) = 'X';
                    cmdstr = %trimr(cmdstr) + ' *OBJALTER';
                endif;
                if %trim(oaref) = 'X';
                    cmdstr = %trimr(cmdstr) + ' *OBJREF';
                endif;
                if %trim(oaread) = 'X';
                    cmdstr = %trimr(cmdstr) + ' *READ';
                endif;
                if %trim(oaadd) = 'X';
                    cmdstr = %trimr(cmdstr) + ' *ADD';
                endif;
                if %trim(oaupd) = 'X';
                    cmdstr = %trimr(cmdstr) + ' *UPD';
                endif;
                if %trim(oadlt) = 'X';
                    cmdstr = %trimr(cmdstr) + ' *DLT';
                endif;
                if %trim(oaexec) = 'X';
                    cmdstr = %trimr(cmdstr) + ' *EXECUTE';
                endif;
                cmdstr = %trimr(cmdstr) + ')';
                        // returnCode = syscmd(cmdstr);
                clear logtxt;
                logsts = 'C';
                logtxt = '-  Authority Diff : Before - ' + %trim(obj_auth) + ' After - ' + %trim(oaobja);
                writelog(logsts : logtxt);
                clear logtxt;
                logsts = 'C';
                logtxt = '-  Changed command : ' + %trim(cmdstr);
                writelog(logsts : logtxt);                        
                if returnCode <> 0;
                    clear logtxt;
                    logsts = 'C';
                    logtxt = '*** ERROR *** : ' + %trim(cmdstr);
                    writelog(logsts : logtxt);
                endif;
            other;

        endsl;
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
        logLocation = '/home/autcmpn' + 
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
