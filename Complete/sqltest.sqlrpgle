**FREE
ctl-opt option(*srcstmt) dftactgrp(*no);
dcl-pi *n;
    objschema char(10);
end-pi;
dcl-ds liblst qualified;
    objlongschema char(10);
    objname char(10);
    objtype char(7);
end-ds;
dcl-s objNotFound char(10);
dcl-s objNotFound_ind int(5); 

dcl-s cmdstr char(800);
dcl-s stmt char(1500);
dcl-s tot_count packed(5:0);
dcl-s chg_count packed(5:0);
dcl-s err_count packed(5:0);

dcl-s cur_owner char(10);
dcl-s fil_owner char(10);
dcl-s logsts char(1); // T: Log Title  C: Log Continue  E: Log Ending
dcl-s logtxt char(1500);

logsts = 'T';
writelog(logsts : logtxt);
//
logsts = 'C';
logtxt = 'Authority comparison job start';
writelog(logsts : logtxt);
//

clear tot_count;
clear chg_count;
clear err_count;

stmt = 'select objlongschema, objname, objtype ' +
        'from table(qsys2.object_statistics(' +
        'object_schema => ''' + %trim(objschema) + ''', ' +
        'objtypelist => ''*ALL''))';
        
exec sql prepare preliblst from :stmt;
exec sql declare liblst cursor for preliblst;
exec sql open liblst;
exec sql fetch next from liblst into :liblst;
dow sqlcod = 0;
    if sqlcod = 0;
        tot_count += 1;
        if %scan('Q' : %trim(liblst.objlongschema)) <> 1 and
            %scan('#LIBRARY' : %trim(liblst.objlongschema)) <> 1 and
            %scan('STAGE' : %trim(liblst.objlongschema)) <> 1 and
            %scan('SYSIBM' : %trim(liblst.objlongschema)) <> 1 and
            %scan('SYSIBMADM' : %trim(liblst.objlongschema)) <> 1 and
            %scan('SYSPROC' : %trim(liblst.objlongschema)) <> 1 and
            %scan('SYSTOOLS' : %trim(liblst.objlongschema)) <> 1;
            //
            exec sql values(select oaname from ddscinfo.objaut
                            where oalib = :liblst.objlongschema
                            and oaname = :liblst.objname
                            and oatype = :liblst.objtype
                            and oausr = '*PUBLIC'
                            fetch first 1 row only)
                    into :objNotFound :objNotFound_ind;

            if objNotFound_ind = 0; 
                check_owner(liblst.objlongschema : liblst.objname : liblst.objtype : chg_count : err_count); // chgobjown
                check_autl(liblst.objlongschema : liblst.objname : liblst.objtype : chg_count : err_count); // grtobjaut
                check_obja(liblst.objlongschema : liblst.objname : liblst.objtype : chg_count : err_count); // grtobjaut
            else;
                err_count += 1;
                clear logtxt;
                logsts = 'C';
                logtxt = 'ERR' + %editc(err_count:'X') + '. Target not found in the file: ' + liblst.objlongschema + 
                        ' | ' + liblst.objname + ' | ' + liblst.objtype;
                writelog(logsts : logtxt);
            endif;                       
        endif;
        exec sql fetch next from liblst into :liblst;
    endif;
enddo;
exec sql close liblst;
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
//
*inlr = *on;
return;

dcl-proc check_obja;
    dcl-pi *n;
        objlongschema char(10);
        objname char(10);
        objtype char(7);
        chg_count packed(5:0);
        err_count packed(5:0);
    end-pi;
    dcl-s cur_usr char(10);
    dcl-s cur_usr_ind int(5);
    dcl-s fil_usr char(10);
    dcl-s fil_usr_ind int(5);
    dcl-s cur_objobja char(12);
    dcl-s cur_objobja_ind int(5);
    dcl-s fil_objobja char(12);
    dcl-s fil_objobja_ind int(5);
    dcl-s cur_objamgt char(3);
    dcl-s cur_objamgt_ind int(5);
    dcl-s fil_objamgt char(3);
    dcl-s fil_objamgt_ind int(5);
    dcl-s cur_objopr char(3);
    dcl-s cur_objopr_ind int(5);
    dcl-s fil_objopr char(3);
    dcl-s fil_objopr_ind int(5);
    dcl-s cur_objomgt char(3);
    dcl-s cur_objomgt_ind int(5);
    dcl-s fil_objomgt char(3);
    dcl-s fil_objomgt_ind int(5);
    dcl-s cur_objexist char(3);
    dcl-s cur_objexist_ind int(5);
    dcl-s fil_objexist char(3);
    dcl-s fil_objexist_ind int(5);
    dcl-s cur_objalter char(3);
    dcl-s cur_objalter_ind int(5);
    dcl-s fil_objalter char(3);
    dcl-s fil_objalter_ind int(5);
    dcl-s cur_objref char(3);
    dcl-s cur_objref_ind int(5);
    dcl-s fil_objref char(3);
    dcl-s fil_objref_ind int(5);
    dcl-s cur_read char(3);
    dcl-s cur_read_ind int(5);
    dcl-s fil_read char(3);
    dcl-s fil_read_ind int(5);
    dcl-s cur_add char(3);
    dcl-s cur_add_ind int(5);
    dcl-s fil_add char(3);
    dcl-s fil_add_ind int(5);
    dcl-s cur_upd char(3);
    dcl-s cur_upd_ind int(5);
    dcl-s fil_upd char(3);
    dcl-s fil_upd_ind int(5);
    dcl-s cur_dlt char(3);
    dcl-s cur_dlt_ind int(5);
    dcl-s fil_dlt char(3);
    dcl-s fil_dlt_ind int(5);
    dcl-s cur_exec char(3);
    dcl-s cur_exec_ind int(5);
    dcl-s fil_exec char(3);
    dcl-s fil_exec_ind int(5);
    //
    stmt = 'select oausr, oaobja from ddscinfo.objaut ' +
                'where oalib = ? ' +
                'and oaname = ? ' +
                'and oatype = ?';
    exec sql prepare preautcur from :stmt;
    exec sql declare autcur cursor for preautcur;
    exec sql open autcur using :objlongschema, :objname, :objtype;
    exec sql fetch next from autcur into :fil_usr :fil_usr_ind, :fil_objobja :fil_objobja_ind;
    dow sqlcod = 0;
        if sqlcod = 0;
            exec sql values(select authorization_name, object_authority from qsys2.object_privileges
                            where sys_dname = :objlongschema
                            and sys_oname = :objname
                            and objtype = :objtype
                            and authorization_name = :fil_usr
                            fetch first 1 row only)
                    into :cur_usr :cur_usr_ind, :cur_objobja :cur_objobja_ind;
            if cur_usr_ind = 0;
                if %trim(cur_objobja) = 'USER DEFINED';
                    cur_objobja = 'USER DEF';
                endif;
                if %trim(fil_objobja) <> %trim(cur_objobja);
                    if %trim(fil_objobja) = 'USER DEFINED';
                        chg_count += 1;
                        clear logtxt;
                        logsts = 'C';
                        logtxt = 'CHG' + %editc(chg_count:'X') + '. Obj Authority Diff (FIL_USER_DEFINED): ' + objlongschema + ' | ' + objname + ' | ' + objtype;
                        writelog(logsts : logtxt);
                
                        clear logtxt;
                        logsts = 'C';
                        logtxt = '-  Current obja: ' + %trim(cur_objobja) + '   -  Current user: ' + %trim(cur_usr);
                        writelog(logsts : logtxt);
                        clear logtxt;
                        logsts = 'C';
                        logtxt = '-  File obja: ' + %trim(fil_objobja) + '   -  File user: ' + %trim(fil_usr);
                        writelog(logsts : logtxt);
                    else;
                        chg_count += 1;
                        clear logtxt;
                        logsts = 'C';
                        logtxt = 'CHG' + %editc(chg_count:'X') + '. Obj Authority Diff (FIL_NORMAL): ' + objlongschema + ' | ' + objname + ' | ' + objtype;
                        writelog(logsts : logtxt);
                
                        clear logtxt;
                        logsts = 'C';
                        logtxt = '-  Current obja: ' + %trim(cur_objobja) + '   -  Current user: ' + %trim(cur_usr);
                        writelog(logsts : logtxt);
                        clear logtxt;
                        logsts = 'C';
                        logtxt = '-  File obja: ' + %trim(fil_objobja) + '   -  File user: ' + %trim(fil_usr);
                        writelog(logsts : logtxt);
                        
                    endif;                  
                endif;
            else;
                if %trim(fil_objobja) = 'USER DEFINED';
                    chg_count += 1;
                    clear logtxt;
                    logsts = 'C';
                    logtxt = 'CHG' + %editc(chg_count:'X') + '. Obj Authority Not found (FIL_USER_DEFINED): ' + objlongschema + ' | ' + objname + ' | ' + objtype;
                    writelog(logsts : logtxt);

                    clear logtxt;
                    logsts = 'C';
                    logtxt = '-  File obja: ' + %trim(fil_objobja) + '   -  File user: ' + %trim(fil_usr);
                    writelog(logsts : logtxt);
                else;
                    chg_count += 1;
                    clear logtxt;
                    logsts = 'C';
                    logtxt = 'CHG' + %editc(chg_count:'X') + '. Obj Authority Not found (FIL_NORMAL): ' + objlongschema + ' | ' + objname + ' | ' + objtype;
                    writelog(logsts : logtxt);
                    
                    clear logtxt;
                    logsts = 'C';
                    logtxt = '-  File obja: ' + %trim(fil_objobja) + '   -  File user: ' + %trim(fil_usr);
                    writelog(logsts : logtxt);
                endif;
            endif; 
            exec sql fetch next from autcur into :fil_usr :fil_usr_ind, :fil_objobja :fil_objobja_ind;
        endif;      
    enddo;
    exec sql close autcur;
    //
    return;
end-proc;

dcl-proc check_autl;
    dcl-pi *n;
        objlongschema char(10);
        objname char(10);
        objtype char(7);
        chg_count packed(5:0);
        err_count packed(5:0);
    end-pi;
    dcl-pr syscmd int(10) ExtProc('system');
        *n Pointer Value Options(*String);
    end-pr;
    dcl-s cur_autl char(10);
    dcl-s cur_autl_ind int(5);
    dcl-s fil_autl char(10);
    dcl-s fil_autl_ind int(5);

    //
    clear cur_autl;
    clear fil_autl;

    exec sql values(select coalesce(autl,'*NONE') as autl from qsys2.object_privileges
                            where sys_dname = :objlongschema
                            and sys_oname = :objname
                            and objtype = :objtype
                            and user_name = '*PUBLIC'
                            fetch first 1 row only)
                    into :cur_autl :cur_autl_ind;
    exec sql values(select coalesce(oaanam,'*NONE') as oaanam from ddscinfo.objaut
                            where oalib = :objlongschema
                            and oaname = :objname
                            and oatype = :objtype
                            and oausr = '*PUBLIC'
                            fetch first 1 row only)
                    into :fil_autl :fil_autl_ind;
    if fil_autl_ind = 0;
        if %trim(cur_autl) <> %trim(fil_autl);
            chg_count += 1;
            clear logtxt;
            logsts = 'C';
            logtxt = 'CHG' + %editc(chg_count:'X') + '. Auth_List Diff: ' + objlongschema + ' | ' + objname + ' | ' + objtype;
            writelog(logsts : logtxt);

            clear logtxt;
            logsts = 'C';
            logtxt = '-  Current autl: ' + %trim(cur_autl) + '   -  File autl: ' + %trim(fil_autl);
            writelog(logsts : logtxt);                        
        endif;
    else;
        chg_count += 1;
        clear logtxt;
        logsts = 'C';
        logtxt = 'ERR' + %editc(err_count:'X') + '. Auth_List Not found: ' + objlongschema + ' | ' + objname + ' | ' + objtype;
        writelog(logsts : logtxt);

        clear logtxt;
        logsts = 'C';
        logtxt = '-  File autl: ' + %trim(fil_autl);
        writelog(logsts : logtxt);
    endif;
    return;
end-proc;


dcl-proc check_owner;
    dcl-pi *n;
        objlongschema char(10);
        objname char(10);
        objtype char(7);
        chg_count packed(5:0);
        err_count packed(5:0);
    end-pi;
    dcl-pr syscmd int(10) ExtProc('system');
        *n Pointer Value Options(*String);
    end-pr;
    dcl-s cur_owner char(10);
    dcl-s cur_owner_ind int(5);
    dcl-s fil_owner char(10);
    dcl-s fil_owner_ind int(5);
    //
    clear cur_owner;
    clear fil_owner;

    exec sql values(select coalesce(owner,'') as owner from qsys2.object_privileges
                            where sys_dname = :objlongschema
                            and sys_oname = :objname
                            and objtype = :objtype
                            and user_name = '*PUBLIC'
                            fetch first 1 row only)
                    into :cur_owner :cur_owner_ind;
    exec sql values(select coalesce(oaown,'') as oaown from ddscinfo.objaut
                            where oalib = :objlongschema
                            and oaname = :objname
                            and oatype = :objtype
                            and oausr = '*PUBLIC'
                            fetch first 1 row only)
                    into :fil_owner :fil_owner_ind;
    if fil_owner_ind = 0;
        if %trim(cur_owner) <> %trim(fil_owner);
            chg_count += 1;
            clear logtxt;
            logsts = 'C';
            logtxt = 'CHG' + %editc(chg_count:'X') + '. Owner Diff: ' +objlongschema + ' | ' + objname + ' | ' + objtype;
            writelog(logsts : logtxt);                        

            clear logtxt;
            logsts = 'C';
            logtxt = '-  Current owner: ' + %trim(cur_owner) + '   -  File owner: ' + %trim(fil_owner);
            writelog(logsts : logtxt);                        
        endif;
    else;
        chg_count += 1;
        clear logtxt;
        logsts = 'C';
        logtxt = 'ERR' + %editc(err_count:'X') + '. Owner Not found: ' + objlongschema + ' | ' + objname + ' | ' + objtype;
        writelog(logsts : logtxt);

        clear logtxt;
        logsts = 'C';
        logtxt = '-  File owner: ' + %trim(fil_owner);
        writelog(logsts : logtxt);
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
        logLocation = '/home/sqltest' +
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
