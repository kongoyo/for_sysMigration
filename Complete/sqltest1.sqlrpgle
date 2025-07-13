**free
ctl-opt option(*srcstmt) dftactgrp(*no);
dcl-s objlongschema char(10);
dcl-s objname char(10);
dcl-s objtype char(7);
dcl-s stmt char(1500);
dcl-s oausr char(10);
//
objlongschema = 'DDSCINFO';
objname = 'OBJAUT';
objtype = '*FILE';
//
stmt = 'select oausr from ddscinfo.objaut ' +
            'where oalib = ? ' +
            'and oaname = ? ' +
            'and oatype = ?';
exec sql prepare preautcur from :stmt;
exec sql declare autcur cursor for preautcur;
exec sql open autcur using :objlongschema, :objname, :objtype;
exec sql fetch next from autcur into :oausr;
dow sqlcod = 0;
    if sqlcod = 0;
        snd-msg oausr;
        exec sql fetch next from autcur into :oausr;
    endif;      
enddo;
exec sql close autcur;
//
*inlr = *on;
return;
