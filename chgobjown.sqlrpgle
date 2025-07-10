**free
ctl-opt Main(chgobjown) option(*srcstmt) dftactgrp(*no);
dcl-proc chgobjown;
    dcl-s stmt varchar(512);
    dcl-s cmdstr varchar(512);
    dcl-ds objlst qualified;
        objname varchar(10);
        objtype varchar(7);
    end-ds;
    stmt = 'select objname, objtype from table(qsys2.object_statistics(' +
            ' object_schema => ''ALFRED'',' +
            ' objtypelist => ''*ALL''))' ;
    exec sql prepare preobjlst from :stmt;
    exec sql declare objlst cursor for preobjlst;
    exec sql open objlst;
    exec sql fetch from objlst into :objlst.objname, :objlst.objtype;
    dow sqlcod = 0;
        if sqlcod = 0;
            cmdstr = 'CHGOBJOWN OBJ(ALFRED/' + %trim(objlst.objname) +
                 ') OBJTYPE(' + %trim(objlst.objtype) +
                 ') NEWOWN(IBMECS)' ;
            exec sql call qsys2.qcmdexc(:cmdstr);
            if sqlcod <> 0;
                snd-msg 'Command Error !';
            endif;
        endif;
        exec sql fetch from objlst into :objlst.objname, :objlst.objtype;
    enddo;
    exec sql close objlst;  
    *inlr = *on;
    return;
end-proc;
