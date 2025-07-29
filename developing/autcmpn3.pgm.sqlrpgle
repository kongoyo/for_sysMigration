**free
ctl-opt option(*srcstmt) dftactgrp(*no) alwnull(*usrctl) datfmt(*iso);
// usage: call steve/autcmpn3 ('steve' 'all')
dcl-pi *n;
    option_lib char(10);
    option char(6); // ALL,OWNER,AUTL,OBJAUT
end-pi;
dcl-s stmt char(1500);
dcl-s savvol char(71);
exec sql set option commit = *none;
// Upper input parameter
option_lib = %upper(%trim(option_lib));     // Library
option = %upper(%trim(option));             // Option

writelog('T': 'Process Start. Lib: ' + %trim(option_lib) + ' Opt: ' + %trim(option));
// Check input parameter
if %trim(option_lib) = '';
    writelog('E': 'Library name not found. Quit...');
    *inlr = *on;
    return;
endif;
if %trim(option) <> 'RESET' and %trim(option) <> 'OWNER' and %trim(option) <> 'AUTL' and %trim(option) <> 'OBJAUT' and %trim(option) <> 'ALL';
    writelog('E': 'Option not found. Quit...');
    *inlr = *on;
    return;
endif;
// count total number of selected objects
totcnt(option_lib);
// generate file for current system
gencurfil(option_lib);
// get save volume
getsavvol(option_lib: savvol);
writelog('C': 'option_lib: ' + %trim(option_lib) + '  original_file: ' + %trim(savvol));
// generate file for option_lib in original system
exec sql drop table ddscinfo.objautfil if exists;
stmt = 'create table ddscinfo.objautfil as ( ' +
        'select * from ddscinfo.' + %trim(savvol) + ' ' +
        'where sys_dname = ''' + %trim(option_lib) + ''' ) with data';
exec sql prepare pregenfil from :stmt;
exec sql execute pregenfil;
// process selections
select;
    // query original system, owner diff
    when option = 'OWNER';
        processOwner();
    // query original system, autl diff
    when option = 'AUTL';
        processAutl();
    // query original system, objaut diff
    when option = 'OBJAUT';
        processObjaut();
    // query original system, all diff
    when option = 'ALL';
        processOwner();
        gencurfil(option_lib);
        processAutl();
        gencurfil(option_lib);
        processObjaut();
    other;
endsl;

writelog('E': 'Process Finished.');
*inlr = *on;
return;

dcl-proc autfix;
    dcl-pi *n;
        option char(6);
    end-pi;
    dcl-ds workfil extname('DDSCINFO/WORKFIL') qualified end-ds;
    dcl-s cmdstr char(800);
    dcl-s returnCode int(10);
    dcl-pr syscmd int(10) ExtProc('system');
        *n Pointer Value Options(*String);
    end-pr;
    exec sql declare workfil cursor for 
            select src_lib,src_obj,src_type,src_usr,src_autl,
                    src_objaut,src_owner,src_objopr,src_objmgt, 
                    src_objexs,src_objalt,src_objref,src_read, 
                    src_add,src_upd,src_del,src_exec,
                    tgt_lib,tgt_obj,tgt_type,tgt_usr,tgt_autl,
                    tgt_objaut,tgt_owner,tgt_objopr,tgt_objmgt,
                    tgt_objexs,tgt_objalt,tgt_objref,tgt_read,
                    tgt_add,tgt_upd,tgt_del,tgt_exec 
                    from ddscinfo.workfil;

    exec sql open workfil;

    select;
        when option = 'OWNER';
            dow '1';
                exec sql fetch next from workfil into :workfil;
                if sqlcod <> 0; leave; endif;
                cmdstr = 'CHGOBJOWN OBJ(' + %trim(workfil.src_lib) + '/' + %trim(workfil.src_obj) +
                         ') OBJTYPE(' + %trim(workfil.src_type) +
                         ') NEWOWN(' + %trim(workfil.src_owner) + ')';
                writelog('C': 'CMD: ' + %trim(cmdstr));
                returnCode = syscmd(cmdstr);
                if returnCode <> 0;
                    writelog('E': 'CMD Failed. RC=' + %char(returnCode));
                endif;
            enddo;
        when option = 'AUTL';
            dow '1';
                exec sql fetch next from workfil into :workfil;
                if sqlcod <> 0; leave; endif;
                cmdstr = 'GRTOBJAUT OBJ(' + %trim(workfil.src_lib) + '/' + %trim(workfil.src_obj) +
                         ') OBJTYPE(' + %trim(workfil.src_type) +
                         ') AUTL(' + %trim(workfil.src_autl) + ')';
                writelog('C': 'CMD: ' + %trim(cmdstr));
                returnCode = syscmd(cmdstr);
                if returnCode <> 0;
                    writelog('E': 'CMD Failed. RC=' + %char(returnCode));
                endif;
            enddo;
        when option = 'OBJAUT';
            dow '1';
                exec sql fetch next from workfil into :workfil;
                if sqlcod <> 0; leave; endif;
                if workfil.src_objaut <> 'USER DEFINED';
                    cmdstr = 'GRTOBJAUT OBJ(' + %trim(workfil.src_lib) + '/' + %trim(workfil.src_obj) +
                             ') OBJTYPE(' + %trim(workfil.src_type) + ') USER(' + %trim(workfil.src_usr) +
                             ') AUT(' + %trim(workfil.src_objaut) + ') REPLACE(*YES)';
                elseif workfil.src_objaut = 'USER DEFINED';
                    cmdstr = 'GRTOBJAUT OBJ(' + %trim(workfil.src_lib) + '/' + %trim(workfil.src_obj) +
                             ') OBJTYPE(' + %trim(workfil.src_type) + ') USER(' + %trim(workfil.src_usr) +
                             ') AUT(';
                    if workfil.SRC_OBJOPR = 'YES'; cmdstr = %trimr(cmdstr) + ' *OBJOPR'; endif;
                    if workfil.SRC_OBJMGT = 'YES'; cmdstr = %trimr(cmdstr) + ' *OBJMGT'; endif;
                    if workfil.SRC_OBJEXS = 'YES'; cmdstr = %trimr(cmdstr) + ' *OBJEXIST'; endif;
                    if workfil.SRC_OBJALT = 'YES'; cmdstr = %trimr(cmdstr) + ' *OBJALTER'; endif;
                    if workfil.SRC_OBJREF = 'YES'; cmdstr = %trimr(cmdstr) + ' *OBJREF'; endif;
                    if workfil.SRC_READ = 'YES'; cmdstr = %trimr(cmdstr) + ' *READ'; endif;
                    if workfil.SRC_ADD = 'YES'; cmdstr = %trimr(cmdstr) + ' *ADD'; endif;
                    if workfil.SRC_UPD = 'YES'; cmdstr = %trimr(cmdstr) + ' *UPD'; endif;
                    if workfil.SRC_DEL = 'YES'; cmdstr = %trimr(cmdstr) + ' *DLT'; endif;
                    if workfil.SRC_EXEC = 'YES'; cmdstr = %trimr(cmdstr) + ' *EXECUTE'; endif;
                    cmdstr = %trimr(cmdstr) + ') REPLACE(*YES)';
                endif;
                writelog('C': 'CMD: ' + %trim(cmdstr));
                returnCode = syscmd(cmdstr);
                if returnCode <> 0;
                    writelog('E': 'CMD Failed. RC=' + %char(returnCode));
                endif;
            enddo;
    endsl;

    exec sql close workfil;
end-proc;

dcl-proc query_handler;
    dcl-pi *n;
        stmt char(1500);
    end-pi;
    dcl-s basic_stmt char(3000);
    dcl-s end_stmt char(1500);
    exec sql drop table ddscinfo.workfil if exists;
    basic_stmt =    'create table ddscinfo.workfil as ( ' +
                    'select ' + 
                    'a.sys_dname as src_lib, ' +
                    'a.sys_oname as src_obj, ' +
                    'a.objtype as src_type, ' +
                    'a.user_name as src_usr, ' +
                    'coalesce(a.autl, ''*NONE'') as src_autl, ' +
                    'a.obj_auth as src_objaut, ' +
                    'a.owner as src_owner, a.objoper as src_objopr, a.objmgt as src_objmgt, ' +
                    'a.objexist as src_objexs, a.objalter as src_objalt, a.objref as src_objref, ' +
                    'a.data_read as src_read, a.data_add as src_add, a.data_upd as src_upd, ' +
                    'a.data_del as src_del, ' +
                    'a.data_exec as src_exec, ' +
                    'coalesce(b.sys_dname, '''') as tgt_lib, ' +
                    'coalesce(b.sys_oname, '''') as tgt_obj, ' +
                    'coalesce(b.objtype, '''') as tgt_type, ' +
                    'coalesce(b.user_name, '''') as tgt_usr, ' +
                    'coalesce(b.autl, ''*NONE'') as tgt_autl, ' +
                    'coalesce(b.obj_auth, '''') as tgt_objaut, ' +
                    'coalesce(b.owner, '''') as tgt_owner, ' +
                    'coalesce(b.objoper, '''') as tgt_objopr, ' +
                    'coalesce(b.objmgt, '''') as tgt_objmgt, ' +
                    'coalesce(b.objexist, '''') as tgt_objexs, ' + 
                    'coalesce(b.objalter, '''') as tgt_objalt, ' +
                    'coalesce(b.objref, '''') as tgt_objref, ' + 
                    'coalesce(b.data_read, '''') as tgt_read, ' +
                    'coalesce(b.data_add, '''') as tgt_add, ' + 
                    'coalesce(b.data_upd, '''') as tgt_upd, ' +
                    'coalesce(b.data_del, '''') as tgt_del, ' + 
                    'coalesce(b.data_exec, '''') as tgt_exec ' +
                    'from ddscinfo.objautfil a ' +
                    'left join ddscinfo.objautcur b ' +
                    'on a.sys_dname = b.sys_dname and a.sys_oname = b.sys_oname and ' +
                    'a.objtype = b.objtype and a.user_name = b.user_name ';
    end_stmt =      ') with data';
    exec sql prepare query from :basic_stmt || :stmt || :end_stmt;
    exec sql execute query;
    return;
end-proc;

dcl-proc totcnt;
    dcl-pi *n; 
        option_lib char(10);
    end-pi;
    dcl-s stmt char(1500);
    dcl-s tot_count packed(5:0);
    // count total number of selected objects
    clear stmt;
    stmt = 'select count(*) ' +
            'from table(qsys2.object_statistics(' +
                ' object_schema => ? ,' +
                ' objtypelist => ''*ALL'' ))';
    exec sql prepare pretotcnt from :stmt;
    exec sql declare totcnt cursor for pretotcnt;
    exec sql open totcnt using :option_lib;
    exec sql fetch next from totcnt into :tot_count;
    writelog('C': 'Total objects in library ' + %trim(option_lib) + ': ' + %char(tot_count));
    exec sql close totcnt;
    return;
end-proc;

dcl-proc processOwner;
    dcl-pi *n; end-pi;
    dcl-s stmt char(1500);
    stmt =  'where a.user_name = ''*PUBLIC'' ' +
            'and b.user_name = ''*PUBLIC'' ' +
            'and a.owner <> b.owner';
    query_handler(stmt);
    exec sql declare workfil cursor for 
            select src_lib,src_obj,src_type,src_usr,src_autl,
                    src_objaut,src_owner,src_objopr,src_objmgt, 
                    src_objexs,src_objalt,src_objref,src_read, 
                    src_add,src_upd,src_del,src_exec,
                    tgt_lib,tgt_obj,tgt_type,tgt_usr,tgt_autl,
                    tgt_objaut,tgt_owner,tgt_objopr,tgt_objmgt,
                    tgt_objexs,tgt_objalt,tgt_objref,tgt_read,
                    tgt_add,tgt_upd,tgt_del,tgt_exec 
                    from ddscinfo.workfil;
    exec sql open workfil;
    exec sql fetch next from workfil into :workfil;
    dow sqlcod = 0;
        cmdstr = 'CHGOBJOWN OBJ(' + %trim(workfil.src_lib) + '/' + %trim(workfil.src_obj) +
                         ') OBJTYPE(' + %trim(workfil.src_type) +
                         ') NEWOWN(' + %trim(workfil.src_owner) + ')';
        writelog('C': 'CMD: ' + %trim(cmdstr));
        returnCode = syscmd(cmdstr);
        if returnCode <> 0;
            writelog('E': 'CMD Failed. RC=' + %char(returnCode));
        endif;
        exec sql fetch next from workfil into :workfil;
    enddo;
    exec sql close workfil;        
end-proc;

dcl-proc processAutl;
    dcl-pi *n; end-pi;
    dcl-s stmt char(1500);
end-proc;

dcl-proc processObjaut;
    dcl-pi *n; end-pi;
    dcl-s stmt char(1500);
end-proc;
    

dcl-proc gencurfil;
    dcl-pi *n;
        option_lib char(10);
    end-pi;
    dcl-s stmt char(1500);
    exec sql drop table ddscinfo.objautcur if exists;
    // generate file for current system
    stmt = 'create table ddscinfo.objautcur as ( ' +
       'select * from qsys2.obj_priv where sys_dname = ''' + %trim(option_lib) + ''' ) with data';
    exec sql prepare pregencur from :stmt;
    exec sql execute pregencur;
    return;
end-proc;

dcl-proc getsavvol;
    dcl-pi *n;
        option_lib char(10);
        savvol char(71);
    end-pi;
    dcl-s stmt char(1500);
    dcl-s cur_sysnm char(8) static;
    // create temp file to compare
    clear stmt;
    stmt = 'select coalesce(save_volume,''*NONE'') as save_volume ' +
        'from table(qsys2.object_statistics( ' +
        'object_schema => ''' + %trim(option_lib) + ''', ' +
        'objtypelist => ''*LIB''))';
    exec sql prepare pregetvol from :stmt;
    exec sql declare getvol cursor for pregetvol;
    exec sql open getvol;
    exec sql fetch next from getvol into :savvol;
    snd-msg 'save_volume: ' + %trim(savvol);
    if %trim(savvol) = '*NONE';
        exec sql values current server into :cur_sysnm;
        savvol = 'OBJAUT' + %subst(%trim(cur_sysnm) : 3 : 3);
    else;
        savvol = 'OBJAUT' + %subst(%trim(savvol) : 1 : 3);
    endif;
    exec sql close getvol;
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
        // test only
        if %scan('CLARK' : %trim(cur_sysnm)) = 1;
            cur_sysnm = 'KSG01N';
        endif;
        // test only
    endif;
    if %len(%trim(logLocation)) = 0;
        logLocation = '/home/autcmpn_' + %trim(cur_sysnm) + 
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
