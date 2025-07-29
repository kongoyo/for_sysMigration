**free
ctl-opt option(*srcstmt) dftactgrp(*no);
// usage:
dcl-pi *n;
    option_lib char(10);
end-pi;
dcl-ds objcur qualified; // 19 columns
    oalib char(10);
    oaname char(10);
    oatype char(8);
    oausr char(10);
    oagrpn char(10);
    oaobja char(8);
    oaanam char(10);
    oapgrp char(10);
    oaown char(10);
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
dcl-ds objfil likeds(objcur); // 19 columns
dcl-s cur_sysnm char(8);
dcl-s savvol char(71);
dcl-s search_file char(10);
dcl-s stmt char(1500);
dcl-s logsts char(1); // T: Log Title  C: Log Continue  E: Log Ending
dcl-s logtxt char(1500);

exec sql set option commit = *none;
// Upper input parameter
option_lib = %upper(%trim(option_lib));   // Library

if %trim(option_lib) = '*ALLUSR';
    totcnt(option_lib);
    exec sql drop table ddscinfo.objautcur if exists;
    exec sql create table ddscinfo.objautcur as (
                    select * from qsys2.obj_priv
                    ) definition only;
    clear stmt;
    stmt = 'select objname from table(qsys2.object_statistics( ' +
                'object_schema => ''*ALLUSR'', ' +
                'objtypelist => ''*LIB''))';
    exec sql prepare preliblst from :stmt;
    exec sql declare liblst cursor for preliblst;
    exec sql open liblst;
    exec sql fetch next from liblst into :option_lib;
    dow sqlcod = 0;
        if sqlcod = 0;
            gencurfil(option_lib);
            getsavvol(option_lib : savvol);
            if %trim(savvol) = '*NONE';
                exec sql values current server into :cur_sysnm;
                search_file = 'OBJAUT' + %subst(%trim(cur_sysnm) : 3 : 3);
                snd-msg 'search_file: ' + %trim(search_file);
            else;
                search_file = 'OBJAUT' + %subst(%trim(savvol) : 1 : 3);
                snd-msg 'search_file: ' + %trim(search_file);
            endif;
            compare_old_new(option_lib : search_file);
        endif;
        exec sql fetch next from liblst into :option_lib;
    enddo;
    exec sql close liblst;    
else;
    totcnt(option_lib);
    exec sql drop table ddscinfo.objautcur if exists;
    exec sql create table ddscinfo.objautcur as (
                    select * from qsys2.obj_priv
                    ) definition only;
    gencurfil(option_lib);
    getsavvol(option_lib : savvol);
    if %trim(savvol) = '*NONE';
        exec sql values current server into :cur_sysnm;
        search_file = 'OBJAUT' + %subst(%trim(cur_sysnm) : 3 : 3);
        snd-msg 'search_file: ' + %trim(search_file);
    else; 
        search_file = 'OBJAUT' + %subst(%trim(savvol) : 1 : 3);
        snd-msg 'search_file: ' + %trim(search_file);
    endif;
    compare_old_new(option_lib : search_file);
endif;
*inlr = *on;
return;

dcl-proc compare_old_new;
    dcl-pi *n;
        option_lib char(10);
        search_file char(10);
    end-pi;
    dcl-ds workfil qualified;
        oalib1     char(10);
        oaname1    char(10);
        oatype1    char(8);
        oausr1     char(10);
        oaobja1    char(8);
        oaown1     char(10);
        oaanam1    char(10);
        oaopr1     char(3);
        oaomgt1    char(3);
        oaexs1     char(3);
        oaalt1     char(3);
        oaref1     char(3);
        oaread1    char(3);
        oaadd1     char(3);
        oaupd1     char(3);
        oadlt1     char(3);
        oaexec1    char(3);
        oalib2     char(10);
        oaname2    char(10);
        oatype2    char(8);
        oausr2     char(10);
        oaobja2    char(8);
        oaown2     char(10);
        oaanam2    char(10);
        oaopr2     char(3);
        oaomgt2    char(3);
        oaexs2     char(3);
        oaalt2     char(3);
        oaref2     char(3);
        oaread2    char(3);
        oaadd2     char(3);
        oaupd2     char(3);
        oadlt2     char(3);
        oaexec2    char(3);
    end-ds;
    dcl-ds objfil likeds(objcur); // 19 columns
    dcl-s stmt char(5000);
    dcl-s cmdstr char(800);
    dcl-s returnCode int(10);
    dcl-pr syscmd int(10) ExtProc('system');
        *n Pointer Value Options(*String);
    end-pr;
    dcl-s notExist char(1) static;
    // first comparison list
    exec sql drop table qtemp.workfil1 if exists;
    clear stmt;
    stmt = 'create table qtemp.workfil1 as ' +
            '(select a.sys_dname as oalib1, a.sys_oname as oaname1, ' +
                    'a.objtype as oatype1, a.user_name as oausr1, ' +
                    'a.obj_auth as oaobja1, a.owner as oaown1, ' +
                    'coalesce(a.autl,'''') as oaanam1, a.objoper as oaopr1, ' +
                    'a.objmgt as oaomgt1, ' +
                    'a.objexist as oaexs1, a.objalter as oaalt1, ' +
                    'a.objref as oaref1, a.data_read as oaread1, ' +
                    'a.data_add as oaadd1, a.data_upd as oaupd1, ' +
                    'a.data_del as oadlt1, a.data_exec as oaexec1, ' +
                    'coalesce(b.sys_dname,'''') as oalib2, ' +
                    'coalesce(b.sys_oname,'''') as oaname2, ' +
                    'coalesce(b.objtype,'''') as oatype2, ' +
                    'coalesce(b.user_name,'''') as oausr2, ' +
                    'coalesce(b.obj_auth,'''') as oaobja2, ' +
                    'coalesce(b.owner,'''') as oaown2, ' +
                    'coalesce(b.autl,'''') as oaanam2, ' +
                    'coalesce(b.objoper,'''') as oaopr2, ' +
                    'coalesce(b.objmgt,'''') as oaomgt2, ' +
                    'coalesce(b.objexist,'''') as oaexs2, ' +
                    'coalesce(b.objalter,'''') as oaalt2, ' +
                    'coalesce(b.objref,'''') as oaref2, ' +
                    'coalesce(b.data_read,'''') as oaread2, ' + 
                    'coalesce(b.data_add,'''') as oaadd2, ' +
                    'coalesce(b.data_upd,'''') as oaupd2, ' + 
                    'coalesce(b.data_del,'''') as oadlt2, ' +
                    'coalesce(b.data_exec,'''') as oaexec2 ' +
                    'from ddscinfo.objautcur a ' +
                         'left join ddscinfo.' + %trim(search_file) + ' b ' +
                             'on a.sys_dname = b.sys_dname and ' +
                                'a.sys_oname = b.sys_oname and ' +
                                'a.objtype = b.objtype and ' + 
                                'a.user_name = b.user_name ' +
                    'where a.sys_dname = ''' + %trim(option_lib) + ''' and ' +
                            'b.sys_dname is null or b.obj_auth <> a.obj_auth or ' +
                            'b.owner <> a.owner or b.autl <> a.autl or ' +
                            'b.objoper <> a.objoper or b.objexist <> a.objexist or ' +
                            'b.objalter <> a.objalter or b.objref <> a.objref or ' +
                            'b.data_read <> a.data_read or b.data_add <> a.data_add or ' +
                            'b.data_upd <> a.data_upd or b.data_del <> a.data_del or ' +
                            'b.data_exec <> a.data_exec) with data';
    exec sql prepare precmp1 from :stmt;
    exec sql execute precmp1;
    exec sql declare workfil1 cursor for select * from qtemp.workfil1;
    exec sql open workfil1;
    exec sql fetch next from workfil1 into :workfil;
    dow sqlcod = 0;
        if sqlcod = 0;
            
                // when %trim(workfil.oausr1) = '*PUBLIC' and workfil.oaown1 <> workfil.oaown2;
                //     cmdstr = 'CHGOBJOWN OBJ(' + %trim(workfil.oalib1) +
                //                 '/' + %trim(workfil.oaname1) +
                //                 ') OBJTYPE(' + %trim(workfil.oatype1) +
                //                 ') NEWOWN(' + %trim(workfil.oaown1) + ')';
                //     snd-msg 'cmdstr: ' + %trim(cmdstr);
                // when %trim(workfil.oausr1) = '*PUBLIC' and workfil.oaanam1 <> workfil.oaanam2;
                //     cmdstr = 'GRTOBJAUT OBJ(' + %trim(workfil.oalib1) +
                //                 '/' + %trim(workfil.oaname1) +
                //                 ') OBJTYPE(' + %trim(workfil.oatype1) +
                //                 ') AUTL(' + %trim(workfil.oaanam1) + ')';
                //     snd-msg 'cmdstr: ' + %trim(cmdstr);
            if %trim(workfil.oausr1) = '*PUBLIC' and %trim(workfil.oalib2) = '';
                snd-msg 'Object not exist in file. Object is ' + %trim(workfil.oaname1) + '.';
            else;
                if %trim(workfil.oaobja1) <> 'USER DEF' and %trim(workfil.oaobja1) <> %trim(workfil.oaobja2);
                    cmdstr = 'RVKOBJAUT OBJ(' + %trim(workfil.oalib1) +
                                '/' + %trim(workfil.oaname1) +
                                ') OBJTYPE(' + %trim(workfil.oatype1) +
                                ') USER(' + %trim(workfil.oausr1) +
                                ') AUT(' + %trim(workfil.oaobja1) + ')';
                    snd-msg 'cmdstr: ' + %trim(cmdstr);
                endif;
            endif;
        endif;
        exec sql fetch next from workfil1 into :workfil;
    enddo;
    exec sql close workfil1;
    // second comparison list                    
    exec sql drop table qtemp.workfil2 if exists;
    clear stmt;
    stmt = 'create table qtemp.workfil2 as ' +
            '(select a.sys_dname as oalib1, a.sys_oname as oaname1, ' +
                    'a.objtype as oatype1, a.user_name as oausr1, ' +
                    'a.obj_auth as oaobja1, a.owner as oaown1, ' +
                    'coalesce(a.autl,'''') as oaanam1, a.objoper as oaopr1, ' +
                    'a.objmgt as oaomgt1, ' +
                    'a.objexist as oaexs1, a.objalter as oaalt1, ' +
                    'a.objref as oaref1, a.data_read as oaread1, ' +
                    'a.data_add as oaadd1, a.data_upd as oaupd1, ' +
                    'a.data_del as oadlt1, a.data_exec as oaexec1, ' +
                    'coalesce(b.sys_dname,'''') as oalib2, ' +
                    'coalesce(b.sys_oname,'''') as oaname2, ' +
                    'coalesce(b.objtype,'''') as oatype2, ' +
                    'coalesce(b.user_name,'''') as oausr2, ' +
                    'coalesce(b.obj_auth,'''') as oaobja2, ' +
                    'coalesce(b.owner,'''') as oaown2, ' +
                    'coalesce(b.autl,'''') as oaanam2, ' +
                    'coalesce(b.objoper,'''') as oaopr2, ' +
                    'coalesce(b.objmgt,'''') as oaomgt2, ' +
                    'coalesce(b.objexist,'''') as oaexs2, ' +
                    'coalesce(b.objalter,'''') as oaalt2, ' +
                    'coalesce(b.objref,'''') as oaref2, ' +
                    'coalesce(b.data_read,'''') as oaread2, ' + 
                    'coalesce(b.data_add,'''') as oaadd2, ' +
                    'coalesce(b.data_upd,'''') as oaupd2, ' + 
                    'coalesce(b.data_del,'''') as oadlt2, ' +
                    'coalesce(b.data_exec,'''') as oaexec2 ' +
                    'from ddscinfo.' + %trim(search_file) + ' a ' +
                         'left join ddscinfo.objautcur b ' +
                             'on a.sys_dname = b.sys_dname and ' +
                                'a.sys_oname = b.sys_oname and ' +
                                'a.objtype = b.objtype and ' + 
                                'a.user_name = b.user_name ' +
                    'where a.sys_dname = ''' + %trim(option_lib) + ''' and ' +
                            'b.sys_dname is null or b.obj_auth <> a.obj_auth or ' +
                            'b.owner <> a.owner or b.autl <> a.autl or ' +
                            'b.objoper <> a.objoper or b.objexist <> a.objexist or ' +
                            'b.objalter <> a.objalter or b.objref <> a.objref or ' +
                            'b.data_read <> a.data_read or b.data_add <> a.data_add or ' +
                            'b.data_upd <> a.data_upd or b.data_del <> a.data_del or ' +
                            'b.data_exec <> a.data_exec) with data';
    exec sql prepare precmp2 from :stmt;
    exec sql execute precmp2;
    exec sql declare workfil2 cursor for select * from qtemp.workfil2;
    exec sql open workfil2;
    exec sql fetch next from workfil2 into :workfil;
    dow sqlcod = 0;
        if sqlcod = 0;
            if %trim(workfil.oausr2) = '*PUBLIC';
                if %trim(workfil.oalib1) = '';
                    snd-msg 'Object not exist in system. Object is ' + %trim(workfil.oaname2) + '.';
                endif;
                if workfil.oaown1 <> workfil.oaown2;
                    cmdstr = 'CHGOBJOWN OBJ(' + %trim(workfil.oalib1) +
                                '/' + %trim(workfil.oaname1) +
                                ') OBJTYPE(' + %trim(workfil.oatype1) +
                                ') NEWOWN(' + %trim(workfil.oaown1) + ')';
                    snd-msg 'cmdstr: ' + %trim(cmdstr);
                endif;
                if workfil.oaanam1 <> workfil.oaanam2;
                    cmdstr = 'GRTOBJAUT OBJ(' + %trim(workfil.oalib1) +
                                '/' + %trim(workfil.oaname1) +
                                ') OBJTYPE(' + %trim(workfil.oatype1) +
                                ') AUTL(' + %trim(workfil.oaanam1) + ') REPLACE(*YES)';
                    snd-msg 'cmdstr: ' + %trim(cmdstr);
                endif;
                if %trim(workfil.oaobja1) <> 'USER DEF' and %trim(workfil.oaobja1) <> %trim(workfil.oaobja2);
                    cmdstr = 'GRTOBJAUT OBJ(' + %trim(workfil.oalib1) +
                                '/' + %trim(workfil.oaname1) +
                                ') OBJTYPE(' + %trim(workfil.oatype1) +
                                ') USER(' + %trim(workfil.oausr1) +
                                ') AUT(' + %trim(workfil.oaobja1) + ') REPLACE(*YES)';
                    snd-msg 'cmdstr: ' + %trim(cmdstr);
                endif;
                if %trim(workfil.oaobja1) = 'USER DEF' and %trim(workfil.oaobja1) <> %trim(workfil.oaobja2);
                endif;

            endif;
        endif;
        exec sql fetch next from workfil2 into :workfil;
    enddo;
    exec sql close workfil2;
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
    snd-msg 'total_count: ' + %char(tot_count);
    exec sql close totcnt;
end-proc;

dcl-proc gencurfil;
    dcl-pi *n;
        option_lib char(10);
    end-pi;
    dcl-s stmt char(1500);
    // generate file for current system
    stmt = 'insert into ddscinfo.objautcur ( ' +
       'select * from qsys2.obj_priv where sys_dname = ''' + %trim(option_lib) + ''' )';
    exec sql prepare pregencur from :stmt;
    exec sql execute pregencur;
end-proc;

dcl-proc getsavvol;
    dcl-pi *n;
        option_lib char(10);
        savvol char(71);
    end-pi;
    dcl-s stmt char(1500);
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
    exec sql close getvol;
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
