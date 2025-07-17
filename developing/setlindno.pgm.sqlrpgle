**free
//
// 停止IP位址可能導致斷線，請使用HMC Console再執行
// 配合回復作業，將IP及LIND autostart 改為 *NO
// 查詢qsys2.netstat_interface_info，取得非127.0.0.1(IPv4)和::1(IPv6)的IP、LIND清單
// 組合指令 ENDTCPIFC、VRYCFG(Vary off LIND)、CHGLINETH、VRYCFG(Vary on LIND)、STRTCPIFC
// 
ctl-opt option(*srcstmt) dftactgrp(*no) ;

dcl-ds nsinter qualified;
  internet_address varchar(45);
  autostart varchar(3);
  line_description varchar(10);
end-ds ;

dcl-pr syscmd int(10) ExtProc('system');
  *n Pointer Value Options(*String);
end-pr;

dcl-s cmdstr varchar(256) inz;
dcl-s returnCode int(5) inz;

// declare cursor
exec sql 
  declare nsinter cursor for
    Select internet_address,
         autostart, line_description
      From qsys2.netstat_interface_info
      where internet_address <> '127.0.0.1' and internet_address <>  '::1';
//
exec sql 
  open nsinter;
//
exec sql
  fetch next from nsinter into  :nsinter.internet_address,
                                :nsinter.autostart,
                                :nsinter.line_description ;

dow sqlcod = 0;
  snd-msg '===== Record Begin =====';    
  if sqlcod = 0;
    //
    // End TCP/IP Interface
    // command sample : ENDTCPIFC INTNETADR('XXX.XXX.XXX.XXX')
    cmdstr = 'ENDTCPIFC INTNETADR(' + %trim(nsinter.internet_address) + ')' ;
    snd-msg 'ENDTCPIFC Cmdstr: ' + cmdstr ;
    //
    // Vary Configuration
    // command sample : VRYCFG CFGOBJ(XXXX) CFGTYPE(*LIN) STATUS(*OFF)
    cmdstr = 'VRYCFG CFGOBJ(' + %trim(nsinter.line_description) + 
             ') CFGTYPE(*LIN) STATUS(*OFF)' ;
    snd-msg 'Vary Off Cmdstr: ' + cmdstr ;
    //
    // Change TCP/IP Interface
    // command sample : CHGTCPIFC INTNETADR('XXX.XXX.XXX.XXX') AUTOSTART(*NO)
    cmdstr = 'CHGTCPIFC INTNETADR(' + %trim(nsinter.internet_address) + 
             ') AUTOSTART(*NO)' ;
    snd-msg 'CHGTCPIFC Cmdstr: ' + cmdstr ;
    // 
    // Vary Configuration
    // command sample : VRYCFG CFGOBJ(XXXX) CFGTYPE(*LIN) STATUS(*ON)
    cmdstr = 'VRYCFG CFGOBJ(' + %trim(nsinter.line_description) + 
             ') CFGTYPE(*LIN) STATUS(*ON)' ;
    snd-msg 'Vary On Cmdstr: ' + cmdstr ;
    //
    // Start TCP/IP Interface
    // command sample : STRTCPIFC INTNETADR('XXX.XXX.XXX.XXX')
    cmdstr = 'STRTCPIFC INTNETADR(' + %trim(nsinter.internet_address) + ')' ;
    snd-msg 'STRTCPIFC Cmdstr: ' + cmdstr ;
  else;
    snd-msg 'Config needs to be changed was not found.' ;
  endif;
  //
  snd-msg '===== Record End =====';    
  //
  exec sql
    fetch next from nsinter into    :nsinter.internet_address,
                                  :nsinter.autostart,
                                  :nsinter.line_description ;
enddo;
//
exec sql
  close nsinter;

*inlr = *on;
return;
