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

dcl-s stmt char(1500);
dcl-s tot_count packed(5:0);
dcl-s chg_count packed(5:0);
dcl-s err_count packed(5:0);

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
// exec sql SET OPTION COMMIT = *NC;
// exec sql create table qtemp.work as (
//         select objlongschema, objname, objtype 
//         from table(qsys2.object_statistics(
//             object_schema => '*ALLUSR',
//             objtypelist => '*ALL'))) with data;
stmt =  'select objlongschema, objname, objtype ' +
        'from table(qsys2.object_statistics(' +
        'object_schema => ''' + %trim(objschema) + ''', ' +
        'objtypelist => ''*ALL''))';
// stmt = 'select objlongschema, objname, objtype ' +
//         'from qtemp.work';
exec sql prepare preliblst from :stmt;
exec sql declare liblst cursor for preliblst;
exec sql open liblst;
exec sql fetch next from liblst into :liblst;
dow sqlcod = 0;
    if sqlcod = 0;
        if %scan('Q' : %trim(liblst.objlongschema)) <> 1 and
            %scan('#LIBRARY' : %trim(liblst.objlongschema)) <> 1 and
            %scan('MAPEPIRE_T' : %trim(liblst.objlongschema)) <> 1 and            
            %scan('STAGE' : %trim(liblst.objlongschema)) <> 1 and
            %scan('SYSIBM' : %trim(liblst.objlongschema)) <> 1 and
            %scan('SYSIBMADM' : %trim(liblst.objlongschema)) <> 1 and
            %scan('SYSPROC' : %trim(liblst.objlongschema)) <> 1 and
            %scan('SYSTOOLS' : %trim(liblst.objlongschema)) <> 1;
            //
            tot_count += 1;
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
                logtxt = 'ERR' + %editc(err_count:'X') + '. Target not found in the file					: ' + 
                            liblst.objlongschema + '  ' + liblst.objname + '  ' + liblst.objtype;
                writelog(logsts : logtxt);
            endif;                       
        endif;
        exec sql fetch next from liblst into :liblst;
    endif;
enddo;
exec sql close liblst;

clear logtxt;
logsts = 'C';
logtxt = '----------------------------------------------------------------------------------------------------------------';
writelog(logsts : logtxt);

snd-msg 'Total Count  : ' + %trim(%char(tot_count));
clear logtxt;
logsts = 'C';
logtxt = 'Total Count  : ' + %trim(%char(tot_count));
writelog(logsts : logtxt);

snd-msg 'Changed Count: ' + %trim(%char(chg_count));
clear logtxt;
logsts = 'C';
logtxt = 'Changed Count: ' + %trim(%char(chg_count));
writelog(logsts : logtxt);

snd-msg 'Error Count  : ' + %trim(%char(err_count));
clear logtxt;
logsts = 'C';
logtxt = 'Error Count  : ' + %trim(%char(err_count));
writelog(logsts : logtxt);
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

dcl-proc execute_change;
    // option code: OWNER - owner diff
    //              AUTHL - auth_list diff
    //              OBJAU - obj_authority diff
    //              OBJNA - obj_authority not found
    dcl-pi *n;
        option char(4);
        objlongschema char(10);
        objname char(10);
        objtype char(7);
        chg_count packed(5:0);
        err_count packed(5:0);
    end-pi;
    dcl-pr syscmd int(10) ExtProc('system');
        *n Pointer Value Options(*String);
    end-pr;
    dcl-s cmdstr char(800);
    dcl-s returnCode int(5);
    //



    //
    return;
end-proc;

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
    exec sql fetch next from autcur into :fil_usr, :fil_objobja;
    dow sqlcod = 0;
        if sqlcod = 0;
            exec sql values(select coalesce(authorization_name,'') as authorization_name, 
                            coalesce(object_authority,'') as object_authority from qsys2.object_privileges
                            where sys_dname = :objlongschema
                            and sys_oname = :objname
                            and objtype = :objtype
                            and authorization_name = :fil_usr
                            fetch first 1 row only)
                    into :cur_usr, :cur_objobja;
            if cur_usr <> '';
                if %trim(cur_objobja) = 'USER DEFINED';
                    cur_objobja = 'USER DEF';
                endif;
                if %trim(fil_objobja) <> %trim(cur_objobja);
                    if %trim(fil_objobja) = 'USER DEFINED';
                        chg_count += 1;
                        clear logtxt;
                        logsts = 'C';
                        logtxt = 'CHG' + %editc(chg_count:'X') + '. Obj Authority Diff (FIL_USRDEF)				: ' + objlongschema + '  ' + objname + '  ' + objtype;
                        writelog(logsts : logtxt);
                
                        clear logtxt;
                        logsts = 'C';
                        logtxt = '-  Current user / obja									: ' + cur_usr + '  ' + cur_objobja;
                        writelog(logsts : logtxt);
                        clear logtxt;
                        logsts = 'C';
                        logtxt = '-  File user / obja										: ' + fil_usr + '  ' + fil_objobja;
                        writelog(logsts : logtxt);
                    else;
                        chg_count += 1;
                        clear logtxt;
                        logsts = 'C';
                        logtxt = 'CHG' + %editc(chg_count:'X') + '. Obj Authority Diff (FIL_NORMAL)				: ' + objlongschema + '  ' + objname + '  ' + objtype;
                        writelog(logsts : logtxt);
                
                        clear logtxt;
                        logsts = 'C';
                        logtxt = '-  Current user / obja									: ' + cur_usr + '  ' + cur_objobja;
                        writelog(logsts : logtxt);
                        clear logtxt;
                        logsts = 'C';
                        logtxt = '-  File user / obja										: ' + fil_usr + '  ' + fil_objobja;
                        writelog(logsts : logtxt);
                        
                    endif;                  
                endif;
            else;
                if %trim(fil_objobja) = 'USER DEFINED';
                    chg_count += 1;
                    clear logtxt;
                    logsts = 'C';
                    logtxt = 'CHG' + %editc(chg_count:'X') + '. Obj Authority Not found (FIL_USRDEF)			: ' + objlongschema + '  ' + objname + '  ' + objtype;
                    writelog(logsts : logtxt);

                    clear logtxt;
                    logsts = 'C';
                    logtxt = '-  File user / obja										: ' + fil_usr + '  ' + fil_objobja;
                    writelog(logsts : logtxt);
                else;
                    chg_count += 1;
                    clear logtxt;
                    logsts = 'C';
                    logtxt = 'CHG' + %editc(chg_count:'X') + '. Obj Authority Not found (FIL_NORMAL)			: ' + objlongschema + '  ' + objname + '  ' + objtype;
                    writelog(logsts : logtxt);
                    
                    clear logtxt;
                    logsts = 'C';
                    logtxt = '-  File user / obja										: ' + fil_usr + '  ' + fil_objobja;
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
    dcl-s cur_autl char(10);
    dcl-s fil_autl char(10);

    //
    clear cur_autl;
    clear fil_autl;

    exec sql values(select coalesce(autl,'*NONE') as autl from qsys2.object_privileges
                            where sys_dname = :objlongschema
                            and sys_oname = :objname
                            and objtype = :objtype
                            and user_name = '*PUBLIC'
                            fetch first 1 row only)
                    into :cur_autl;
    if cur_autl = '';
        err_count += 1;
        clear logtxt;
        logsts = 'C';
        logtxt = 'ERR' + %editc(err_count:'X') + 
                 '. Not authorized. Please re-run. (' + 
                 %trim(objlongschema) + '  ' + %trim(objname) + '  ' + %trim(objtype) + ')';
        writelog(logsts : logtxt);
    endif;
    exec sql values(select coalesce(oaanam,'*NONE') as oaanam from ddscinfo.objaut
                            where oalib = :objlongschema
                            and oaname = :objname
                            and oatype = :objtype
                            and oausr = '*PUBLIC'
                            fetch first 1 row only)
                    into :fil_autl;
    if fil_autl <> '';
        if %trim(cur_autl) <> %trim(fil_autl);
            chg_count += 1;
            clear logtxt;
            logsts = 'C';
            logtxt = 'CHG' + %editc(chg_count:'X') + '. Auth_List Diff				 					: ' + objlongschema + 
                        '  ' + objname + '  ' + objtype;
            writelog(logsts : logtxt);

            clear logtxt;
            logsts = 'C';
            logtxt = '-  Current / File autl			 						: ' + cur_autl + '  ' + fil_autl;
            writelog(logsts : logtxt);                        
        endif;
    else;
        chg_count += 1;
        clear logtxt;
        logsts = 'C';
        logtxt = 'ERR' + %editc(err_count:'X') + '. Auth_List Not found: ' + objlongschema + '  ' + objname + '  ' + objtype;
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
    dcl-s cur_owner char(10);
    dcl-s fil_owner char(10);
    //
    clear cur_owner;
    clear fil_owner;

    exec sql values(select coalesce(owner,'') as owner from qsys2.object_privileges
                            where sys_dname = :objlongschema
                            and sys_oname = :objname
                            and objtype = :objtype
                            and user_name = '*PUBLIC'
                            fetch first 1 row only)
                    into :cur_owner;
    if cur_owner = '';
        err_count += 1;
        clear logtxt;
        logsts = 'C';
        logtxt = 'ERR' + %editc(err_count:'X') + 
                 '. Not authorized. Please re-run. (' + 
                 %trim(objlongschema) + '  ' + %trim(objname) + '  ' + %trim(objtype) + ')';
        writelog(logsts : logtxt);
    endif;
    exec sql values(select coalesce(oaown,'') as oaown from ddscinfo.objaut
                            where oalib = :objlongschema
                            and oaname = :objname
                            and oatype = :objtype
                            and oausr = '*PUBLIC'
                            fetch first 1 row only)
                    into :fil_owner;
    if fil_owner <> '';
        if %trim(cur_owner) <> %trim(fil_owner);
            chg_count += 1;
            clear logtxt;
            logsts = 'C';
            logtxt = 'CHG' + %editc(chg_count:'X') + '. Owner Diff					 					: ' +objlongschema + 
                        '  ' + objname + '  ' + objtype;
            writelog(logsts : logtxt);                        

            clear logtxt;
            logsts = 'C';
            logtxt = '-  Current / File owner									: ' + cur_owner + '  ' + fil_owner;
            writelog(logsts : logtxt);
        endif;
    else;
        chg_count += 1;
        clear logtxt;
        logsts = 'C';
        logtxt = 'ERR' + %editc(err_count:'X') + '. Owner Not found: ' + objlongschema + '  ' + objname + '  ' + objtype;
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
