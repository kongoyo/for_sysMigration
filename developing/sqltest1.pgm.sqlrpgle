**free
ctl-opt option(*srcstmt) dftactgrp(*no) ;

dcl-ds exsusrvol extname('DDSCINFO/EXSUSRVOL') qualified end-ds;
dcl-pr syscmd int(10) ExtProc('system');
    *n Pointer Value Options(*String);
end-pr;
dcl-s cmdstr varchar(512);
dcl-s returnCode int(5);
dcl-s stmt varchar(512);
  // read file
stmt = 'select objname, save_volume from ddscinfo.exsusrvol order by save_volume';
exec sql prepare preworkfil from :stmt;
exec sql declare workfil cursor for preworkfil;
exec sql open workfil;
exec sql fetch next from workfil into :exsusrvol;
dow sqlcod = 0;      
    snd-msg 'User: ' + %trim(exsusrvol.objname);
    snd-msg 'Volume: ' + %trim(exsusrvol.savvol);
    exec sql fetch next from workfil into :exsusrvol;
enddo;
exec sql close workfil;

*inlr = *on;
return;