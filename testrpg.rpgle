**free
ctl-opt main(Main) option(*srcstmt) dftactgrp(*no) ;
dcl-pr Main extpgm('TESTRPG') ;
  *n char(8);
end-pr ;
// declare for Program status data structure (PSDS)
dcl-ds Pgm psds qualified ;
  JobUser char(10) pos(254);          // Job user
  SysName char(8) pos(396);           // System name
end-ds ;
// declare for Break message
dcl-pr QEZSNDMG extpgm  ;
  *n char(10) const ;
  *n char(10) const ;
  *n char(32) const ;
  *n int(10) const  ;
  *n char(10) const ;
  *n int(10) const ;
  *n int(10) const ;
  *n int(10) const ;
  *n char(8) ;
  *n char(1) const ;
  *n char(20) const ;
  *n char(4) const ;
  *n int(10) const ;
end-pr ;

dcl-proc Main ;
  dcl-pi *n ;
    rmtlocnm char(8);
  end-pi ;
  dcl-s currentUser char(10);
  dcl-s messageText char(32);
  // dcl-s currentServer char(8);
  dcl-s ErrorCode char(8) inz(*loval);

  currentUser = Pgm.JobUser;
  snd-msg '-- Test from ' + pgm.SysName + ' --';
  // aping test
  aping(rmtlocnm : messageText);
  QEZSNDMG('*INFO':
           '*NORMAL':
           messageText:
           %len(%trim(messageText)): // Use the actual length for safety
           currentUser:
           1:
           0:
           0:
           ErrorCode:
           'N':
           ' ':
           '*USR':
           0) ;
  return ;
end-proc ;

dcl-proc aping ;
  dcl-pi *n ;
    rmtlocnm char(8);
    inMessage char(32);
  end-pi ;
  dcl-pr syscmd int(10) ExtProc('system');
    *n Pointer Value Options(*String);
  end-pr;
  dcl-s returnCode int(3);
  dcl-s commandString varchar(512);

  commandString = 'aping rmtlocname(' + %trim(rmtlocnm) + ') msgmode(*quiet)' ;
  returnCode = syscmd(commandString);
  if returnCode <> 0;
    inMessage = 'Aping ' + %trim(rmtlocnm) + ' failed.';
    return;
  else; 
    inMessage = 'Aping ' + %trim(rmtlocnm) + ' success.';
    return;
  endif;
end-proc;

dcl-proc ddmf ;
end-proc ;

dcl-proc sndnetf ;
end-proc ;