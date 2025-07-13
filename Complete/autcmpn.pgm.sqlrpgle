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
//
dcl-s stmt char(1500);
dcl-s tot_count packed(5:0);
dcl-s err_count packed(5:0);
dcl-s save_volume char(6);
dcl-s list_libfilnm char(21);
// Main procedure
clear tot_count;
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
stmt = 'select sys_dname,sys_oname,objtype,user_name,obj_auth,owner,' +
            'coalesce(autl,''*NONE'') as autl,' +
            'coalesce(group,'''') as group,' +
            'autl_mgmt,obj_owner,objoper,objmgt,objexist,object_alter,object_reference,' +
            'data_read,data_add,data_upd,data_del,data_execute,' +
            'coalesce(text_description,'''') as text_description ' +
            'from qsys2.object_privileges ' +
            'where object_schema = ''QSYS'' and objtype = ''*AUTL''' + 
            'order by user_name,sys_dname,sys_oname';
            // 'where object_schema <> ''#COBLIB'' and ' +
            // 'object_schema <> ''#LIBRARY'' and ' +
            // 'object_schema <> ''#RPGLIB'' and ' +
            // 'object_schema <> ''DDSCINFO'' and ' +
            // 'object_schema not like ''Q%'' and ' +
            // 'object_schema <> ''SYSIBM'' and ' +
            // 'object_schema <> ''SYSIBMADM'' and ' +
            // 'object_schema <> ''SYSPROC'' and ' +
            // 'object_schema <> ''SYSTOOLS'' and ' +

    //
exec sql prepare preautcur from :stmt;
exec sql declare autcur cursor for preautcur;
exec sql open autcur;
exec sql fetch next from autcur into :sys_dname,:sys_oname,:objtype,:user_name,:obj_auth,:owner,:autl,
                                :group,:autl_mgmt,:obj_owner,:objoper,:objmgt,:objexist,:object_alter,
                                :object_reference,:data_read,:data_add,:data_upd,:data_del,:data_execute,:text_description;
dow sqlcod = 0;
    if sqlcod = 0;
        // Total count
        if user_name = '*PUBLIC';
            tot_count += 1;
        endif;
        //
        get_rst_vol(sys_dname : sys_oname : objtype : save_volume);
        //
        clear logtxt;
        logsts = 'C';
        logtxt = 'Query from current system: ' + sys_dname + ' . ' + sys_oname + 
                    ' . ' + objtype + ' . ' + user_name + ' . ' + save_volume;
        writelog(logsts : logtxt);
        //
        save_volume = '';
        list_libfilnm = 'DDSCINFO.OBJAUT' + %trim(save_volume);
        //
        rtv_file_compare(list_libfilnm:sys_dname:sys_oname:objtype:user_name:obj_auth:owner:
        autl:group:autl_mgmt:obj_owner:objoper:objmgt:objexist:object_alter:object_reference:
        data_read:data_add:data_upd:data_del:data_execute:text_description:err_count);
        //
    endif;
    exec sql fetch next from autcur into :sys_dname,:sys_oname,:objtype,:user_name,:obj_auth,:owner,:autl,
                                :group,:autl_mgmt,:obj_owner,:objoper,:objmgt,:objexist,:object_alter,
                                :object_reference,:data_read,:data_add,:data_upd,:data_del,:data_execute,:text_description;
enddo;
exec sql close autcur;
snd-msg 'Total Count: ' + %trim(%char(tot_count));
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

dcl-proc rtv_file_compare;
    dcl-pi *n;
        list_libfilnm char(21);
        sys_dname char(10);
        sys_oname char(10);
        objtype char(7);
        user_name char(10);
        obj_auth char(12);
        owner char(10);
        autl char(10);
        group char(10);
        autl_mgmt char(3);
        obj_owner char(3);
        objoper char(3);
        objmgt char(3);
        objexist char(3);
        object_alter char(3);
        object_reference char(3);
        data_read char(3);
        data_add char(3);
        data_upd char(3);
        data_del char(3);
        data_execute char(3);
        text_description char(50);
        err_count packed(5:0);
    end-pi;
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
    stmt = 'select oalib,oaname,oatype,oausr,oagrpn,oaobja,oaown,' +
                'oaanam,oapgrp,oaamgt,oaopr,oaomgt,oaexs,oaalt,oaref,' +
                'oaread,oaadd,oaupd,oadlt,oaexec ' +
                'from ' + %trim(list_libfilnm) +
                ' where oalib = ? ' +
                'and oaname = ? ' +
                'and oatype = ? ' +
                'and oausr = ? ';
    exec sql prepare preautfile from :stmt;
    exec sql declare autfile cursor for preautfile;
    exec sql open autfile using :sys_dname, :sys_oname, :objtype, :user_name;
    exec sql fetch next from autfile into :oalib,:oaname,:oatype,:oausr,:oagrpn,:oaobja,:oaown,
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
            if %trim(oausr) = '*GROUP';
                oausr = %trim(oagrpn);
            endif;
            if %trim(oaobja) = 'USER DEF';
                oaobja = 'USER DEFINED';
            endif;
            if %trim(oaopr) = 'X';
                oaopr = 'YES';
            else;
                oaopr = 'NO';
            endif;
            if %trim(oaomgt) = 'X';
                oaomgt = 'YES';
            else;
                oaomgt = 'NO';
            endif;
            if %trim(oaexs) = 'X';
                oaexs = 'YES';
            else;
                oaexs = 'NO';
            endif;
            if %trim(oaread) = 'X';
                oaread = 'YES';
            else;
                oaread = 'NO';
            endif;
            if %trim(oaadd) = 'X';
                oaadd = 'YES';
            else;
                oaadd = 'NO';
            endif;
            if %trim(oaupd) = 'X';
                oaupd = 'YES';
            else;
                oaupd = 'NO';
            endif;
            if %trim(oadlt) = 'X';
                oadlt = 'YES';
            else;
                oadlt = 'NO';
            endif;
            if %trim(oaexec) = 'X';
                oaexec = 'YES';
            else;
                oaexec = 'NO';
            endif;
            if %trim(oaalt) = 'X';
                oaalt = 'YES';
            else;
                oaalt = 'NO';
            endif;
            if %trim(oaref) = 'X';
                oaref = 'YES';
            else;
                oaref = 'NO';
            endif;
            if %trim(oaamgt) = 'X';
                oaamgt = 'YES';
            else;
                oaamgt = 'NO';
            endif;
            //
            select;
                when user_name = '*PUBLIC';
                    check_owner(sys_dname : sys_oname : objtype : owner : oaown);
                    check_autl(sys_dname : sys_oname : objtype : autl : oaanam);
                    check_objaut(sys_dname : sys_oname : objtype : user_name : obj_auth : 
                    autl_mgmt : objoper : objmgt : objexist : object_alter : object_reference : 
                    data_read : data_add : data_upd : data_del : data_execute :
                    oaobja : oaamgt : oaopr : oaomgt : oaexs : oaalt : oaref : oaread : oaadd :
                    oaupd : oadlt : oaexec);
                when user_name <> '*PUBLIC';
                    if 
                    check_objaut(sys_dname : sys_oname : objtype : user_name : obj_auth : 
                    autl_mgmt : objoper : objmgt : objexist : object_alter : object_reference : 
                    data_read : data_add : data_upd : data_del : data_execute :
                    oaobja : oaamgt : oaopr : oaomgt : oaexs : oaalt : oaref : oaread : oaadd :
                    oaupd : oadlt : oaexec);
                other;
            endsl;
            //  
        endif;
        exec sql fetch next from autfile into :oalib,:oaname,:oatype,:oausr,:oagrpn,:oaobja,:oaown,
                                    :oaanam,:oapgrp,:oaamgt,:oaopr,:oaomgt,:oaexs,:oaalt,:oaref,
                                    :oaread,:oaadd,:oaupd,:oadlt,:oaexec;
    enddo;
    exec sql close autfile;
    return;
end-proc;

dcl-proc check_owner;
    dcl-pi *n;
        sys_dname char(10);
        sys_oname char(10);
        objtype char(7);
        owner char(10);
        oaown char(10);
    end-pi;
    dcl-pr syscmd int(10) ExtProc('system');
        *n Pointer Value Options(*String);
    end-pr;
    //
    dcl-s cmdstr char(500) inz('');
    dcl-s returnCode int(3);
    dcl-s logsts char(1); // T: Log Title  C: Log Continue  E: Log Ending
    dcl-s logtxt char(1500);
    //
    if %trim(owner) <> %trim(oaown);
        cmdstr = 'CHGOBJOWN OBJ(' + %trim(sys_dname) + '/' +
                    %trim(sys_oname) + ') OBJTYPE(' + %trim(objtype) +
                    ') NEWOWN(' + %trim(oaown) + ')' ;
        returnCode = syscmd(cmdstr);
        clear logtxt;
        logsts = 'C';
        logtxt = '-  Owner Diff : Before - ' + %trim(owner) + ' After - ' + %trim(oaown);
        writelog(logsts : logtxt);
        if returnCode <> 0;
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
        sys_dname char(10);
        sys_oname char(10);
        objtype char(7);
        autl char(10);
        oaanam char(10);
    end-pi;
    dcl-pr syscmd int(10) ExtProc('system');
        *n Pointer Value Options(*String);
    end-pr;
    //
    dcl-s cmdstr char(500) inz('');
    dcl-s returnCode int(3);
    dcl-s logsts char(1); // T: Log Title  C: Log Continue  E: Log Ending
    dcl-s logtxt char(1500);
    //
    if %trim(autl) <> %trim(oaanam);
        cmdstr = 'GRTOBJAUT OBJ(' + %trim(sys_dname) + '/' +
                    %trim(sys_oname) + ') OBJTYPE(' + %trim(objtype) +
                    ') AUTL(' + %trim(oaanam) + ')' ;
        returnCode = syscmd(cmdstr);
        clear logtxt;
        logsts = 'C';
        logtxt = '-  Authority List Diff : Before - ' + %trim(autl) + ' After - ' + %trim(oaanam);
        writelog(logsts : logtxt);
        if returnCode <> 0;
            clear logtxt;
            logsts = 'C';
            logtxt = '*** ERROR *** : ' + %trim(cmdstr);
            writelog(logsts : logtxt);
        endif;
    endif;
    return;
end-proc;

dcl-proc check_objaut;
    dcl-pi *n;
        sys_dname char(10);
        sys_oname char(10);
        objtype char(7);
        user_name char(10);
        obj_auth char(12);
        autl_mgmt char(3);
        objoper char(3);
        objmgt char(3);
        objexist char(3);
        object_alter char(3);
        object_reference char(3);
        data_read char(3);
        data_add char(3);
        data_upd char(3);
        data_del char(3);
        data_execute char(3);
        oaobja char(12);
        oaamgt char(3);
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
    end-pi;
    dcl-pr syscmd int(10) ExtProc('system');
        *n Pointer Value Options(*String);
    end-pr;
    //
    dcl-s cmdstr char(500) inz('');
    dcl-s returnCode int(3);
    dcl-s logsts char(1); // T: Log Title  C: Log Continue  E: Log Ending
    dcl-s logtxt char(1500);
    //  
    select;
        when objtype = '*AUTL';
            if %trim(autl_mgmt) <> %trim(oaamgt) or %trim(obj_auth) <> %trim(oaobja) or 
                %trim(objoper) <> %trim(oaopr) or %trim(objmgt) <> %trim(oaomgt) or 
                %trim(objexist) <> %trim(oaexs) or %trim(object_alter) <> %trim(oaalt) or 
                %trim(object_reference) <> %trim(oaref) or %trim(data_read) <> %trim(oaread) or 
                %trim(data_add) <> %trim(oaadd) or %trim(data_upd) <> %trim(oaupd) or 
                %trim(data_del) <> %trim(oadlt) or %trim(data_execute) <> %trim(oaexec);
                cmdstr = 'CHGAUTLE AUTL(' + %trim(sys_oname) + ') + ') USER(' + %trim(user_name) +
                    ') AUT(';
                if %trim(oaamgt) = 'YES';
                    cmdstr = %trimr(cmdstr) + ' *AUTLMGT';
                endif;
                if %trim(objoper) = 'YES';
                    cmdstr = %trimr(cmdstr) + ' *OBJOPR';
                endif;
                if %trim(objmgt) = 'YES';
                    cmdstr = %trimr(cmdstr) + ' *OBJMGT';
                endif;
                if %trim(objexist) = 'YES';
                    cmdstr = %trimr(cmdstr) + ' *OBJEXIST';
                endif;
                if %trim(object_alter) = 'YES';
                    cmdstr = %trimr(cmdstr) + ' *OBJALTER';
                endif;
                if %trim(object_reference) = 'YES';
                    cmdstr = %trimr(cmdstr) + ' *OBJREF';
                endif;
                if %trim(data_read) = 'YES';
                    cmdstr = %trimr(cmdstr) + ' *READ';
                endif;
                if %trim(data_add) = 'YES';
                    cmdstr = %trimr(cmdstr) + ' *ADD';
                endif;
                if %trim(data_upd) = 'YES';
                    cmdstr = %trimr(cmdstr) + ' *UPD';
                endif;
                if %trim(data_del) = 'YES';
                    cmdstr = %trimr(cmdstr) + ' *DLT';
                endif;
                if %trim(data_execute) = 'YES';
                    cmdstr = %trimr(cmdstr) + ' *EXECUTE';
                endif;
                cmdstr = %trimr(cmdstr) + ')';
                returnCode = syscmd(cmdstr);
                clear logtxt;
                logsts = 'C';
                logtxt = '-  Authority List mgmt Diff : Before - ' + %trim(autl_mgmt) + ' After - ' + %trim(oaamgt);
                writelog(logsts : logtxt);
                if returnCode <> 0;
                    clear logtxt;
                    logsts = 'C';
                    logtxt = '*** ERROR *** : ' + %trim(cmdstr);
                    writelog(logsts : logtxt);
                endif;
            endif;
        when objtype <> '*AUTL';
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
                        returnCode = syscmd(cmdstr);
                        clear logtxt;
                        logsts = 'C';
                        logtxt = '-  Authority Diff : Before - ' + %trim(obj_auth) + ' After - ' + %trim(oaobja);
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
                        if %trim(objoper) = 'YES';
                            cmdstr = %trimr(cmdstr) + '*OBJOPR';
                        endif;
                        if %trim(objmgt) = 'YES';
                            cmdstr = %trimr(cmdstr) + '*OBJMGT';
                        endif;
                        if %trim(objexist) = 'YES';
                            cmdstr = %trimr(cmdstr) + '*OBJEXIST';
                        endif;
                        if %trim(object_alter) = 'YES';
                            cmdstr = %trimr(cmdstr) + '*OBJALTER';
                        endif;
                        if %trim(object_reference) = 'YES';
                            cmdstr = %trimr(cmdstr) + '*OBJREF';
                        endif;
                        if %trim(data_read) = 'YES';
                            cmdstr = %trimr(cmdstr) + '*READ';
                        endif;
                        if %trim(data_add) = 'YES';
                            cmdstr = %trimr(cmdstr) + '*ADD';
                        endif;
                        if %trim(data_upd) = 'YES';
                            cmdstr = %trimr(cmdstr) + '*UPD';
                        endif;
                        if %trim(data_del) = 'YES';
                            cmdstr = %trimr(cmdstr) + '*DLT';
                        endif;
                        if %trim(data_execute) = 'YES';
                            cmdstr = %trimr(cmdstr) + '*EXECUTE';
                        endif;
                        cmdstr = %trimr(cmdstr) + ')';
                        returnCode = syscmd(cmdstr);
                        clear logtxt;
                        logsts = 'C';
                        logtxt = '-  Authority Diff : Before - ' + %trim(obj_auth) + ' After - ' + %trim(oaobja);
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
        other;
    endsl;
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
