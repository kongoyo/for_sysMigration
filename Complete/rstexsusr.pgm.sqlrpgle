**FREE
//
// 呼叫時需要輸入磁帶機名稱，可用TAPXX或是TAPMLBXX
// 查詢 table ( qsys2.users() ) 取得已存在的使用者帳號清單
// 查詢 table ( qsys2.qsys2.object_statistics ) 取得 save_volume 資訊
// 組合指令 RSTUSRPRF 指定 VOLUME 進行倒檔
// 
ctl-opt option(*srcstmt) dftactgrp(*no);
// Declare User input Tape device
dcl-pi *n;
  tapdev char(8);
end-pi;
// Declare data structures
DCL-DS usrsavdev QUALIFIED;
  objname     varchar(10);
  save_volume varchar(71);
  save_seqnum packed(10:0);
END-DS;
//
dcl-pr syscmd int(10) ExtProc('system');
  *n Pointer Value Options(*String);
end-pr;
//
dcl-s cmdstr varchar(7000);
dcl-s returnCode int(5);
dcl-s stmt varchar(512);
dcl-s username char(10);
dcl-s usraut varchar(5000);

dcl-s ifsfnm char(200);
dcl-s cur_date date;
dcl-s count int(10) inz(0);

tapdev = %upper(%trim(tapdev));

exec sql values(current_date) into :cur_date;
ifsfnm = '/home/qsecofr/kgi_log/rstexsusr_' + %trim(%char(cur_date)) + '.log';
exec sql call QSYS2.IFS_WRITE_UTF8(trim(:ifsfnm),
                          '--- Process begin ---',
                          END_OF_LINE => 'CRLF'); 

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
    count = count + 1;
    // if %scan('Q' : username : 1 : 1) = 0;
      snd-msg '----- Process User ' + %trim(username) + ' -----';
      exec sql select 
               coalesce(objname,'') as objname,
               coalesce(save_volume,'') as save_volume,
               coalesce(save_sequence_number,0) as save_seqnum
               into :usrsavdev.objname, 
                    :usrsavdev.save_volume, 
                    :usrsavdev.save_seqnum
              from table(qsys2.object_statistics(
              object_schema => 'QSYS', 
              objtypelist => '*USRPRF', 
              object_name => trim(:username))) ;  
      snd-msg '  SQL code   : ' + %char(sqlcod);

      // Action section
      if sqlcod = 0 ;

      // Restore *usrprf
        cmdstr = 'RSTUSRPRF DEV(' + %trim(tapdev) +
              ') USRPRF(' + %trim(usrsavdev.objname) +
              ') VOL(' + %trim(usrsavdev.save_volume) +
              ') SEQNBR(' + %trim(%char(usrsavdev.save_seqnum)) +
              ') ALWOBJDIF(*ALL) SECDTA(*USRPRF)';
        snd-msg '1st Command: ' + %trim(cmdstr);
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
        snd-msg '2nd Command: ' + %trim(cmdstr);
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
        snd-msg '3rd Command: ' + %trim(cmdstr);
        // returnCode = syscmd(cmdstr);
        // if returnCode <> 0;
        //   snd-msg 'sqlcod: ' + %char(sqlcod);
        //   snd-msg '--- Restore *pwdgrp error ---';
        // endif;
        // usraut
        usraut = %trimr(usraut) + ' ' + %trim(usrsavdev.objname) + ' ';

      endif;
      // Action section
      if count = 50;
        clear cmdstr;
        // snd-msg 'Usraut: ' + %trim(usraut);
        cmdstr = 'RSTAUT USRPRF(' + %trim(usraut) + ')';
        exec sql call QSYS2.IFS_WRITE_UTF8(trim(:ifsfnm),
                                          trim(:cmdstr),
                                          OVERWRITE => 'APPEND',
                                          END_OF_LINE => 'CRLF'); 

        // snd-msg 'Restore user authority: ' + %trim(cmdstr);
        clear count;
        clear usraut;
      endif;
      // returnCode = syscmd(cmdstr);
    // endif;
    snd-msg '----- Finish User ' + %trim(username) + ' -----';
  endif;
  exec sql fetch next from curusrlst into :username;    
enddo;

clear cmdstr;
// snd-msg 'Usraut: ' + %trim(usraut);
cmdstr = 'RSTAUT USRPRF(' + %trim(usraut) + ')';
exec sql call QSYS2.IFS_WRITE_UTF8(trim(:ifsfnm),
                                  trim(:cmdstr),
                                  OVERWRITE => 'APPEND',
                                  END_OF_LINE => 'CRLF'); 
// snd-msg 'Restore user authority: ' + %trim(cmdstr);
clear count;
clear usraut;

exec sql call QSYS2.IFS_WRITE_UTF8(trim(:ifsfnm),
                          '--- Process end ---',
                          END_OF_LINE => 'CRLF');

exec sql close curusrlst;

*inlr = *on;
return;
