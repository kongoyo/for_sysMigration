**free
ctl-opt main(Main) option(*srcstmt) dftactgrp(*no) ;
dcl-pr Main extpgm('TESTRPG1') ;
  *n char(8);
end-pr ;
// declare for Program status data structure (PSDS)
dcl-ds Pgm psds qualified ;
  JobUser char(10) pos(254);          // Job user
  SysName char(8) pos(396);           // System name
end-ds ;
// Main Procedure
dcl-proc Main ;
  dcl-pi *n ;
    rmtlocnm char(8);
  end-pi ;
  dcl-s currentUser char(10);
  dcl-s messageText char(32);
  dcl-s ifsfnm char(200);
  dcl-s cur_date date;
  dcl-s cur_time time;
  dcl-s cur_sysnm char(8);
  dcl-s logtxt char(200);
  // collect current date time servername
  exec sql values(current_date) into :cur_date;
  exec sql values(current_time) into :cur_time;
  exec sql values current server into :cur_sysnm;
  // clear logfile and write title
  ifsfnm = '/home/qsecofr/kgi_log/testrpg1_' + %trim(%scanrpl('-' : '' : %char(cur_date))) + 
         '_' + %trim(%scanrpl('.' : '' : %char(cur_time))) + '.log';
  exec sql call QSYS2.IFS_WRITE_UTF8(trim(:ifsfnm),
                                  '',
                                  OVERWRITE => 'REPLACE',
                                  END_OF_LINE => 'NONE');
  logtxt = ' ' + %trim(%char(cur_date)) + 
         ' ' + %trim(%char(cur_time)) + 
         ' ' + %trim(cur_sysnm) + 
         ' ' + 'Test sqlrpgle function start.';
  exec sql call QSYS2.IFS_WRITE_UTF8(trim(:ifsfnm),
                                  trim(:logtxt),
                                  END_OF_LINE => 'CRLF');
  // initialize
  rmtlocnm = %upper(%trim(rmtlocnm));
  currentUser = Pgm.JobUser;
  // aping test
  // snd-msg '-- Aping test from ' + pgm.SysName + ' --';
  aping(rmtlocnm : messageText);
  logtxt = ' ' + %trim(%char(cur_date)) + 
         ' ' + %trim(%char(cur_time)) + 
         ' ' + %trim(cur_sysnm) + 
         ' ' + '-- Aping test from ' + pgm.SysName + ' -- : ' + %trim(messageText);
  exec sql call QSYS2.IFS_WRITE_UTF8(trim(:ifsfnm),
                          trim(:logtxt),
                          OVERWRITE => 'APPEND',
                          END_OF_LINE => 'CRLF');
  // ddmf test
  // snd-msg '-- DDMF test from ' + pgm.SysName + ' --';
  ddmf(rmtlocnm : messageText);
  logtxt = ' ' + %trim(%char(cur_date)) + 
         ' ' + %trim(%char(cur_time)) + 
         ' ' + %trim(cur_sysnm) + 
         ' ' + '-- DDMF test from ' + pgm.SysName + ' -- : ' + %trim(messageText);
  exec sql call QSYS2.IFS_WRITE_UTF8(trim(:ifsfnm),
                          trim(:logtxt),
                          OVERWRITE => 'APPEND',
                          END_OF_LINE => 'CRLF');
  // sndnetf test
  



  logtxt = ' ' + %trim(%char(cur_date)) + 
         ' ' + %trim(%char(cur_time)) + 
         ' ' + %trim(cur_sysnm) + 
         ' ' + 'Test sqlrpgle function finished.';
  exec sql call QSYS2.IFS_WRITE_UTF8(trim(:ifsfnm),
                                  trim(:logtxt),
                                  OVERWRITE => 'APPEND',
                                  END_OF_LINE => 'CRLF');
  *inlr = *on;
  return ;
end-proc ;

dcl-proc aping ;
  dcl-pi *n ;
    rmtlocnm char(8);
    inMessage char(32);
  end-pi ;
  dcl-s cmdstr varchar(512);
  clear cmdstr;
  cmdstr = 'aping rmtlocname(' + %trim(rmtlocnm) + ') msgmode(*quiet)' ;
  // snd-msg %trim(cmdstr);
  exec sql call qsys2.qcmdexc(:cmdstr);
  if sqlcod = -443;
    inMessage = 'Aping ' + %trim(rmtlocnm) + ' failed.';
    // snd-msg %trim(inMessage);
  else; 
    inMessage = 'Aping ' + %trim(rmtlocnm) + ' success.';
  endif;
end-proc;

dcl-proc ddmf ;
  dcl-pi *n ;
    rmtlocnm char(8);
    inMessage char(32);
  end-pi ;
  dcl-pr syscmd int(10) ExtProc('system');
    *n Pointer Value Options(*String);
  end-pr;
  dcl-s returnCode int(3);
  dcl-s cmdstr varchar(512);

  cmdstr = 'aping rmtlocname(' + %trim(rmtlocnm) + ') msgmode(*quiet)' ;
  returnCode = syscmd(cmdstr);
  if returnCode <> 0;
    inMessage = 'Aping ' + %trim(rmtlocnm) + ' failed.';
    return;
  else; 
    inMessage = 'Aping ' + %trim(rmtlocnm) + ' success.';
    return;
  endif;

end-proc ;

dcl-proc sndnetf ;
end-proc ;