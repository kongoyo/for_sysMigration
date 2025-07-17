**FREE
Ctl-Opt Main(CLRUSRLIB) dftactgrp(*no);
// *******************************************************************
// Program function  : Clear User Library.                                
// Program Name      : CLRUSRLIB.sqlrpgle
// Programmer Name   : STEVE                                       
// Modification Date : 2025/07/07                                   
// *******************************************************************
// Usage             : CALL *LIBL/CLRUSRLIB ('*ALLUSR')
//    Or             : CALL *LIBL/CLRUSRLIB ('DDSCINFO')
// *******************************************************************
// Parameters        : --- user-input parameter ---
//                     exe_schema char(10)  - The library name to clear.
//                                          option: *ALL、*ALLUSR、specific or generic name can be used. 
//
//                     --- log format ---
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
//                     --- sql query ---
//                     stmt varchar(512)    - sql query statement
//                     rplylst_seqnum int(10)  - reply sequence number
//                     rplylst_msgid varchar(7) - reply message id
//                     rplylst_reply varchar(1) - reply message reply
// *******************************************************************
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
    dcl-s returnCode int(3);
    dcl-s cmdstr char(500) inz('');
    dcl-s rplylst_seqnum int(10);
    dcl-s rplylst_msgid varchar(7);
    dcl-s rplylst_reply varchar(1);

    dcl-s cur_sysnm varchar(10);
    dcl-s ifsfnm char(200);
    dcl-s cur_date date;
    dcl-s cur_time time;
    dcl-s logtxt char(1000);

    exec sql values current server into :cur_sysnm;
    exec sql values(current_date) into :cur_date;
    exec sql values(current_time) into :cur_time;
    ifsfnm = '/home/qsecofr/kgi_log/clrusrlib_' + %trim(%scanrpl('-' : '' : %char(cur_date))) + 
         '_' + %trim(%scanrpl('.' : '' : %char(cur_time))) + '.log';
    clear logtxt;
    exec sql call QSYS2.IFS_WRITE_UTF8(trim(:ifsfnm),
                                  trim(:logtxt),
                                  OVERWRITE => 'REPLACE',
                                  END_OF_LINE => 'NONE');
    logtxt = ' ' + %trim(%char(cur_date)) + 
         ' ' + %trim(%char(cur_time)) + 
         ' ' + %trim(cur_sysnm) + 
         ' ' + 'Clear User Library start.';
    exec sql call QSYS2.IFS_WRITE(trim(:ifsfnm),
                                  trim(:logtxt),
                                  OVERWRITE => 'APPEND',
                                  END_OF_LINE => 'CRLF');
    // snd-msg '------------------------------';
    // snd-msg '  Current SysName : ' + %trim(cur_sysnm);
    // snd-msg '------------------------------';
    logtxt = ' ' + %trim(%char(cur_date)) + 
         ' ' + %trim(%char(cur_time)) + 
         ' ' + %trim(cur_sysnm) + 
         ' ' + '------------------------------';
    exec sql call QSYS2.IFS_WRITE(trim(:ifsfnm),
                                  trim(:logtxt),
                                  OVERWRITE => 'APPEND',
                                  END_OF_LINE => 'CRLF');
    logtxt = ' ' + %trim(%char(cur_date)) + 
         ' ' + %trim(%char(cur_time)) + 
         ' ' + %trim(cur_sysnm) + 
         ' ' + '  Current SysName : ' + %trim(cur_sysnm);
    exec sql call QSYS2.IFS_WRITE(trim(:ifsfnm),
                                  trim(:logtxt),
                                  OVERWRITE => 'APPEND',
                                  END_OF_LINE => 'CRLF');                                  
    logtxt = ' ' + %trim(%char(cur_date)) + 
         ' ' + %trim(%char(cur_time)) + 
         ' ' + %trim(cur_sysnm) + 
         ' ' + '------------------------------';
    exec sql call QSYS2.IFS_WRITE(trim(:ifsfnm),
                                  trim(:logtxt),
                                  OVERWRITE => 'APPEND',
                                  END_OF_LINE => 'CRLF');
    // change job to log msg
    cmdstr = 'CHGJOB LOG(4 00 *MSG) LOGCLPGM(*YES) INQMSGRPY(*SYSRPYL)';
    returnCode = syscmd(cmdstr);
    logtxt = ' ' + %trim(%char(cur_date)) + 
            ' ' + %trim(%char(cur_time)) + 
            ' ' + %trim(cur_sysnm) + 
            ' ' + %trimr(cmdstr);
    exec sql call QSYS2.IFS_WRITE(trim(:ifsfnm),
                                  trim(:logtxt),
                                  OVERWRITE => 'APPEND',
                                  END_OF_LINE => 'CRLF');
    // Check if reply list entry for CPA7025 exists
    exec sql Select coalesce(sequence_number,0) as sequence_number,
                    coalesce(message_id,'') as message_id, 
                    coalesce(message_reply,'') as message_reply
             Into :rplylst_seqnum, :rplylst_msgid, :rplylst_reply
             From qsys2.reply_list_info
             Where message_id In ('CPA7025');
    // If it doesn't exist, add it to auto-reply with 'I' (Ignore)
    if rplylst_seqnum = 0;
        clear cmdstr;
        cmdstr = 'ADDRPYLE SEQNBR(9898) MSGID(CPA7025) RPY(I)';
        exec sql call qsys2.qcmdexc(:cmdstr);
        logtxt = ' ' + %trim(%char(cur_date)) +
                 ' ' + %trim(%char(cur_time)) +
                 ' ' + %trim(cur_sysnm) +
                 ' ' + %trimr(cmdstr);
        exec sql call QSYS2.IFS_WRITE(trim(:ifsfnm),
                                  trim(:logtxt),
                                  OVERWRITE => 'APPEND',
                                  END_OF_LINE => 'CRLF');
    elseif rplylst_seqnum <> 0 and rplylst_reply <> 'I';
        clear cmdstr;
        cmdstr = 'CHGRPYLE SEQNBR(' + %char(rplylst_seqnum) + ') MSGID(*SAME) RPY(I)';
        exec sql call qsys2.qcmdexc(:cmdstr);
        logtxt = ' ' + %trim(%char(cur_date)) +
                 ' ' + %trim(%char(cur_time)) +
                 ' ' + %trim(cur_sysnm) +
                 ' ' + %trimr(cmdstr);
        exec sql call QSYS2.IFS_WRITE(trim(:ifsfnm),
                                  trim(:logtxt),
                                  OVERWRITE => 'APPEND',
                                  END_OF_LINE => 'CRLF');
    else;
    endif;
    // Get Library Name
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
                // snd-msg 'Library Name: ' + liblst.objname ;
                // snd-msg '------------------------------';
                logtxt = ' ' + %trim(%char(cur_date)) + 
                         ' ' + %trim(%char(cur_time)) + 
                         ' ' + %trim(cur_sysnm) + 
                         ' ' + 'Library Name: ' + liblst.objname ;
                exec sql call QSYS2.IFS_WRITE(trim(:ifsfnm),
                                  trim(:logtxt),
                                  OVERWRITE => 'APPEND',
                                  END_OF_LINE => 'CRLF');    
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
                        // snd-msg '  Journal Name: ' + objlst.objname ;
                        logtxt = ' ' + %trim(%char(cur_date)) + 
                                 ' ' + %trim(%char(cur_time)) + 
                                 ' ' + %trim(cur_sysnm) + 
                                 ' ' + '  Journal Name: ' + objlst.objname ;
                        exec sql call QSYS2.IFS_WRITE(trim(:ifsfnm),
                                  trim(:logtxt),
                                  OVERWRITE => 'APPEND',
                                  END_OF_LINE => 'CRLF'); 
                        clear cmdstr;
                        cmdstr = '  ENDJRNPF FILE(*ALL) ' +
                             'JRN(' + %trim(liblst.objname) + '/' + %trim(objlst.objname) + ')';
                        // snd-msg %trimr(cmdstr);
                        logtxt = ' ' + %trim(%char(cur_date)) + 
                                 ' ' + %trim(%char(cur_time)) + 
                                 ' ' + %trim(cur_sysnm) + 
                                 ' ' + %trimr(cmdstr);
                        exec sql call QSYS2.IFS_WRITE(trim(:ifsfnm),
                                  trim(:logtxt),
                                  OVERWRITE => 'APPEND',
                                  END_OF_LINE => 'CRLF'); 
                    // returnCode = syscmd(cmdstr);
                    endif;
                    exec sql fetch from objlst into :objlst.objname;
                enddo;
                exec sql close objlst;
  
                // Process Clear Library
                clear cmdstr;
                cmdstr = '  CLRLIB LIB(' + %trim(liblst.objname) + ')';
                // snd-msg %trimr(cmdstr);
                logtxt = ' ' + %trim(%char(cur_date)) + 
                                 ' ' + %trim(%char(cur_time)) + 
                                 ' ' + %trim(cur_sysnm) + 
                                 ' ' + %trimr(cmdstr);
                exec sql call QSYS2.IFS_WRITE(trim(:ifsfnm),
                                  trim(:logtxt),
                                  OVERWRITE => 'APPEND',
                                  END_OF_LINE => 'CRLF');
                // returnCode = syscmd(cmdstr);
            endif;
        endif;
        exec sql fetch from liblst into :liblst.objname;
    enddo;
    exec sql close liblst;
    if rplylst_seqnum <> 0;
        clear cmdstr;
        cmdstr = 'CHGRPYLE SEQNBR(' + %char(rplylst_seqnum) + ') MSGID(*SAME) RPY(' + %trim(rplylst_reply) + ')';
        exec sql call qsys2.qcmdexc(:cmdstr);
        logtxt = ' ' + %trim(%char(cur_date)) +
                 ' ' + %trim(%char(cur_time)) +
                 ' ' + %trim(cur_sysnm) +
                 ' ' + %trimr(cmdstr);
        exec sql call QSYS2.IFS_WRITE(trim(:ifsfnm),
                                  trim(:logtxt),
                                  OVERWRITE => 'APPEND',
                                  END_OF_LINE => 'CRLF');
    elseif rplylst_seqnum = 0;
        clear cmdstr;
        cmdstr = 'RMVRPYLE SEQNBR(9898)';
        exec sql call qsys2.qcmdexc(:cmdstr);
        logtxt = ' ' + %trim(%char(cur_date)) +
                 ' ' + %trim(%char(cur_time)) +
                 ' ' + %trim(cur_sysnm) +
                 ' ' + %trimr(cmdstr);
        exec sql call QSYS2.IFS_WRITE(trim(:ifsfnm),
                                  trim(:logtxt),
                                  OVERWRITE => 'APPEND',
                                  END_OF_LINE => 'CRLF');
    else;
    endif;
    logtxt = ' ' + %trim(%char(cur_date)) + 
         ' ' + %trim(%char(cur_time)) + 
         ' ' + %trim(cur_sysnm) + 
         ' ' + 'Clear User Library finished.';
    exec sql call QSYS2.IFS_WRITE(trim(:ifsfnm),
                                  trim(:logtxt),
                                  OVERWRITE => 'APPEND',
                                  END_OF_LINE => 'CRLF');
End-Proc;