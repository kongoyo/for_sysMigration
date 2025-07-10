**FREE
ctl-opt Main(rstusrlib) option(*srcstmt) dftactgrp(*no);
// Main procedure
dcl-proc rstusrlib;
    dcl-pi *n;
        tapdev char(10);
    end-pi;
    //
    dcl-s logtxt char(200);
    // Log Title
    wrtlog('T' : logtxt);
    // Restore existing user profiles
    rstexsusr(tapdev);
    // Restore user libraries and omit specific libraries
    // KSG01 & AS081: SGKGISN、OSKGISN、FUKGISN、VCKGISN、FEKGISN
    // AS101 & KSF03: SGKGISN only
    rstlib(cur_sysnm);
    // Log Ending
    wrtlog('E' : logtxt);
    *inlr = *on;
    return;
end-proc;

dcl-proc wrtlog;
    dcl-pi *n;
        logSts char(1); // T: Log Title  C: Log Content  E: Log Ending
        logtxt char(200);
    end-pi;
    dcl-s cur_date date;
    dcl-s cur_time time;
    dcl-s cur_sysnm char(8);
    dcl-s logLocation char(100);
    
    exec sql values(current_date) into :cur_date;
    exec sql values(current_time) into :cur_time;
    exec sql values current server into :cur_sysnm;
    logLocation = '/home/rstusrlib_' + %trim(%scanrpl('-' : '' : %char(cur_date))) + 
                  '_' + %trim(%scanrpl('.' : '' : %char(cur_time))) + '.log';
    select;
        when logSts = 'T';
            exec sql call QSYS2.IFS_WRITE_UTF8(trim(:logLocation),
                            '',
                            OVERWRITE => 'REPLACE',
                            END_OF_LINE => 'NONE');
            if %len(%trim(logtxt)) = 0;
                logtxt = '--- Process start ---';
            endif;
            exec sql call QSYS2.IFS_WRITE_UTF8(trim(:logLocation), 
                            ' ' || trim(char(cur_date)) ||
                            ' ' || trim(char(cur_time)) ||
                            ' ' || trim(cur_sysnm) ||
                            ' ' || trim(logtxt), 
                            END_OF_LINE => 'CRLF');
        when logSts = 'C';
            exec sql call QSYS2.IFS_WRITE_UTF8(trim(:logLocation), 
                            ' ' || trim(char(cur_date)) ||
                            ' ' || trim(char(cur_time)) ||
                            ' ' || trim(cur_sysnm) ||
                            ' ' || trim(logtxt),
                            OVERWRITE => 'APPEND',
                            END_OF_LINE => 'CRLF');
        when logSts = 'E';
            if %len(%trim(logtxt)) = 0;
                logtxt = '--- Process finished ---';
            endif;
            exec sql call QSYS2.IFS_WRITE_UTF8(trim(:logLocation), 
                            ' ' || trim(char(cur_date)) ||
                            ' ' || trim(char(cur_time)) ||
                            ' ' || trim(cur_sysnm) ||
                            ' ' || trim(logtxt),
                            OVERWRITE => 'APPEND',
                            END_OF_LINE => 'CRLF');
        other;
            snd-msg 'Write Log failed.';
    endsl;
end-proc;

dcl-proc rstlib;
    dcl-pi *n;
        cur_sysnm char(8);
    end-pi;


end-proc;

dcl-proc rstexsusr;
    dcl-pi *n;
        tapdev char(8);
    end-pi;   
    tapdev = %upper(%trim(tapdev));

    logSts = 'T';
    logtxt = 'Restore exist user profile start.';
    wrtlog('T' : logtxt);
  // Declare cursor for table qsys2.users()
    clear stmt;
    stmt = 'select odobnm from table(qsys2.users())';
    exec sql prepare preusrlst from :stmt;
    exec sql declare curusrlst cursor for preusrlst;
    exec sql open curusrlst;
    exec sql fetch next from curusrlst into :username;
        //
    dow sqlcod = 0;
        if sqlcod = 0;
            if %scan('Q' : username : 1) <> 1;
                count = count + 1;
                wrtlog('C' : '----- Process User ' + %trim(username) + ' -----');
                exec sql select 
                            coalesce(objname,'') as objname,
                            coalesce(save_volume,'') as save_volume,
                            coalesce(save_sequence_number,0) as save_seqnum
                        into :usrsavdev.objname, :usrsavdev.save_volume, :usrsavdev.save_seqnum
                        from table(qsys2.object_statistics(
                        object_schema => 'QSYS', 
                        objtypelist => '*USRPRF', 
                        object_name => trim(:username))) ;  
                // Action section
                if sqlcod = 0 ;
                    if %trim(usrsavdev.save_volume) <> '';
                    // Restore *usrprf
                        cmdstr = 'RSTUSRPRF DEV(' + %trim(tapdev) +
                                ') USRPRF(' + %trim(usrsavdev.objname) +
                                ') VOL(' + %trim(usrsavdev.save_volume) +
                                ') SEQNBR(' + %trim(%char(usrsavdev.save_seqnum)) +
                                ') ALWOBJDIF(*ALL) SECDTA(*USRPRF)';
                        exec sql call qsys2.qcmdexc(:cmdstr);
                        wrtlog('C' : ' ' + '1st Command: ' + %trim(cmdstr));
        // returnCode = syscmd(cmdstr);
        // if returnCode <> 0;
        //   snd-msg 'sqlcod: ' + %char(sqlcod);
        //   snd-msg '--- Restore *usrprf error ---';
        // endif;
        // Restore *pvtaut
                        cmdstr = 'RSTUSRPRF DEV(' + %trim(tapdev) +
                                ') USRPRF(' + %trim(usrsavdev.objname) +
                                ') VOL(' + %trim(usrsavdev.save_volume) +
                                ') SEQNBR(' + %trim(%char(usrsavdev.save_seqnum)) +
                                ') ALWOBJDIF(*ALL) SECDTA(*PVTAUT)';
                        exec sql call qsys2.qcmdexc(:cmdstr);
                        wrtlog('C' : ' ' + '2nd Command: ' + %trim(cmdstr));
        // returnCode = syscmd(cmdstr);
        // if returnCode <> 0;
        //   snd-msg 'sqlcod: ' + %char(sqlcod);
        //   snd-msg '--- Restore *pvtaut error ---';
        // endif;
        // Restore *pwdgrp
                        cmdstr = 'RSTUSRPRF DEV(' + %trim(tapdev) +
                                ') USRPRF(' + %trim(usrsavdev.objname) +
                                ') VOL(' + %trim(usrsavdev.save_volume) +
                                ') SEQNBR(' + %trim(%char(usrsavdev.save_seqnum)) +
                                ') ALWOBJDIF(*ALL) SECDTA(*PWDGRP)';
                        exec sql call qsys2.qcmdexc(:cmdstr);
                        wrtlog('C' : ' ' + '3rd Command: ' + %trim(cmdstr));
        // returnCode = syscmd(cmdstr);
        // if returnCode <> 0;
        //   snd-msg 'sqlcod: ' + %char(sqlcod);
        //   snd-msg '--- Restore *pwdgrp error ---';
        // endif;
        // usraut
                        usraut = %trimr(usraut) + ' ' + %trim(usrsavdev.objname) + ' ';
                    endif;
                endif;
      // Action section
                if count = 10;
                    clear cmdstr;
                    if %len(%trim(usraut)) > 0;
          // snd-msg 'Usraut: ' + %trim(usraut);
                        cmdstr = 'RSTAUT USRPRF(' + %trim(usraut) + ')';
                        exec sql call qsys2.qcmdexc(:cmdstr);
                    endif;
        // snd-msg 'Restore user authority: ' + %trim(cmdstr);
                    clear count;
                    clear usraut;
                endif;
      // returnCode = syscmd(cmdstr);
      // snd-msg '----- Finish User ' + %trim(username) + ' -----';
            endif;
        endif;
        exec sql fetch next from curusrlst into :username;    
    enddo;

    clear cmdstr;
    // snd-msg 'Usraut: ' + %trim(usraut);
    if %len(%trim(usraut)) > 0;
        cmdstr = 'RSTAUT USRPRF(' + %trim(usraut) + ')';
        exec sql call qsys2.qcmdexc(:cmdstr);
    endif;
    // snd-msg 'Restore user authority: ' + %trim(cmdstr);
    clear count;
    clear usraut;
    exec sql close curusrlst;
end-proc;
