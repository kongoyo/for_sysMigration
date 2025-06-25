**free
ctl-opt option(*srcstmt) dftactgrp(*no) ;

// user-input remote hostname
dcl-pi *n ;
  rmtlocnm char(8);
end-pi;
dcl-s cur_sysnm char(8);
dcl-s lcllocnm char(8);

// Get current system name
exec sql 
  values current server into :cur_sysnm;
lcllocnm = cur_sysnm ; 

// Aping Test
monitor;
  aping(rmtlocnm) ;
on-error 0202;
endmon;

// DDMF Test
monitor;
  read_ddmf(rmtlocnm) ;
on-error 0202;
endmon;

// send network file Test 
monitor; 
  sndnf(rmtlocnm : lcllocnm) ;
on-error 0202;
endmon;

*inlr = *on ;
return ;

dcl-proc APING;
  dcl-pi *n ;
    rmtlocnm char(8);
  end-pi ;
  dcl-pr syscmd int(10) ExtProc('system');
  *n Pointer Value Options(*String);
  end-pr;
  dcl-s returnCode int(3);
  dcl-s commandString varchar(512);

  commandString = 'aping rmtlocname(' + %trim(rmtlocnm) + ') msgmode(*quiet)' ;
  snd-msg commandString;

  returnCode = syscmd(commandString);
  if returnCode <> 0;
    snd-msg *ESCAPE %msg('APG0002' : 'STVMSGF');
  else; 
    snd-msg *INFO %msg('APG0001' : 'STVMSGF');
  endif;
end-proc;

dcl-proc read_ddmf;
  dcl-pi *n ;
    rmtlocnm char(8);
  end-pi ;
  dcl-pr syscmd int(10) ExtProc('system');
  *n Pointer Value Options(*String);
  end-pr;
  dcl-s returnCode int(3);
  dcl-s commandString varchar(512);

  commandString = 'CRTDDMF FILE(QTEMP/TSTDDMF) ' +  
                  'RMTFILE(QUSRSYS/QATOCSTART) RMTLOCNAME(' + %trim(rmtlocnm) + ' *SNA)';
  returnCode = syscmd(commandString);
  if returnCode <> 0 ;
    snd-msg '--- Create DDM file error! ---';
  endif;

  commandString = 'DSPPFM FILE(QTEMP/TSTDDMF)';
  returnCode = syscmd(commandString);
  if returnCode <> 0;
    snd-msg *ESCAPE %msg('DMF0002' : 'STVMSGF');
  else; 
    snd-msg *INFO %msg('DMF0001' : 'STVMSGF');
  endif;
end-proc;

dcl-proc sndnf;
  dcl-pi *n ;
    rmtlocnm char(8);
    lcllocnm char(8);
  end-pi ;
  dcl-pr syscmd int(10) ExtProc('system');
  *n Pointer Value Options(*String);
  end-pr;
  dcl-s returnCode int(3);
  dcl-s commandString varchar(512);
  dcl-s Incmdstr varchar(100);
  dcl-s usrvar char(10) inz('IBMECS');
  dcl-s pwdvar char(10) inz('IBMECSUSR'); 

  // example command : SNDNETF FILE(QUSRSYS/QATOCHOST) TOUSRID((IBMECS CLARK73))
  Incmdstr = '''SNDNETF FILE(QUSRSYS/QATOCSTART) TOUSRID((IBMECS ' + %trim(lcllocnm) + '))''';
  commandString = 'RUNRMTCMD CMD(' + %trim(Incmdstr) + ') ' + 
                  'RMTLOCNAME(' + %trim(rmtlocnm) + ' *IP) ' + 
                  'RMTUSER(' + %trim(usrvar) + ') ' + 
                  'RMTPWD(' + %trim(pwdvar) + ')' ;
  snd-msg 'Command : ' + commandString;
  monitor;
    syscmd(commandString);
  on-error 0202;
    snd-msg *escape %msg('SNF0001' : 'STVMSGF');
  endmon;

  commandString = 'DSPMSG IBMECS';
  returnCode = syscmd(commandString);
  if returnCode <> 0;
    //
  endif;
end-proc;