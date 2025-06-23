**free

ctl-opt option(*srcstmt) dftactgrp(*no) ; // Add debug options

// 定義 config source : 使用 RTVCFGSRC 指令抓取 *CTLD source
dcl-ds cfgsrc qualified;
  srcseq zoned(6);
  srcdat zoned(6);
  srcdta char(120);
end-ds;

// 定義 config table : 將 *CTLD 資訊寫入表格供後續使用

dcl-ds cfgtbl qualified;
  ctld char(10);
  linktype char(10);
  rmtintneta char(15);
  lclintneta char(15);
  rmtcpname char(10);
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
// 定義組合併執行指令區塊

// 定義 CFGSRC no commit，否則檔案會無法I/O
exec sql
  set transaction isolation level no commit ;

// 抓取 config source

exec sql 
  drop table qtemp.cfgsrc if exists;

cmdstr = 'DLTOBJ OBJ(QTEMP/CFGSRC) OBJTYPE(*FILE)';
returnCode = syscmd(cmdstr);
if returnCode <> 0;
  snd-msg '-- DLTOBJ QTEMP/CFGSRC error --';
endif;

cmdstr = 'CRTSRCPF FILE(QTEMP/CFGSRC) IGCDTA(*YES)';
returnCode = syscmd(cmdstr);
if returnCode <> 0;
  snd-msg '-- CRTSRCPF QTEMP/CFGSRC error --';
endif;

cmdstr = 'RTVCFGSRC CFGD(*ALL) CFGTYPE(*CTLD) SRCFILE(QTEMP/CFGSRC) RTVOPT(*OBJ)';
returnCode = syscmd(cmdstr);
if returnCode <> 0;
  snd-msg '-- RTVCFGSRC QTEMP/CFGSRC error --';
endif;

// 抓取 config source
// 拆解 config source

exec sql
  drop table cfgtbl if exists;

exec sql
  create table qtemp.cfgtbl (
    ctld varchar(10),
    linktype varchar(10),
    rmtintneta varchar(15),
    lclintneta varchar(15),
    rmtcpname varchar(10)
   );

exec sql
  declare c1 cursor for
    select srcseq, srcdat, srcdta 
    from qtemp.cfgsrc 
    order by srcseq;

exec sql
  open c1;

exec sql
  fetch next from c1 into :cfgsrc.srcseq, 
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

    // 如果新指令為 true 且 pendingCommand 長度大於 0，立即處理 pendingCommand
    if isNewCommandStart and %len(%trim(pendingCommand)) > 0;
      ProcessCommand(pendingCommand); 
      clear pendingCommand;
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
    else;
    endif;

  exec sql
    fetch next from c1 into :cfgsrc.srcseq, 
                            :cfgsrc.srcdat, 
                            :cfgsrc.srcdta ;
  endif; 
  // 處理讀取到的資料
enddo; 
  
exec sql
   close c1;

// 拆解 config source

// 轉存到 DDSCINFO/CFGTBL

exec sql
   drop table ddscinfo.cfgtbl if exists;

exec sql
   create table ddscinfo.cfgtbl as (
      select ctld, 
             linktype, 
             rmtintneta, 
             lclintneta, 
             rmtcpname 
      from qtemp.cfgtbl
      // 篩選符合特定條件的 CTLD
      where substring(ctld,1,3) = 'TCP'
   ) with data;

// 轉存到 DDSCINFO/CFGTBL

// 組合 RUNRMTCMD 指令

cmdstr = 'QSYS/RUNRMTCMD CMD(';





// 組合 RUNRMTCMD 指令

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
      if sqlcod <> 0;
        snd-msg ('SQL INSERT Error! SQLCOD: ' + %char(sqlcod));
      else;
        snd-msg ('SQL INSERT Successful.');
      endif;
    endif;
  endif;
end-proc; 
// 組成指令區塊