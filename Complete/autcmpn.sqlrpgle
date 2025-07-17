**FREE
// CALL PGM(STEVE/SQLTEST) PARM(('STEVE'))
// parameter: *ALL *ALLUSR or specific library
//
ctl-opt option(*srcstmt) dftactgrp(*no);
dcl-pi *n;
    objschema char(10);
end-pi;
dcl-ds liblst qualified;
    objlongschema char(10);
    objname char(10);
    objtype char(7);
    save_volume char(6);
end-ds;
dcl-s target_libnm char(10);
dcl-s target_filnm char(10);
dcl-s objNotFound char(10);

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
stmt =  'select coalesce(objlongschema,'''') as objlongschema, ' +
        'coalesce(objname,'''') as objname, ' +
        'coalesce(objtype,'''') as objtype, ' +
        'coalesce(save_volume,'''') as save_volume ' +
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
            %scan('HOYA' : %trim(liblst.objlongschema)) <> 1 and
            %scan('PMEDH' : %trim(liblst.objlongschema)) <> 1 and
            %scan('RMT' : %trim(liblst.objlongschema)) <> 1 and
            %scan('STAGE' : %trim(liblst.objlongschema)) <> 1 and
            %scan('SYSIBM' : %trim(liblst.objlongschema)) <> 1 and
            %scan('SYSIBMADM' : %trim(liblst.objlongschema)) <> 1 and
            %scan('SYSPROC' : %trim(liblst.objlongschema)) <> 1 and
            %scan('SYSTOOLS' : %trim(liblst.objlongschema)) <> 1;
            tot_count += 1;
            // prepare file name
            // if %trim(liblst.save_volume) = '';
            target_libnm = 'DDSCINFO';
            target_filnm = 'OBJAUT';
            // else;
            //     target_libnm = 'DDSCINFO';
            //     target_filnm = 'OBJAUT' + %subst(%trim(liblst.save_volume) : 1 : 3);
            // endif;
            clear logtxt;
            logsts = 'C';
            logtxt = 'Search from  : ' + target_libnm + '.' + target_filnm;
            writelog(logsts : logtxt);
            //
            stmt = 'select oaname from ' + %trim(target_libnm) + '.' + %trim(target_filnm) + ' ' +
                        'where oalib = ? ' +
                        'and oaname = ? ' +
                        'and oatype = ? ' +
                        'and oausr = ''*PUBLIC'' ' +
                        'fetch first 1 row only';
            exec sql prepare preobjFound from :stmt;
            exec sql declare objFound cursor for preobjFound;
            exec sql open objFound using :liblst.objlongschema, :liblst.objname, :liblst.objtype;
            exec sql fetch from objFound into :objNotFound;
            if objNotFound <> ''; 
                check_owner(target_libnm : target_filnm : liblst.objlongschema : liblst.objname : liblst.objtype : chg_count : err_count); // chgobjown
                check_autl(target_libnm : target_filnm : liblst.objlongschema : liblst.objname : liblst.objtype : chg_count : err_count); // grtobjaut
                check_obja(target_libnm : target_filnm : liblst.objlongschema : liblst.objname : liblst.objtype : chg_count : err_count); // grtobjaut
            else;
                err_count += 1;
                clear logtxt;
                logsts = 'C';
                logtxt = 'ERR' + %editc(err_count:'X') + '. Target not found in the file					: ' + 
                liblst.objlongschema + '  ' + liblst.objname + '  ' + liblst.objtype;
                writelog(logsts : logtxt);
            endif;                       
            exec sql close objFound;                      
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
        option char(5);
        data char(100);
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
    dcl-s logsts char(1); // T: Log Title  C: Log Continue  E: Log Ending)
    dcl-s logtxt char(1500);
    //
    select;
        when option = 'OWNER';
            clear cmdstr;
            // CHGOBJOWN OBJ(XXX/XXX) OBJTYPE(*XXX) NEWOWN(XXX)
            cmdstr = 'CHGOBJOWN OBJ(' + %trim(objlongschema) + '/' + %trim(objname) + 
                        ') OBJTYPE(' + %trim(objtype) + ') NEWOWN(' + %trim(data) + ')';
            clear logtxt;
            logsts = 'C';
            logtxt = 'Command preview: [' + %trim(cmdstr) + ']';
            writelog(logsts : logtxt);
            returnCode = syscmd(cmdstr);
            if returnCode <> 0;
                err_count += 1;
                clear logtxt;
                logsts = 'C';
                logtxt = 'ERR' + %editc(err_count:'X') + 
                            '. Command failed. Please check. (' +
                            %trim(objlongschema) + '  ' + %trim(objname) + '  ' + %trim(objtype) + ')';
                writelog(logsts : logtxt);
            endif;

        when option = 'AUTHL';
            clear cmdstr;
            // GRTOBJAUT OBJ(XXX/XXX) OBJTYPE(*XXX) AUTL(XXX)
            cmdstr = 'GRTOBJAUT OBJ(' + %trim(objlongschema) + '/' + %trim(objname) + 
                        ') OBJTYPE(' + %trim(objtype) + ') AUTL(' + %trim(data) + ')';
            clear logtxt;
            logsts = 'C';
            logtxt = 'Command preview: [' + %trim(cmdstr) + ']';
            writelog(logsts : logtxt);
            returnCode = syscmd(cmdstr);
            if returnCode <> 0;
                err_count += 1;
                clear logtxt;
                logsts = 'C';
                logtxt = 'ERR' + %editc(err_count:'X') + 
                            '. Command failed. Please check. (' +
                            %trim(objlongschema) + '  ' + %trim(objname) + '  ' + %trim(objtype) + ')';
                writelog(logsts : logtxt);
            endif;

        when option = 'OBJAU';
            clear cmdstr;
            // GRTOBJAUT OBJ(XXX/XXX) OBJTYPE(XXX) USER(XXX) AUT(XXX)
            cmdstr = 'GRTOBJAUT OBJ(' + %trim(objlongschema) + '/' + %trim(objname) + 
                        ') OBJTYPE(' + %trim(objtype) + ') USER(' + %trim(%subst(data : 1 : 10)) + 
                        ') AUT(' + %scanrpl(',' : ' ' : %trim(%subst(data : 11 : 80))) + 
                        ') REPLACE(*YES)';
            clear logtxt;
            logsts = 'C';
            logtxt = 'Command preview: [' + %trim(cmdstr) + ']';
            writelog(logsts : logtxt);
            returnCode = syscmd(cmdstr);
            if returnCode <> 0;
                err_count += 1;
                clear logtxt;
                logsts = 'C';
                logtxt = 'ERR' + %editc(err_count:'X') + 
                            '. Command failed. Please check. (' +
                            %trim(objlongschema) + '  ' + %trim(objname) + '  ' + %trim(objtype) + ')';
                writelog(logsts : logtxt);
            endif;

        when option = 'OBJNA';
            clear cmdstr;
            // GRTOBJAUT OBJ(XXX/XXX) OBJTYPE(XXX) USER(XXX) AUT(XXX)
            cmdstr = 'GRTOBJAUT OBJ(' + %trim(objlongschema) + '/' + %trim(objname) + 
                        ') OBJTYPE(' + %trim(objtype) + ') USER(' + %trim(%subst(data : 1 : 10)) + 
                        ') AUT(' + %scanrpl(',' : ' ' : %trim(%subst(data : 11 : 80))) + 
                        ') REPLACE(*YES)';
            clear logtxt;
            logsts = 'C';
            logtxt = 'Command preview: [' + %trim(cmdstr) + ']';
            writelog(logsts : logtxt);
            returnCode = syscmd(cmdstr);
            if returnCode <> 0;
                err_count += 1;
                clear logtxt;
                logsts = 'C';
                logtxt = 'ERR' + %editc(err_count:'X') + 
                            '. Command failed. Please check. (' +
                            %trim(objlongschema) + '  ' + %trim(objname) + '  ' + %trim(objtype) + ')';
                writelog(logsts : logtxt);
            endif;

        other;
            clear logtxt;
            logsts = 'C';
            logtxt = 'ERR' + %editc(err_count:'X') + 
                        '. Unrecorgnized command. Please check. (' + 
                        %trim(objlongschema) + '  ' + %trim(objname) + '  ' + %trim(objtype) + ')';
            writelog(logsts : logtxt);
    endsl;
    //
    return;
end-proc;

dcl-proc check_obja;
    dcl-pi *n;
        target_libnm char(10);
        target_filnm char(10);
        objlongschema char(10);
        objname char(10);
        objtype char(7);
        chg_count packed(5:0);
        err_count packed(5:0);
    end-pi;
    dcl-s cur_usr char(10);
    dcl-s fil_usr char(10);
    dcl-s cur_grpn char(10);
    dcl-s fil_grpn char(10);
    dcl-s cur_objobja char(12);
    dcl-s fil_objobja char(12);
    dcl-s cur_objamgt char(3);
    dcl-s fil_objamgt char(3);
    dcl-s cur_objopr char(3);
    dcl-s fil_objopr char(3);
    dcl-s cur_objomgt char(3);
    dcl-s fil_objomgt char(3);
    dcl-s cur_objexist char(3);
    dcl-s fil_objexist char(3);
    dcl-s cur_objalter char(3);
    dcl-s fil_objalter char(3);
    dcl-s cur_objref char(3);
    dcl-s fil_objref char(3);
    dcl-s cur_read char(3);
    dcl-s fil_read char(3);
    dcl-s cur_add char(3);
    dcl-s fil_add char(3);
    dcl-s cur_upd char(3);
    dcl-s fil_upd char(3);
    dcl-s cur_dlt char(3);
    dcl-s fil_dlt char(3);
    dcl-s cur_exec char(3);
    dcl-s fil_exec char(3);
    dcl-s option char(5);
    dcl-s data char(100);
    //
    stmt = 'select oausr, oaobja, oagrpn, oaopr, oaomgt, oaexs, oaalt, oaref, ' + 
                'oaread, oaadd, oaupd, oadlt, oaexec ' +
                'from '+ %trim(target_libnm) + '.' + %trim(target_filnm) + ' ' +
                'where oalib = ? ' +
                'and oaname = ? ' +
                'and oatype = ?';
    exec sql prepare preautcur from :stmt;
    exec sql declare autcur cursor for preautcur;
    exec sql open autcur using :objlongschema, :objname, :objtype;
    exec sql fetch next from autcur into :fil_usr, :fil_objobja, :fil_grpn, :fil_objopr, :fil_objomgt, 
                :fil_objexist, :fil_objalter, :fil_objref, :fil_read, :fil_add, :fil_upd, :fil_dlt, :fil_exec;
    dow sqlcod = 0;
        if sqlcod = 0;
            if fil_usr = '*GROUP';
                fil_usr = %trim(fil_grpn);
            endif;
            exec sql values(select coalesce(authorization_name,'') as authorization_name, 
                            coalesce(object_authority,'') as object_authority,
                            object_operational, object_management, object_existence,
                            object_alter, object_reference,
                            data_read, data_add, data_update, data_delete, data_execute 
                            from qsys2.object_privileges
                            where sys_dname = :objlongschema
                            and sys_oname = :objname
                            and objtype = :objtype
                            and authorization_name = :fil_usr
                            fetch first 1 row only)
                    into :cur_usr, :cur_objobja, :cur_objopr, :cur_objomgt, :cur_objexist, 
                    :cur_objalter, :cur_objref, :cur_read, :cur_add, :cur_upd, :cur_dlt, :cur_exec;
            if cur_usr <> '';
                if %trim(cur_objobja) = 'USER DEFINED';
                    cur_objobja = 'USER DEF';
                endif;
                if %trim(fil_objobja) <> %trim(cur_objobja);
                    if %trim(fil_objobja) = 'USER DEF';
                        chg_count += 1;
                        clear logtxt;
                        logsts = 'C';
                        logtxt = 'CHG' + %editc(chg_count:'X') + 
                                '. Obj Authority Diff (FIL_USRDEF)				: ' + objlongschema + 
                                '  ' + objname + '  ' + objtype;
                        writelog(logsts : logtxt);
                
                        clear logtxt;
                        logsts = 'C';
                        logtxt = '-  Current user / obja									: ' + cur_usr + 
                                '  ' + cur_objobja;
                        writelog(logsts : logtxt);
                        clear logtxt;
                        logsts = 'C';
                        logtxt = '-  File user / obja										: ' + fil_usr + 
                                '  ' + fil_objobja;
                        writelog(logsts : logtxt);
                        
                        option = 'OBJAU';
                        data = fil_usr + ',';
                        if %trim(fil_objopr) = 'X';
                            data = %trimr(data) + '*OBJOPR,';
                        endif;
                        if %trim(fil_objomgt) = 'X';
                            data = %trimr(data) + '*OBJMGT,';
                        endif;
                        if %trim(fil_objexist) = 'X';
                            data = %trimr(data) + '*OBJEXIST,';
                        endif;
                        if %trim(fil_objalter) = 'X';
                            data = %trimr(data) + '*OBJALTER,';
                        endif;
                        if %trim(fil_objref) = 'X';
                            data = %trimr(data) + '*OBJREF,';
                        endif;
                        if %trim(fil_read) = 'X';
                            data = %trimr(data) + '*READ,';
                        endif;
                        if %trim(fil_add) = 'X';
                            data = %trimr(data) + '*ADD,';
                        endif;
                        if %trim(fil_upd) = 'X';
                            data = %trimr(data) + '*UPD,';
                        endif;
                        if %trim(fil_dlt) = 'X';
                            data = %trimr(data) + '*DLT,';
                        endif;
                        if %trim(fil_exec) = 'X';
                            data = %trimr(data) + '*EXECUTE';
                        endif;
                        execute_change(option : data : objlongschema : objname : objtype : chg_count : err_count);                    
                    else;
                        chg_count += 1;
                        clear logtxt;
                        logsts = 'C';
                        logtxt = 'CHG' + %editc(chg_count:'X') + 
                                    '. Obj Authority Diff (FIL_NORMAL)				: ' + objlongschema + 
                                    '  ' + objname + '  ' + objtype;
                        writelog(logsts : logtxt);
                
                        clear logtxt;
                        logsts = 'C';
                        logtxt = '-  Current user / obja									: ' + cur_usr + 
                                    '  ' + cur_objobja;
                        writelog(logsts : logtxt);
                        clear logtxt;
                        logsts = 'C';
                        logtxt = '-  File user / obja										: ' + fil_usr + 
                                    '  ' + fil_objobja;
                        writelog(logsts : logtxt);
                        
                        option = 'OBJAU';
                        data = fil_usr + ',' + %trim(fil_objobja);
                        execute_change(option : data : objlongschema : objname : objtype : chg_count : err_count);

                    endif;  
                elseif %trim(fil_objobja) = %trim(cur_objobja) and %trim(fil_objobja) = 'USER DEF';
                    // Both file and current are USER DEFINED
                    if %trim(cur_objopr) = 'YES';
                        cur_objopr = 'X';
                    else;
                        cur_objopr = '';
                    endif;
                    if %trim(cur_objomgt) = 'YES';
                        cur_objomgt = 'X';
                    else;
                        cur_objomgt = '';
                    endif;
                    if %trim(cur_objexist) = 'YES';
                        cur_objexist = 'X';
                    else;
                        cur_objexist = '';
                    endif;
                    if %trim(cur_objalter) = 'YES';
                        cur_objalter = 'X';
                    else;
                        cur_objalter = '';
                    endif;
                    if %trim(cur_objref) = 'YES';
                        cur_objref = 'X';
                    else;
                        cur_objref = '';
                    endif;
                    if %trim(cur_read) = 'YES';
                        cur_read = 'X';
                    else;
                        cur_read = '';                        
                    endif;
                    if %trim(cur_add) = 'YES';
                        cur_add = 'X';
                    else;
                        cur_add = '';
                    endif;
                    if %trim(cur_upd) = 'YES';
                        cur_upd = 'X';
                    else;
                        cur_upd = '';
                    endif;
                    if %trim(cur_dlt) = 'YES';
                        cur_dlt = 'X';
                    else;
                        cur_dlt = '';
                    endif;
                    if %trim(cur_exec) = 'YES';
                        cur_exec = 'X';
                    else; 
                        cur_exec = '';
                    endif;

                    if %trim(fil_objopr) <> %trim(cur_objopr) or %trim(fil_objomgt) <> %trim(cur_objomgt) or
                    %trim(fil_objexist) <> %trim(cur_objexist) or %trim(fil_objalter) <> %trim(cur_objalter) or
                    %trim(fil_objref) <> %trim(cur_objref) or %trim(fil_read) <> %trim(cur_read) or
                    %trim(fil_add) <> %trim(cur_add) or %trim(fil_upd) <> %trim(cur_upd) or
                    %trim(fil_dlt) <> %trim(cur_dlt) or %trim(fil_exec) <> %trim(cur_exec);
                        logsts = 'C';
                        logtxt = 'objopr:' + %trim(fil_objopr) + '  ' + %trim(cur_objopr);
                        writelog(logsts : logtxt);
                        logsts = 'C';
                        logtxt = 'objomgt:' + %trim(fil_objomgt) + '  ' + %trim(cur_objomgt);
                        writelog(logsts : logtxt);
                        logsts = 'C';
                        logtxt = 'objexist:' + %trim(fil_objexist) + '  ' + %trim(cur_objexist);
                        writelog(logsts : logtxt);
                        logsts = 'C';
                        logtxt = 'objalter:' + %trim(fil_objalter) + '  ' + %trim(cur_objalter);
                        writelog(logsts : logtxt);
                        logsts = 'C';
                        logtxt = 'objref:' + %trim(fil_objref) + '  ' + %trim(cur_objref);
                        writelog(logsts : logtxt);
                        logsts = 'C';
                        logtxt = 'dataread:' + %trim(fil_read) + '  ' + %trim(cur_read);
                        writelog(logsts : logtxt);
                        logsts = 'C';
                        logtxt = 'dataadd:' + %trim(fil_add) + '  ' + %trim(cur_add);
                        writelog(logsts : logtxt);
                        logsts = 'C';
                        logtxt = 'dataupd:' + %trim(fil_upd) + '  ' + %trim(cur_upd);
                        writelog(logsts : logtxt);
                        logsts = 'C';
                        logtxt = 'datadlt:' + %trim(fil_dlt) + '  ' + %trim(cur_dlt);
                        writelog(logsts : logtxt);
                        logsts = 'C';
                        logtxt = 'dataexec:' + %trim(fil_exec) + '  ' + %trim(cur_exec);
                        writelog(logsts : logtxt);


                        chg_count += 1;
                        clear logtxt;
                        logsts = 'C';
                        logtxt = 'CHG' + %editc(chg_count:'X') + 
                                    '. Obj Authority Diff (BOTH_USRDEF)			: ' + objlongschema + 
                                    '  ' + objname + '  ' + objtype;
                        writelog(logsts : logtxt);

                        option = 'OBJAU';
                        data = fil_usr + ',';
                        if %trim(fil_objopr) = 'X';
                            data = %trimr(data) + '*OBJOPR,';
                        endif;
                        if %trim(fil_objomgt) = 'X';
                            data = %trimr(data) + '*OBJMGT,';
                        endif;
                        if %trim(fil_objexist) = 'X';
                            data = %trimr(data) + '*OBJEXIST,';
                        endif;
                        if %trim(fil_objalter) = 'X';
                            data = %trimr(data) + '*OBJALTER,';
                        endif;
                        if %trim(fil_objref) = 'X';
                            data = %trimr(data) + '*OBJREF,';
                        endif;
                        if %trim(fil_read) = 'X';
                            data = %trimr(data) + '*READ,';
                        endif;
                        if %trim(fil_add) = 'X';
                            data = %trimr(data) + '*ADD,';
                        endif;
                        if %trim(fil_upd) = 'X';
                            data = %trimr(data) + '*UPD,';
                        endif;
                        if %trim(fil_dlt) = 'X';
                            data = %trimr(data) + '*DLT,';
                        endif;
                        if %trim(fil_exec) = 'X';
                            data = %trimr(data) + '*EXECUTE';
                        endif;
                        execute_change(option : data : objlongschema : objname : objtype : chg_count : err_count);                    

                    endif;
                else;
                endif;
            else;
                if %trim(fil_objobja) = 'USER DEF';
                    chg_count += 1;
                    clear logtxt;
                    logsts = 'C';
                    logtxt = 'CHG' + %editc(chg_count:'X') + 
                                '. Obj Authority Not found (FIL_USRDEF)			: ' + objlongschema + 
                                '  ' + objname + '  ' + objtype;
                    writelog(logsts : logtxt);
                    clear logtxt;
                    logsts = 'C';
                    logtxt = '-  File user / obja										: ' + fil_usr + 
                                '  ' + fil_objobja;
                    writelog(logsts : logtxt);
                    option = 'OBJNA';
                    data = fil_usr + ',' + %trim(fil_objobja);
                    execute_change(option : data : objlongschema : objname : objtype : chg_count : err_count);
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
                    option = 'OBJNA';
                    data = fil_usr + ',' + %trim(fil_objobja);
                    execute_change(option : data : objlongschema : objname : objtype : chg_count : err_count);
                endif;
            endif; 
            exec sql fetch next from autcur into :fil_usr, :fil_objobja, :fil_grpn, :fil_objopr, :fil_objomgt, 
                :fil_objexist, :fil_objalter, :fil_objref, :fil_read, :fil_add, :fil_upd, :fil_dlt, :fil_exec;
        endif;      
    enddo;
    exec sql close autcur;
    //
    return;
end-proc;

dcl-proc check_autl;
    dcl-pi *n;
        target_libnm char(10);
        target_filnm char(10);
        objlongschema char(10);
        objname char(10);
        objtype char(7);
        chg_count packed(5:0);
        err_count packed(5:0);
    end-pi;
    dcl-s cur_autl char(10);
    dcl-s fil_autl char(10);
    dcl-s stmt char(1500);
    dcl-s option char(5);
    dcl-s data char(100);
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
    stmt = 'select coalesce(oaanam,''*NONE'') as oaanam from ' + %trim(target_libnm) + '.' + %trim(target_filnm) + ' ' +
                'where oalib = ? ' +
                'and oaname = ? ' +
                'and oatype = ? ' +
                'and oausr = ''*PUBLIC'' ' +
                'fetch first 1 row only';
    exec sql prepare preautl from :stmt;
    exec sql declare autl cursor for preautl;
    exec sql open autl using :objlongschema, :objname, :objtype;
    exec sql fetch from autl into :fil_autl;
    // exec sql values(select coalesce(oaanam,'*NONE') as oaanam from ddscinfo.objaut
    //                         where oalib = :objlongschema
    //                         and oaname = :objname
    //                         and oatype = :objtype
    //                         and oausr = '*PUBLIC'
    //                         fetch first 1 row only)
    //                 into :fil_autl;
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
            option = 'AUTHL';
            data = %trim(fil_autl);
            execute_change(option : data : objlongschema : objname : objtype : chg_count : err_count);
        endif;
    else;
        err_count += 1;
        clear logtxt;
        logsts = 'C';
        logtxt = 'ERR' + %editc(err_count:'X') + '. Auth_List Not found: ' + objlongschema + '  ' + objname + '  ' + objtype;
        writelog(logsts : logtxt);

        clear logtxt;
        logsts = 'C';
        logtxt = '-  File autl : ' + %trim(fil_autl);
        writelog(logsts : logtxt);
    endif;
    exec sql close autl;
    //
    return;
end-proc;

dcl-proc check_owner;
    dcl-pi *n;
        target_libnm char(10);
        target_filnm char(10);
        objlongschema char(10);
        objname char(10);
        objtype char(7);
        chg_count packed(5:0);
        err_count packed(5:0);
    end-pi;
    dcl-s cur_owner char(10);
    dcl-s fil_owner char(10);
    dcl-s stmt char(1500);
    dcl-s option char(5);
    dcl-s data char(100);
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
    stmt = 'select coalesce(oaown,''*NONE'') as oaown from ' + %trim(target_libnm) + '.' + %trim(target_filnm) + ' ' +
                'where oalib = ? ' +
                'and oaname = ? ' +
                'and oatype = ? ' +
                'and oausr = ''*PUBLIC'' ' +
                'fetch first 1 row only';
    exec sql prepare preowner from :stmt;
    exec sql declare owner cursor for preowner;
    exec sql open owner using :objlongschema, :objname, :objtype;
    exec sql fetch from owner into :fil_owner;
    // exec sql)
    // exec sql values(select coalesce(oaown,'') as oaown from ddscinfo.objaut
    //                         where oalib = :objlongschema
    //                         and oaname = :objname
    //                         and oatype = :objtype
    //                         and oausr = '*PUBLIC'
    //                         fetch first 1 row only)
    //                 into :fil_owner;
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
            option = 'OWNER';
            data = %trim(fil_owner);
            execute_change(option : data : objlongschema : objname : objtype : chg_count : err_count);
        endif;
    else;
        err_count += 1;
        clear logtxt;
        logsts = 'C';
        logtxt = 'ERR' + %editc(err_count:'X') + '. Owner Not found: ' + objlongschema + '  ' + objname + '  ' + objtype;
        writelog(logsts : logtxt);

        clear logtxt;
        logsts = 'C';
        logtxt = '-  File owner: ' + %trim(fil_owner);
        writelog(logsts : logtxt);
    endif;
    exec sql close owner;
    //
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
