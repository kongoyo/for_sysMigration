**FREE
ctl-opt option(*srcstmt) dftactgrp(*no);
dcl-pi *n;
    objschema char(10);
end-pi;
dcl-pr syscmd int(10) ExtProc('system');
    *n Pointer Value Options(*String);
end-pr;
dcl-ds libnm qualified;
    objname char(10);
end-ds;
dcl-ds objnm qualified;
    objlib char(10);
    objnm char(10);
    objtype char(7);
end-ds;
dcl-s cmdstr char(800);
dcl-s returnCode int(5);
dcl-s stmt char(1500);
dcl-s tot_count packed(5:0);
dcl-s isFirst char(3) inz('on');
//
objschema = %upper(%trim(objschema));
exec sql set option commit = *none;
clear cmdstr;
cmdstr = 'DLTOBJ OBJ(DDSCINFO/OBJAUT) OBJTYPE(*FILE)';
returnCode = syscmd(cmdstr);
//
stmt = 'select objname ' +
        'from table(qsys2.object_statistics( ' +
        ' object_schema => ? , ' +
        ' objtypelist => ''*LIB'' ' +
        '))';
exec sql prepare prelst from :stmt;
exec sql declare lst cursor for prelst;
exec sql open lst using :objschema;
exec sql fetch next from lst into :libnm;
dow sqlcod = 0;
    if sqlcod = 0;
        //
        clear stmt;
        stmt = 'select objlongschema, objname, objtype ' +
        'from table(qsys2.object_statistics( ' +
        ' object_schema => ? , ' +
        ' objtypelist => ''*ALL'' ' +
        '))';
        exec sql prepare preobjlst from :stmt;
        exec sql declare objlst cursor for preobjlst;
        exec sql open objlst using :libnm.objname;
        exec sql fetch next from objlst into :objnm;
        dow sqlcod = 0;
            if sqlcod = 0;
                tot_count += 1;
                ///
                clear cmdstr;
                cmdstr = 'DSPOBJAUT OBJ(' + %trim(objnm.objlib) + 
                        '/' + %trim(objnm.objnm) + 
                        ') OBJTYPE(' + %trim(objnm.objtype) + 
                        ') OUTPUT(*OUTFILE) OUTFILE(DDSCINFO/OBJAUT) ' +
                        'OUTMBR(*FIRST *ADD)';
                // snd-msg 'Command: ' + %trim(cmdstr);
                returnCode = syscmd(cmdstr);
                if %trim(isFirst) = 'on';
                    clear cmdstr;
                    cmdstr = 'CHGPF FILE(DDSCINFO/OBJAUT) SIZE(*NOMAX)';
                    returnCode = syscmd(cmdstr);
                    isFirst = 'off';
                endif;
                ///
                exec sql fetch next from objlst into :objnm;
            endif;
        enddo;
        exec sql close objlst;
        //
        exec sql fetch next from lst into :libnm;
    endif;
enddo;
exec sql close lst;

snd-msg 'tot_count: ' + %trim(%char(tot_count));

*inlr = *on;
return;
