**free
ctl-opt option(*srcstmt) dftactgrp(*no) ; 

dcl-ds cfgsrc qualified;
  srcseq zoned(6);
  srcdat zoned(6);
  srcdta char(120);
end-ds;

dcl-ds cfgtbl qualified;
  ctld char(10);
  linktype char(10);
  rmtintneta char(15);
  lclintneta char(15);
  rmtcpname char(10);
end-ds;

dcl-ds tcphte qualified;
  ip_addr char(15);
  hostnme1 varchar(50);
  hostnme2 varchar(50);
end-ds;

dcl-s isNewCommandStart ind inz(*off);
dcl-s commandEndThisLine ind inz(*off);
dcl-s currentParsedLine char(120);
dcl-s pendingCommand char(1000);
dcl-s startPos int(10);

dcl-pr syscmd int(10) ExtProc('system');
  *n Pointer Value Options(*String);
end-pr;
dcl-s cmdstr char(100);
dcl-s returnCode int(3);

dcl-s cur_sysnm char(8);
dcl-s N_pos int(5);
dcl-s org_sysnm char(8);
dcl-s org_ip char(15);
dcl-s new_sysnm char(8);
dcl-s new_ip char(15);
dcl-s org_ctlnm char(10);
dcl-s new_ctlnm char(10);
dcl-s new_hostnme1 char(50);
dcl-s new_hostnme2 char(50);

// 取得現行主機名稱
exec sql 
  values current server into :cur_sysnm;


// 取得新機主機名稱
new_sysnm = 'AS081N' ;
// FOR_KGI : new_sysnm = cur_sysnm ; 

// 取得原機主機名稱
n_pos = %scan('N' : %UPPER(new_sysnm)) ;
if n_pos > 0;
  org_sysnm = %subst( new_sysnm : 1 : n_pos - 1 ) ;
endif;

// 取得原機 IP 位址
exec sql 
  select internet
  into   :org_ip 
  from qusrsys.qatochost
  where hostnme1 = :org_sysnm or 
        hostnme2 = :org_sysnm 
  fetch first 1 rows only;

// 取得新機 IP 位址
exec sql 
  select internet_address
  into   :new_ip
  from qsys2.netstat_interface_info 
  where line_description = '*VIRTUALIP' and 
  internet_address like '%10.102%'
  order by internet_address 
  fetch first 1 rows only;
  
// 組成要修改的原機 ctld name
org_ctlnm = 'TCP' + org_sysnm ;
// 組成要刪除的新機 ctld name
new_ctlnm = %trimr(org_ctlnm) + 'N' ;
// 組成要新增的原機 host table entry
new_hostnme1 = %trimr(org_sysnm) ;
new_hostnme2 = %trimr(org_sysnm) + '.APPN.SNA.IBM.COM' ;

snd-msg '--------------------------------------';
snd-msg '   New System Name     : ' + new_sysnm ;
snd-msg '   Original System Name: ' + org_sysnm ;
snd-msg '   New      IP address : ' + new_ip    ;
snd-msg '   Original IP address : ' + org_ip    ;
snd-msg '   New         ctlname : ' + new_ctlnm ;
snd-msg '   Original    ctlname : ' + org_ctlnm ;
snd-msg '--------------------------------------';

exec sql
  set transaction isolation level no commit ;

cmdstr = 'DLTOBJ OBJ(QTEMP/CFGSRC) OBJTYPE(*FILE)';
returnCode = syscmd(cmdstr);
if returnCode <> 0;
  snd-msg '-- DLTOBJ QTEMP/CFGSRC error ( This error can be ignored ) --';
endif;
cmdstr = 'CRTSRCPF FILE(QTEMP/CFGSRC) IGCDTA(*YES)';
returnCode = syscmd(cmdstr);
if returnCode <> 0;
  snd-msg '-- CRTSRCPF QTEMP/CFGSRC error --';
endif;
cmdstr = 'RTVCFGSRC CFGD(*ALL) CFGTYPE(*CTLD) SRCFILE(QTEMP/CFGSRC)';
returnCode = syscmd(cmdstr);
if returnCode <> 0;
  snd-msg '-- RTVCFGSRC QTEMP/CFGSRC error --';
endif;
cmdstr = 'DLTOBJ OBJ(QTEMP/CFGTBL) OBJTYPE(*FILE)';
returnCode = syscmd(cmdstr);
if returnCode <> 0;
  snd-msg '-- DLTOBJ QTEMP/CFGTBL error ( This error can be ignored ) --';
endif;

exec sql
  create table qtemp.cfgtbl (
    ctld varchar(10),           // Controller Name varchar(10)
    linktype varchar(10),       // Link Type       varchar(10)
    rmtintneta varchar(15),     // Remote IP       varchar(15)
    lclintneta varchar(15),     // Local  IP       varchar(15)
    rmtcpname varchar(10)       // Remote CP Name  varchar(10)
   );

exec sql
  declare cfgsrc cursor for
    select srcseq, srcdat, srcdta 
    from qtemp.cfgsrc 
    order by srcseq;

exec sql
  open cfgsrc;

exec sql
  fetch next from cfgsrc into :cfgsrc.srcseq, 
                              :cfgsrc.srcdat, 
                              :cfgsrc.srcdta ;

dow sqlcod = 0;
  if sqlcod = 0;
    currentParsedLine = %trimr(cfgsrc.srcdta); 
    isNewCommandStart = *off;
    if %scan('CRTCTLAPPC' : %trim(cfgsrc.srcdta)) = 1;
      isNewCommandStart = *on;
    endif;
    commandEndThisLine = *on;
    If %scan('+':currentParsedLine) > 1;
      startPos = %scan('+':currentParsedLine);
      currentParsedLine = %subst(currentParsedLine : 1 : startPos); 
      commandEndThisLine = *off; 
    else;
    endif;
    if isNewCommandStart and %len(%trim(pendingCommand)) > 0;
      ProcessCommand(pendingCommand); 
      clear pendingCommand;
    elseif %len(%trim(pendingCommand)) > 0;
      pendingCommand = %trimr(pendingCommand) + ' ' + %trim(currentParsedLine);
    else;
      pendingCommand = %trim(currentParsedLine);
    endif;
    if %len(%trimr(pendingCommand)) > %len(pendingCommand);
      pendingCommand = %subst(pendingCommand:1:%len(pendingCommand));
    else;
    endif;
    if commandEndThisLine and %len(%trim(pendingCommand)) > 0;
      ProcessCommand(pendingCommand); 
      clear pendingCommand;
    else;
    endif;

    exec sql
      fetch next from cfgsrc into :cfgsrc.srcseq, 
                                  :cfgsrc.srcdat, 
                                  :cfgsrc.srcdta ;
  elseif sqlcod = 100; 
    if %len(%trim(pendingCommand)) > 0;
      ProcessCommand(pendingCommand);
      clear pendingCommand;
    endif;
  else ;
    snd-msg 'ProcessCommand error with sqlcod : ' + %char(sqlcod);
  endif; 
enddo; 

exec sql
  close cfgsrc;

// 只篩選 TCP 開頭的 CTLD
exec sql  
  declare tcpctld cursor for
    select * 
      from qtemp.cfgtbl 
      where trim(cfgtbl.ctld) like 'TCP%';

exec sql 
  open tcpctld;

exec sql
  fetch from tcpctld into :cfgtbl.ctld,
                          :cfgtbl.linktype,
                          :cfgtbl.lclintneta,
                          :cfgtbl.rmtintneta,
                          :cfgtbl.rmtcpname ;

dow sqlcod = 0 ;
  if sqlcod = 0 ;
    snd-msg '--------------------------------------';
    snd-msg '** Target-System: ' + %trim(cfgtbl.rmtcpname);
    snd-msg '--------------------------------------';
    RemoteCommand(%trim(cfgtbl.rmtcpname) : org_ctlnm);
  elseif sqlcod = 100;
    snd-msg 'Valid record not found.';
  else;
    snd-msg 'Unknown error.';
  endif;

  exec sql
    fetch from tcpctld into :cfgtbl.ctld,
                            :cfgtbl.linktype,
                            :cfgtbl.lclintneta,
                            :cfgtbl.rmtintneta,
                            :cfgtbl.rmtcpname ;
enddo;

exec sql
  close tcpctld;

*inlr = *on;
return;


dcl-proc RemoteCommand ; 
  dcl-pi *n ; 
    rmtsys char(15) const; // Remote system to connect
    org_ctlnm char(10) const; // CTLD at remote system need to be modified
  end-pi;
  dcl-s usrvar char(10) inz('IBMECS');
  dcl-s pwdvar char(15) inz('IBMECSUSR');
  dcl-s cmdstr varchar(512) inz;
  dcl-s Incmdstr varchar(512) inz;
  
  if rmtsys = org_sysnm ;
    // Remove remote Host table entries
    // Required : new server ip address
    Incmdstr = '''RMVTCPHTE INTNETADR(''' + %trim(new_ip) + ''')''';
    cmdstr = 'RUNRMTCMD CMD(' + %trim(Incmdstr) + ') ' + 
                'RMTLOCNAME(' + %trim(rmtsys) + ' *IP) ' +
                'RMTUSER(' + %trim(usrvar) + ') ' + 
                'RMTPWD(' + %trim(pwdvar) + ')' ;
    snd-msg Incmdstr ;
    // returnCode = syscmd(cmdstr);
    // If ReturnCode <> 0;
    //   snd-msg 'Command   : ' + cmdstr ;
    //   snd-msg 'returnCode: ' + %char(returnCode) ;
    //   *inlr = *on ;
    //   return ;
    // endif; 

    // Vary off new ctld
    // Required : new ctld name
    Incmdstr = '''VRYCFG CFGOBJ(' + %trim(new_ctlnm) + 
             ') CFGTYPE(*CTL) STATUS(*OFF) FRCVRYOFF(*YES)''' ;
    cmdstr = 'RUNRMTCMD CMD(' + %trim(Incmdstr) + ') ' + 
             'RMTLOCNAME(' + %trim(rmtsys) + ' *IP) ' + 
             'RMTUSER(' + %trim(usrvar) + ') ' + 
             'RMTPWD(' + %trim(pwdvar) + ')' ;
    snd-msg Incmdstr ;
    // snd-msg cmdstr ;
    // returnCode = syscmd(cmdstr);
    // If ReturnCode <> 0;
    //   snd-msg 'Command   : ' + cmdstr ;
    //   snd-msg 'returnCode: ' + %char(returnCode) ;
    //   *inlr = *on ;
    //   return ;
    // endif; 

    // delete new ctld
    // Required : new ctld name 
    Incmdstr = '''DLTCTLD CTLD(' + %trim(new_ctlnm) + ')''' ; 
    cmdstr = 'RUNRMTCMD CMD(' + %trim(Incmdstr) + ') ' + 
           'RMTLOCNAME(' + %trim(rmtsys) + ' *IP) ' + 
           'RMTUSER(' + %trim(usrvar) + ') ' + 
           'RMTPWD(' + %trim(pwdvar) + ')' ;
    snd-msg Incmdstr ;
    // snd-msg cmdstr ;
    // returnCode = syscmd(cmdstr);
    // If ReturnCode <> 0;
    //   snd-msg 'Command   : ' + cmdstr ;
    //   snd-msg 'returnCode: ' + %char(returnCode) ;
    //   *inlr = *on ;
    //   return ;
    // endif;
  endif;
  
  // Remove remote Host table entries
  // Requirements : 原機 IP 位址 ( org_ip )
  Incmdstr = '''RMVTCPHTE INTNETADR(''' + %trim(org_ip) + ''')''';
  cmdstr = 'RUNRMTCMD CMD(' + %trim(Incmdstr) + ') ' + 
              'RMTLOCNAME(' + %trim(rmtsys) + ' *IP) ' +
              'RMTUSER(' + %trim(usrvar) + ') ' + 
              'RMTPWD(' + %trim(pwdvar) + ')' ;
  snd-msg Incmdstr ;
  // returnCode = syscmd(cmdstr);
  // If ReturnCode <> 0;
  //   snd-msg 'Command   : ' + cmdstr ;
  //   snd-msg 'returnCode: ' + %char(returnCode) ;
  //   *inlr = *on ;
  //   return ;
  // endif; 

  // Add new Host table entries
  // Requirements : 原機 IP 位址 ( new_ip )
  Incmdstr = '''ADDTCPHTE INTNETADR(''' + %trimr(new_ip) + ''')' + 
             ' HOSTNAME((' + %trimr(new_hostnme1) + 
             ')' + '(' + %trimr(new_hostnme2) + '))''';
  cmdstr = 'RUNRMTCMD CMD(' + %trim(Incmdstr) + ') ' + 
           'RMTLOCNAME(' + %trim(rmtsys) + ' *IP) ' + 
           'RMTUSER(' + %trim(usrvar) + ') ' + 
           'RMTPWD(' + %trim(pwdvar) + ')' ;
  snd-msg Incmdstr ;
  // snd-msg cmdstr ;
  // returnCode = syscmd(cmdstr);
  // If ReturnCode <> 0;
  //   snd-msg 'Command   : ' + cmdstr ;
  //   snd-msg 'returnCode: ' + %char(returnCode) ;
  //   *inlr = *on ;
  //   return ;
  // endif;  

  // Vary off original ctld
  // Requirements : CFGOBJ = TCP + 原機主機名稱
  Incmdstr = '''VRYCFG CFGOBJ(' + %trim(org_ctlnm) + 
           ') CFGTYPE(*CTL) STATUS(*OFF) FRCVRYOFF(*YES)''' ;
  cmdstr = 'RUNRMTCMD CMD(' + %trim(Incmdstr) + ') ' + 
           'RMTLOCNAME(' + %trim(rmtsys) + ' *IP) ' + 
           'RMTUSER(' + %trim(usrvar) + ') ' + 
           'RMTPWD(' + %trim(pwdvar) + ')' ;
  snd-msg Incmdstr ;
  // snd-msg cmdstr ;
  // returnCode = syscmd(cmdstr);
  // If ReturnCode <> 0;
  //   snd-msg 'Command   : ' + cmdstr ;
  //   snd-msg 'returnCode: ' + %char(returnCode) ;
  //   *inlr = *on ;
  //   return ;
  // endif; 

  // Vary on original ctld 
  Incmdstr = '''VRYCFG CFGOBJ(' + %trim(org_ctlnm) + 
           ') CFGTYPE(*CTL) STATUS(*ON)''' ;
  cmdstr = 'RUNRMTCMD CMD(' + %trim(Incmdstr) + ') ' + 
         'RMTLOCNAME(' + %trim(rmtsys) + ' *IP) ' + 
         'RMTUSER(' + %trim(usrvar) + ') ' + 
         'RMTPWD(' + %trim(pwdvar) + ')' ;
  snd-msg Incmdstr ;
  // snd-msg cmdstr ;
    // returnCode = syscmd(cmdstr);
    // If ReturnCode <> 0;
    //   snd-msg 'Command   : ' + cmdstr ;
    //   snd-msg 'returnCode: ' + %char(returnCode) ;
    //   *inlr = *on ;
    //   return ;
    // endif;
end-proc;

dcl-proc ProcessCommand;
  dcl-pi ProcessCommand;
    inCommand char(1000) const; 
  end-pi;

  dcl-s localStartPos int(10);
  dcl-s localEndPos int(10);
  dcl-s localLength int(10);

  dcl-s parsedCommand char(6000);

  parsedCommand = inCommand;
  clear cfgtbl;

  if %scan('CRTCTLAPPC' : %trim(parsedCommand)) = 1;
    // Extract CTLD value
    localStartPos = %scan('CTLD(' : parsedCommand);
    if localStartPos > 0;
      localStartPos = localStartPos + %len('CTLD(');
      localEndPos = %scan(')' : parsedCommand : localStartPos);
      if localEndPos > localStartPos;
        localLength = localEndPos - localStartPos;
        cfgtbl.ctld = %subst(parsedCommand : localStartPos : localLength);
      endif;
    endif;

    // Extract LINKTYPE value
    localStartPos = %scan('LINKTYPE(' : parsedCommand);
    if localStartPos > 0;
      localStartPos = localStartPos + %len('LINKTYPE(');
      localEndPos = %scan(')' : parsedCommand : localStartPos);
      if localEndPos > localStartPos;
        localLength = localEndPos - localStartPos;
        cfgtbl.linktype = %subst(parsedCommand : localStartPos : localLength);
      endif;
    endif;

    // Extract RMTINTNETA value
    localStartPos = %scan('RMTINTNETA(' : parsedCommand);
    if localStartPos > 0;
      localStartPos = localStartPos + %len('RMTINTNETA(');
      localEndPos = %scan(')' : parsedCommand : localStartPos);
      if localEndPos > localStartPos;
        localLength = localEndPos - localStartPos;
        cfgtbl.rmtintneta = %subst(parsedCommand : localStartPos : localLength);
      endif;
    endif;

    // Extract LCLINTNETA value
    localStartPos = %scan('LCLINTNETA(' : parsedCommand);
    if localStartPos > 0;
      localStartPos = localStartPos + %len('LCLINTNETA(');
      localEndPos = %scan(')' : parsedCommand : localStartPos);
      if localEndPos > localStartPos;
        localLength = localEndPos - localStartPos;
        cfgtbl.lclintneta = %subst(parsedCommand : localStartPos : localLength);
      endif;
    endif;

    // Extract RMTCPNAME value
    localStartPos = %scan('RMTCPNAME(' : parsedCommand);
    if localStartPos > 0;
      localStartPos = localStartPos + %len('RMTCPNAME(');
      localEndPos = %scan(')' : parsedCommand : localStartPos);
      if localEndPos > localStartPos;
        localLength = localEndPos - localStartPos;
        cfgtbl.rmtcpname = %subst(parsedCommand : localStartPos : localLength);
      endif;
    endif;
    if %trim(cfgtbl.linktype) = '*HPRIP' and
         %trim(cfgtbl.rmtintneta) <> '' and
         %trim(cfgtbl.lclintneta) <> '';

      exec sql
            INSERT INTO qtemp.cfgtbl (CTLD, LINKTYPE, RMTINTNETA, LCLINTNETA, RMTCPNAME)
            VALUES (:cfgtbl.ctld, :cfgtbl.linktype, :cfgtbl.rmtintneta, :cfgtbl.lclintneta, :cfgtbl.rmtcpname);
    endif;
  endif;
end-proc;