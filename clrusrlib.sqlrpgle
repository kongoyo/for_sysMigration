**FREE
Ctl-Opt Main(CLRUSRLIB) dftactgrp(*no);

Dcl-Proc CLRUSRLIB;
    Dcl-Pi *N;
        exe_schema char(10) const;
    End-Pi;
    dcl-pr syscmd int(10) ExtProc('system');
        *n Pointer Value Options(*String);
    end-pr;
    dcl-ds liblst qualified;
        objname varchar(10);
        // objtype varchar(8);
    end-ds;
    dcl-ds objlst qualified;
        objname varchar(10);
        // objtype varchar(8);
    end-ds;
    dcl-s stmt varchar(512);
    dcl-s cur_sysnm char(8);
    dcl-s returnCode int(3);
    dcl-s cmdstr char(500) inz('');
    dcl-s returnVal int(3);

// 取得現行主機名稱
    exec sql values current server into :cur_sysnm;

    clear stmt;
    stmt = 'select ' +
           'coalesce(objname, '''') as objname ' +
           'from table (qsys2.object_statistics(' +
           'object_schema => ''' + %trim(%upper(exe_schema)) + ''', objtypelist => ''*LIB''' +
           '))';
    exec sql prepare preliblst from :stmt;
    exec sql declare liblst cursor for preliblst;
    exec sql open liblst;
    exec sql fetch from liblst into :liblst.objname;

    snd-msg '------------------------------';
    snd-msg '  Current SysName : ' + %trim(cur_sysnm);
    snd-msg '------------------------------';

    dow sqlcod = 0;
        if sqlcod = 0;
            // returnVal = %scan('DDSC' : liblst.objname : 1);
            // snd-msg %trim(liblst.objname) + ' : ' + %char(returnVal);
            if liblst.objname <> '#COBLIB' and
               liblst.objname <> '#LIBRARY' and
               liblst.objname <> '#RPGLIB' and
               %scan('Q' : liblst.objname : 1) <> 1 and
               liblst.objname <> 'SYSIBM' and
               liblst.objname <> 'SYSIBMADM' and
               liblst.objname <> 'SYSPROC' and
               liblst.objname <> 'SYSTOOLS' and
               %scan('DDSC' : liblst.objname : 1) <> 1 and
               %scan('RMT' : liblst.objname : 1) <> 1 and
               %scan('HOYA' : liblst.objname : 1) <> 1 and
               %scan('PMEDH' : liblst.objname : 1) <> 1;

                // Process Library
                snd-msg 'Library Name: ' + liblst.objname ;
                snd-msg '------------------------------';
    
                clear stmt;
                stmt = 'select ' +
                   'coalesce(objname, '''') as objname ' +
                   'from table (qsys2.object_statistics(' +
                   'object_schema => ''' + %trim(liblst.objname) + ''', objtypelist => ''*JRN''' +
                   '))';
                exec sql prepare preobjlst from :stmt;
                exec sql declare objlst cursor for preobjlst;
                exec sql open objlst;
                exec sql fetch from objlst into :objlst.objname;

                dow sqlcod = 0;
                    if sqlcod = 0;
                    // Process Journals & receivers
                        snd-msg '  Journal Name: ' + objlst.objname ;
                        clear cmdstr;
                        cmdstr = '  ENDJRNPF FILE(*ALL) ' +
                             'JRN(' + %trim(liblst.objname) + '/' + %trim(objlst.objname) + ')';
                        snd-msg %trimr(cmdstr);
                    // returnCode = syscmd(cmdstr);
                    endif;
                    exec sql fetch from objlst into :objlst.objname;
                enddo;
                exec sql close objlst;
  
                // Process Clear Library
                clear cmdstr;
                cmdstr = '  CLEARLIB LIB(' + %trim(liblst.objname) + ')';
                snd-msg %trimr(cmdstr);
                // returnCode = syscmd(cmdstr);
            endif;
        endif;
        exec sql fetch from liblst into :liblst.objname;
    enddo;
    exec sql close liblst;
End-Proc;