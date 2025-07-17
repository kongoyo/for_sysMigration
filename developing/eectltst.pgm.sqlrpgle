**free
// *******************************************************************
// Program function  : Do APING、DDMF、SNDNETF test from New server.                                
// Program Name      : EECTLTST.sqlrpgle
// Programmer Name   : STEVE                                       
// Modification Date : 2025/07/07                                   
// *******************************************************************
// Parameters        : --- write log to ifs file ---
//                     ifsfnm char(200)     - Log file name(include path)
//                     logtxt char(256)     - Log text
//                     cur_date date        - Current date
//                     cur_time time        - Current time  
//                     cur_sysnm char(8)    - current system name
//
//                     --- log format ---
//                     XXXX-XX-XX HH.MM.SS SYSNAME logText(command string or executed result). 
//
//                     --- execute command string ---
//                     cmdstr char(256)     - commandString
//
//                     --- collect target ctld remote location name ---
//                     rmtlocnm char(8)     - Remote location name
//                     inMessage char(32)   - input Message
//                     lcllocnm char(8)     - local location name
//                     ErrorCode char(8)    - Error code
// *******************************************************************
// Usage             : CALL *LIBL/EECTLTST ('CLARK75')
// *******************************************************************
Ctl-Opt option(*srcstmt) dftactgrp(*no);
// 
Dcl-Pi *N;
  rmtlocnm char(8);
End-Pi;
// declare for Program status data structure (PSDS)
dcl-ds Pgm psds qualified ;
  JobUser char(10) ;          // Job user
  SysName char(8) ;           // System name
end-ds;

dcl-s inMessage char(32);
dcl-s cur_sysnm char(8);
dcl-s lcllocnm char(8);
dcl-s ErrorCode char(8);

// Get current system name
exec sql 
  values current server into :cur_sysnm;
    lcllocnm = cur_sysnm ; 

// Aping Test
aping(rmtlocnm : inMessage) ;
// DDMF Test
read_ddmf(rmtlocnm : inMessage) ;
// send network file Test 
sndnf(rmtlocnm : lcllocnm : inMessage) ;
*inlr = *on ;
return ;

dcl-proc APING;
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
  // snd-msg commandString;

  returnCode = syscmd(commandString);
  if returnCode <> 0;
    inMessage = 'Aping failed.';
    return;
  else; 
    inMessage = 'Aping success.';
    return;
  endif;
end-proc;

dcl-proc read_ddmf;
  dcl-pi *n ;
    rmtlocnm char(8);
    inMessage char(32);
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
    inMessage = 'DDMF Test failed.';
    return;
  else; 
    inMessage = 'DDMF Test success.';
    return;
  endif;
end-proc;

dcl-proc sndnf;
  dcl-pi *n ;
    rmtlocnm char(8);
    lcllocnm char(8);
    inMessage char(32);
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
    inMessage = 'Remote command failed.';
    return;
  endmon;

  commandString = 'DSPMSG IBMECS';
  returnCode = syscmd(commandString);
  if returnCode <> 0;
    //
  endif;
end-proc;