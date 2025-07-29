**FREE
// Usage: 
ctl-opt option(*srcstmt) dftactgrp(*no);
dcl-pi *n;
  tapdev char(8);
end-pi;
// set sql commit option
exec sql set option commit = *none;
// Upper input parameter
tapdev = %upper(%trim(tapdev));
// prepare restore user list
prep_rstusr();
// execute restore user command
exec_rstusr(tapdev);
exec_rstaut();

*inlr = *on;
return;

dcl-proc prep_rstusr;
  // prepare restore user list
  exec sql drop table ddscinfo.exsusrvol;
  exec sql create table ddscinfo.exsusrvol as
                  (select objname,
                          coalesce(save_volume, 'NA') as savvol,
                          coalesce(save_sequence_number, 0) as savseq
                    from table ( qsys2.object_statistics(
                      object_schema => 'QSYS', objtypelist => '*USRPRF'
                      ))
                    where objname not like 'Q%' and 
                          (save_volume <> 'NA' and save_sequence_number <> 0)
                    order by save_volume
                  ) with data;
  return;
end-proc;

dcl-proc exec_rstusr;
  dcl-pi *n;
    tapdev char(8);
  end-pi;
  dcl-ds exsusrvol extname('DDSCINFO/EXSUSRVOL') qualified end-ds; 
  dcl-pr syscmd int(10) ExtProc('system');
    *n Pointer Value Options(*String);
  end-pr;
  dcl-s cmdstr varchar(512);
  dcl-s returnCode int(5);
  dcl-s logsts char(1); // T: Log Title  C: Log Continue  E: Log Ending
  dcl-s logtxt char(1500);
  // read file
  exec sql declare wk_rstusr cursor for 
            select objname, savvol, savseq from ddscinfo.exsusrvol order by savvol;
  exec sql open wk_rstusr;
  exec sql fetch next from wk_rstusr into :exsusrvol;
  dow sqlcod = 0;      
    // snd-msg 'User: ' + exsusrvol.objname + '  Volume: ' + exsusrvol.savvol +
    //         '  Sequence: ' + %char(exsusrvol.savseq);
    // SECDTA(*USRPRF)
    cmdstr = 'RSTUSRPRF DEV(' + %trim(tapdev) +
              ') USRPRF(' + %trim(exsusrvol.objname) +
              ') VOL(' + %trim(exsusrvol.savvol) +
              ') SEQNBR(' + %trim(%char(exsusrvol.savseq)) +
              ') ALWOBJDIF(*ALL) SECDTA(*USRPRF)';
    // returnCode = syscmd(cmdstr);
    // snd-msg 'CMD: ' + %trim(cmdstr);
    if returnCode <> 0;
      logsts = 'C';
      logtxt = 'User ' + %trim(exsusrvol.objname) + ' restore *usrprf from ' +
               %trim(exsusrvol.savvol) + ' failed.';
      writelog(logsts: logtxt);
    endif;
    // SECDTA(*PVTAUT)
    cmdstr = 'RSTUSRPRF DEV(' + %trim(tapdev) +
              ') USRPRF(' + %trim(exsusrvol.objname) +
              ') VOL(' + %trim(exsusrvol.savvol) +
              ') SEQNBR(' + %trim(%char(exsusrvol.savseq)) +
              ') ALWOBJDIF(*ALL) SECDTA(*PVTAUT)';
    // returnCode = syscmd(cmdstr);
    // snd-msg 'CMD: ' + %trim(cmdstr);
    if returnCode <> 0;
      logsts = 'C';
      logtxt = 'User ' + %trim(exsusrvol.objname) + ' restore *pvtaut from ' +
               %trim(exsusrvol.savvol) + ' failed.';
      writelog(logsts: logtxt);
    endif;
    // SECDTA(*PWDGRP)
    cmdstr = 'RSTUSRPRF DEV(' + %trim(tapdev) +
              ') USRPRF(' + %trim(exsusrvol.objname) +
              ') VOL(' + %trim(exsusrvol.savvol) +
              ') SEQNBR(' + %trim(%char(exsusrvol.savseq)) +
              ') ALWOBJDIF(*ALL) SECDTA(*PWDGRP)';
    // returnCode = syscmd(cmdstr);
    // snd-msg 'CMD: ' + %trim(cmdstr);
    if returnCode <> 0;
      logsts = 'C';
      logtxt = 'User ' + %trim(exsusrvol.objname) + ' restore *pwdgrp from ' +
               %trim(exsusrvol.savvol) + ' failed.';
      writelog(logsts: logtxt);
    endif;
    exec sql fetch next from wk_rstusr into :exsusrvol;
  enddo;
  exec sql close wk_rstusr;
  return;
end-proc;

dcl-proc exec_rstaut;
  dcl-s usraut char(100);
  dcl-ds exsusrvol extname('DDSCINFO/EXSUSRVOL') qualified end-ds; 
  dcl-pr syscmd int(10) ExtProc('system');
    *n Pointer Value Options(*String);
  end-pr;
  dcl-s cmdstr varchar(512);
  dcl-s returnCode int(5);
  dcl-s logsts char(1); // T: Log Title  C: Log Continue  E: Log Ending
  dcl-s logtxt char(1500);
  dcl-s cnt int(5) inz(0);
  // read file
  exec sql declare wk_rstaut cursor for 
            select objname from ddscinfo.exsusrvol order by savvol;
  exec sql open wk_rstaut;
  exec sql fetch next from wk_rstaut into :exsusrvol.objname;
  dow sqlcod = 0;
    usraut = %trimr(usraut) + ' ' + %trim(exsusrvol.objname) + ' ';
    cnt += 1;
    if %rem(cnt : 10) = 0;
      cmdstr = 'RSTAUT USRPRF(' + %trim(usraut) + ')';
      // returnCode = syscmd(cmdstr);
      snd-msg 'CMD: ' + %trim(cmdstr);
      if returnCode <> 0;
        logsts = 'C';
        logtxt = 'Restore user authority failed.';
        writelog(logsts: logtxt);
      endif;
      clear usraut;
    endif;
    exec sql fetch next from wk_rstaut into :exsusrvol.objname;
  enddo;
  if %len(%trim(usraut)) > 0;
    cmdstr = 'RSTAUT USRPRF(' + %trim(usraut) + ')';
    // returnCode = syscmd(cmdstr);
    snd-msg 'CMD: ' + %trim(cmdstr);
    if returnCode <> 0;
      logsts = 'C';
      logtxt = 'Restore user authority failed.';
      writelog(logsts: logtxt);
    endif;
    clear usraut;
  endif;
  exec sql close wk_rstaut;
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
        // // test only
        // if %scan('CLARK' : %trim(cur_sysnm)) = 1;
        //     cur_sysnm = 'KSG01N';
        // endif;
        // // test only
  endif;
  if %len(%trim(logLocation)) = 0;
    logLocation = '/home/rstexsusr_' + %trim(cur_sysnm) + 
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


// - Compile prerequisite
// create table ddscinfo.exsusrvol as
//       (select objname,
//               coalesce(save_volume, 'NA') as savvol,
//               coalesce(save_sequence_number, 0) as savseq
//           from table (
//               qsys2.object_statistics(object_schema => 'QSYS', objtypelist => '*USRPRF')
//             )
//           where objname not like 'Q%' and save_volume <> 'NA'
//           order by save_volume)
//       with data;
// - Compile command
// CRTSQLRPGI OBJ(STEVE/RSTEXSUSR)                      
//            SRCSTMF('/home/IBMECS/builds/for_sysMigration/Complete/rstexsusr.pgm.sqlrpgle')
//            OPTION(*EVENTF)                           
//            RPGPPOPT(*LVL2)                           
//            CLOSQLCSR(*ENDMOD)                        
//            DBGVIEW(*SOURCE)                          
//            CVTCCSID(*JOB)                            
//            COMPILEOPT('TGTCCSID(937)')


