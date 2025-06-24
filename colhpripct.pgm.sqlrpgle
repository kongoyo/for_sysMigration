**free

// 檔案:
// 1. cfgsrc : retrieve configuration source
// 2. cfgtbl : write ctld name, linktype = *HPRIP, remote ip_addr, local ip_addr, remote cp_name 

// 功能:
// 1. 抓取本機 APPC controller 資訊
// 2. 將 APPC controller 資訊寫入檔案
// 3. 讀檔組成遠端指令
// 4. 遠端主機: 用原機 主機名稱 
// 5. 遠端主機: 用原機 IP 搜尋 Host Table，並刪除之
// 6. 遠端主機: 用新機 IP 搜尋 Host Table，並刪除之
// 7. 遠端主機: 用新 IP 建立 1 筆新的 Host table entry
// 7. 執行 aping、sndnetf、cpyf from ddmf 等測試

ctl-opt option(*srcstmt) dftactgrp(*no) ; // Add debug options

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

dcl-s currentParsedLine char(120);
dcl-s pendingCommand char(1000) inz;
dcl-s commandEndsHereThisLine ind inz(*off);
dcl-s startPos int(10);
dcl-s isNewCommandStart ind;

// 定義組合並執行指令區塊
dcl-pr syscmd int(10) ExtProc('system');
  *n Pointer Value Options(*String);
end-pr;
dcl-s cmdstr varchar(512) inz;
dcl-s returnCode int(3) inz;
dcl-s curr_sysnm char(8) inz;
dcl-s N_pos int(5) inz;
dcl-s orig_sysnm char(8) inz;
dcl-s orig_ip varchar(15) inz;
dcl-s new_sysnm char(8) inz;
dcl-s new_ip varchar(15) inz;
dcl-s usrvar char(10) inz('IBMECS');
dcl-s pwdvar char(10) inz('IBMECSUSR'); 


// 取得新機主機名稱
exec sql 
  values current server into :curr_sysnm;

// 取得原機主機名稱
n_pos = %scan('3' : %UPPER(curr_sysnm)) ;
if n_pos > 0;
  orig_sysnm = %subst( curr_sysnm : 1 : n_pos -1 ) ;
  // snd-msg orig_sysnm ;   
endif;

// 從 Host table 取得原主機 IP address
exec sql 
  select internet
  into   :orig_ip 
  from qusrsys.qatochost 
  where hostnme1 like '%' concat trim(:orig_sysnm) concat '%' or 
        hostnme2 like '%' concat trim(:orig_sysnm) concat '%' 
  fetch first 1 rows only;

// 從 Host table 取得新主機 IP address
exec sql 
  select internet 
  into   :new_ip
  from qusrsys.qatochost
  where trim(hostnme1) like '%CLARK73' or 
        trim(hostnme2) like '%CLARK73' 
  fetch first 1 rows only;
snd-msg '--------------------------------------';
snd-msg '   New System Name     : ' + curr_sysnm ;
snd-msg '   Original System Name: ' + orig_sysnm ;
snd-msg '   New      IP address : ' + new_ip ;
snd-msg '   Original IP address : ' + orig_ip ;
snd-msg '--------------------------------------';//

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
  // 處理 pendingCommand
  if sqlcod = 100; 
    if %len(%trim(pendingCommand)) > 0;
      ProcessCommand(pendingCommand);
      clear pendingCommand;
    endif;
  elseif sqlcod <> 0;
    snd-msg 'SQL error with sqlcod : ' + %char(sqlcod);
  endif;
  // 處理 pendingCommand

  // 處理讀取到的資料
  if sqlcod = 0;
    // 查詢 CRTCTLAPPC ，查到就代表是新指令
    currentParsedLine = %trimr(cfgsrc.srcdta); 
    isNewCommandStart = *off;
    if %scan('CRTCTLAPPC' : %trim(cfgsrc.srcdta)) = 1;
      isNewCommandStart = *on;
    endif;
    // 指令結尾指示器 *on
    commandEndsHereThisLine = *on;
    // 查詢 + 號，如果查到代表非指令結尾，指示器 *off 
    If %scan('+':currentParsedLine) > 1;
      startPos = %scan('+':currentParsedLine);
      currentParsedLine = %subst(currentParsedLine : 1 : startPos); 
      commandEndsHereThisLine = *off; 
    else;
    endif;
    // ProcessCommand Procedure
    // 如果新指令為 true 且 pendingCommand 長度大於 0，立即處理 pendingCommand
    if isNewCommandStart and %len(%trim(pendingCommand)) > 0;
      ProcessCommand(pendingCommand); 
      clear pendingCommand;
      // if %subst(cfgtbl.ctld : 1 : 3) = 'TCP' and 
      //    cfgtbl.linktype = '*HPRIP' and 
      //    cfgtbl.rmtintneta <> '' and 
      //    cfgtbl.lclintneta <> '' ;
      //   snd-msg '--------------------------------------';
      //   snd-msg 'Controller Name : ' + cfgtbl.ctld ;
      //   snd-msg 'Linktype        : ' + cfgtbl.linktype ;
      //   snd-msg 'remote ip_addr  : ' + cfgtbl.rmtintneta ;
      //   snd-msg 'local  ip_addr  : ' + cfgtbl.lclintneta ;
      //   snd-msg 'remote cp_name  : ' + cfgtbl.rmtcpname ;
      //   snd-msg '--------------------------------------';
      //   RemoteCommand('TCP' + %trim(orig_sysnm) : cfgtbl.rmtintneta : 'IBMECS' : 'IBMECSUSR') ;
      // endif;
    // 如果新指令為 false 且 pendingCommand 長度大於 0，組合 pendingCommand 和 currentPasedLine 
    elseif %len(%trim(pendingCommand)) > 0;
      pendingCommand = %trimr(pendingCommand) + ' ' + %trim(currentParsedLine);
    else;
      pendingCommand = %trim(currentParsedLine);
    endif;
    // Clear pendingCommand 後方多餘字串
    if %len(%trimr(pendingCommand)) > %len(pendingCommand);
      pendingCommand = %subst(pendingCommand:1:%len(pendingCommand));
    else;
    endif;
    // 如果指令結尾為 true 且 pendingCommand 長度大於 0 ，立即處理 pendingCommand
    if commandEndsHereThisLine and %len(%trim(pendingCommand)) > 0;
      ProcessCommand(pendingCommand); 
      clear pendingCommand;
      // if %subst(cfgtbl.ctld : 1 : 3) = 'TCP' and 
      //    cfgtbl.linktype = '*HPRIP' and 
      //    cfgtbl.rmtintneta <> '' and 
      //    cfgtbl.lclintneta <> '' ;
      //   snd-msg '--------------------------------------';
      //   snd-msg 'Controller Name : ' + cfgtbl.ctld ;
      //   snd-msg 'Linktype        : ' + cfgtbl.linktype ;
      //   snd-msg 'remote ip_addr  : ' + cfgtbl.rmtintneta ;
      //   snd-msg 'local  ip_addr  : ' + cfgtbl.lclintneta ;
      //   snd-msg 'remote cp_name  : ' + cfgtbl.rmtcpname ;
      //   snd-msg '--------------------------------------';
      //   RemoteCommand('TCP' + %trim(orig_sysnm) : cfgtbl.rmtintneta : 'IBMECS' : 'IBMECSUSR') ;
      // endif;
    else;
    endif;
    // ProcessCommand Procedure

    exec sql
      fetch next from cfgsrc into :cfgsrc.srcseq, 
                                  :cfgsrc.srcdat, 
                                  :cfgsrc.srcdta ;
  endif; 
  // 處理讀取到的資料
enddo; 

exec sql
  close cfgsrc;

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
    snd-msg 'Execute-RemoteCmd : ' + cfgtbl.ctld;
    RemoteCommand(cfgtbl.ctld:cfgtbl.rmtcpname:usrvar:pwdvar);
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

// 組成指令區塊
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
      // if sqlcod <> 0;
      //   snd-msg ('SQL INSERT Error! SQLCOD: ' + %char(sqlcod));
      // else;
      //   snd-msg ('SQL INSERT Successful.');
      // endif;
    endif;
  endif;
end-proc; 
// 組成指令區塊

// 執行遠端指令區塊
dcl-proc RemoteCommand ; 
  dcl-pi *n ; 
    ctlvar char(10) const; // TCP + orig_sysnm
    rmtsys char(15) const; // Remote system to connect
    usrvar char(10) const; // Remote User ID
    pwdvar char(10) const; // Remote User PWD
  end-pi;
  dcl-s cmdstr varchar(512) inz;
  dcl-s Incmdstr varchar(512) inz;

  // 本週要移轉主機 -> 要修改所有 controller 的 lclintneta
  // 清單中 TCP 開頭的 CTLD -> 刪除 Host table 用新 IP 重新建立、vary off ctld、vary on ctld

  // Remove remote Host table entries
  Incmdstr = '''RMVTCPHTE INTNETADR(''' + %trim(orig_ip) + ''')''';
  cmdstr = 'RUNRMTCMD CMD(' + %trim(Incmdstr) + ') ' + 
              'RMTLOCNAME(' + %trim(rmtsys) + ' *IP) ' +
              'RMTUSER(' + %trim(usrvar) + ') ' + 
              'RMTPWD(' + %trim(pwdvar) + ')' ;
  snd-msg cmdstr ;
  // returnCode = syscmd(cmdstr);
  // If ReturnCode <> 0;
  //   snd-msg 'Command   : ' + cmdstr ;
  //   snd-msg 'returnCode: ' + %char(returnCode) ;
  //   *inlr = *on ;
  //   return ;
  // endif; 

  // Add new Host table entries
  Incmdstr = '''ADDTCPHTE INTNETADR(''' + %trim(new_ip) + ''')''';
  cmdstr = 'RUNRMTCMD CMD(' + %trim(Incmdstr) + ') ' + 
           'RMTLOCNAME(' + %trim(rmtsys) + ' *IP) ' + 
           'RMTUSER(' + %trim(usrvar) + ') ' + 
           'RMTPWD(' + %trim(pwdvar) + ')' ;
  snd-msg cmdstr ;
  // returnCode = syscmd(cmdstr);
  // If ReturnCode <> 0;
  //   snd-msg 'Command   : ' + cmdstr ;
  //   snd-msg 'returnCode: ' + %char(returnCode) ;
  //   *inlr = *on ;
  //   return ;
  // endif;  

  // Vary off remote ctld
  Incmdstr = '''VRYCFG CFGOBJ(' + %trim(ctlvar) + 
           ') CFGTYPE(*CTL) STATUS(*OFF) FRCVRYOFF(*YES)''' ;
  cmdstr = 'RUNRMTCMD CMD(' + %trim(Incmdstr) + ') ' + 
           'RMTLOCNAME(' + %trim(rmtsys) + ' *IP) ' + 
           'RMTUSER(' + %trim(usrvar) + ') ' + 
           'RMTPWD(' + %trim(pwdvar) + ')' ;
  snd-msg cmdstr ;
  // returnCode = syscmd(cmdstr);
  // If ReturnCode <> 0;
  //   snd-msg 'Command   : ' + cmdstr ;
  //   snd-msg 'returnCode: ' + %char(returnCode) ;
  //   *inlr = *on ;
  //   return ;
  // endif; 

  // Vary on remote ctld 
  Incmdstr = '''VRYCFG CFGOBJ(' + %trim(ctlvar) + 
           ') CFGTYPE(*CTL) STATUS(*ON)''' ;
  if %subst(cfgtbl.ctld : 1 : 3) = 'TCP' ;
  cmdstr = 'RUNRMTCMD CMD(' + %trim(Incmdstr) + ') ' + 
           'RMTLOCNAME(' + %trim(rmtsys) + ' *IP) ' + 
           'RMTUSER(' + %trim(usrvar) + ') ' + 
           'RMTPWD(' + %trim(pwdvar) + ')' ;
    snd-msg cmdstr ;
    // returnCode = syscmd(cmdstr);
    // If ReturnCode <> 0;
    //   snd-msg 'Command   : ' + cmdstr ;
    //   snd-msg 'returnCode: ' + %char(returnCode) ;
    //   *inlr = *on ;
    //   return ;
    // endif;
  endif; 
  // 2. Change EE controller remote ip_addr Start

  end-proc;
// 執行遠端指令區塊