**FREE
ctl-opt option(*srcstmt) actgrp(*caller) ;

// declare user-input variable

dcl-pi *n;
  exelib char(10);  // user-input process object library
  exetype char(8);  // user-input process object type
end-pi;

// ***** Notice *****
// declare data structure
DCL-DS objAutRec EXTNAME('OAAS101N/OBJAUT101') QUALIFIED;
END-DS;

// declare system command string
dcl-pr syscmd int(10) ExtProc('system');
  *n Pointer Value Options(*String);
end-pr;

// Prototype for QCMDEXC API
dcl-pr QCMDCHK extpgm ;
  *n char(500) options(*varsize) const ;
  *n packed(15:5) const ;
end-pr;

dcl-s cmdstr char(500) inz;
dcl-s cmdlen packed(15:5) inz;
dcl-s returnCode int(5) inz;

dcl-s @tbllib varchar(10) inz;
dcl-s @tblname varchar(10) inz;

dcl-s sys_dname varchar(10) inz;
dcl-s sys_oname varchar(10) inz;
dcl-s objtype varchar(7) inz;
dcl-s user_name varchar(10) inz;
dcl-s obj_auth varchar(12) inz;
dcl-s owner varchar(10) inz;
dcl-s auth varchar(10) inz;
dcl-s pgroup varchar(10) inz;
dcl-s auth_mgmt varchar(3) inz;
dcl-s objown varchar(3) inz;
dcl-s objoper varchar(3) inz;
dcl-s objmgt varchar(3) inz;
dcl-s objexist varchar(3) inz;
dcl-s objalter varchar(3) inz;
dcl-s objref varchar(3) inz;
dcl-s dataread varchar(3) inz;
dcl-s dataadd varchar(3) inz;
dcl-s dataupd varchar(3) inz;
dcl-s datadel varchar(3) inz;
dcl-s dataexec varchar(3) inz;

// declare null Ind
dcl-s authNulInd int(5) inz;
dcl-s pgrpNulInd int(5) inz;

// declare cursor
EXEC SQL
    DECLARE objaut CURSOR FOR
        SELECT  oasyst,
                oalib,
                oaname,
                oatype,
                oausr,
                oaobja,
                oaown,
                oagrpn,
                oaopr,
                oaomgt,
                oaread,
                oaadd,
                oaupd,
                oadlt,
                oaamgt,
                oaanam,
                oaexec,
                oaalt,
                oaref
            FROM oaas101n.OBJAUTF02  // Control process range
            WHERE oalib like trim(:exelib) concat '%' and 
                  oaname like trim(:exetype) concat '%' ;

EXEC SQL
    OPEN objaut;

EXEC SQL
    fetch next from objaut into :objAutRec.oasyst,          // System
                                :objAutRec.oalib,           // Library
                                :objAutRec.oaname,          // Object
                                :objAutRec.oatype,          // Object type
                                :objAutRec.oausr,           // User Profile
                                :objAutRec.oaobja,          // User Authority
                                :objAutRec.oaown,           // Object owner
                                :objAutRec.oagrpn,          // Object group
                                :objAutRec.oaopr,
                                :objAutRec.oaomgt,
                                :objAutRec.oaread,
                                :objAutRec.oaadd,
                                :objAutRec.oaupd,
                                :objAutRec.oadlt,
                                :objAutRec.oaamgt,
                                :objAutRec.oaanam,
                                :objAutRec.oaexec,
                                :objAutRec.oaalt,
                                :objAutRec.oaref;

DOW SQLCOD = 0;
  snd-msg '----- Record Begin -----';
  if sqlcod = 0;
    // Print source record
    snd-msg 'Original:';
    snd-msg '1. Sys_lib   : ' + objAutRec.OALIB +
            '   Sys_obj   : ' + objAutRec.OANAME;
    snd-msg '   Sys_type  : ' + objAutRec.OATYPE +
            '   Owner     : ' + objAutRec.OAOWN;
    snd-msg '   Usrprf    : ' + objAutRec.OAUSR;
    snd-msg '   public_Aut: ' + objAutRec.OAOBJA;
    snd-msg '   Group     : ' + objAutRec.OAGRPN;

    // Get current object Info
    exec sql
                select  sys_dname, sys_oname, objtype,
                        authorization_name, object_authority,
                        owner, authorization_list,
                        primary_group, authorization_list_management,
                        object_owner, object_operational,
                        object_management, object_existence,
                        object_alter, object_reference,
                        data_read, data_add, data_update,
                        data_delete, data_execute
                into
                        :sys_dname, 
                        :sys_oname,
                        :objtype,
                        :user_name,
                        :obj_auth,
                        :owner,
                        :auth :authNulInd,
                        :pgroup :pgrpNulInd,
                        :auth_mgmt,
                        :objown,
                        :objoper,
                        :objmgt,
                        :objexist,
                        :objalter,
                        :objref,
                        :dataread,
                        :dataadd,
                        :dataupd,
                        :datadel,
                        :dataexec
                from qsys2.obj_priv
                where system_object_schema = :objAutRec.OALIB and
                        system_object_name = :objAutRec.OANAME and
                        object_type = :objAutRec.OATYPE and
                        ( authorization_name = :objAutRec.OAUSR or
                          primary_group = :objAutRec.OAGRPN ) ;
    // If object exist
    if sqlcod <> 100;
      // Print Current object Info
      // Print source record
      snd-msg 'New:';
      snd-msg '2. Sys_lib   : ' + sys_dname +
              '   Sys_obj   : ' + sys_oname;
      snd-msg '   Sys_type  : ' + objtype +
              '   Owner     : ' + owner;
      snd-msg '   Usrprf    : ' + user_name;
      snd-msg '   public_Aut: ' + obj_auth;
      snd-msg '   Group     : ' + pgroup;

      // object owner will be changed only if owner is not same as OAOWN and owner is QDFTOWN
      if owner <> objAutRec.OAOWN and owner = 'QDFTOWN';
        cmdstr = 'CHGOBJOWN OBJ(' + %trim(objAutRec.OALIB) + '/' +
        %trim(objAutRec.OANAME) + ') OBJTYPE(' + %trim(objAutRec.OATYPE) +
        ') NEWOWN(' + %trim(objAutRec.OAOWN) + ')' ;
        returnCode = syscmd(cmdstr);
        snd-msg 'cmdstr: ' + cmdstr;
        if returnCode <> 0;
          snd-msg 'sqlcod: ' + %char(sqlcod);
          snd-msg 'Change object owner error.';
        endif;
      endif;

      // authority list will be changed only if auth is not same as OAANAM and OAANAM is not *NONE
      if auth <> objAutRec.OAANAM and %subst(objAutRec.OAANAM : 1 : 5) <> '*NONE';
        cmdstr = 'GRTOBJAUT OBJ(' + %trim(objAutRec.OALIB) + '/' +
        %trim(objAutRec.OANAME) + ') OBJTYPE(' + %trim(objAutRec.OATYPE) +
        ') AUTL(' + %trim(objAutRec.OAANAM) + ')' ;
        returnCode = syscmd(cmdstr);
        snd-msg 'cmdstr: ' + cmdstr;
        if returnCode <> 0;
          snd-msg 'sqlcod: ' + %char(sqlcod);
          snd-msg 'Grant AUTL Authority error.';
        endif;
      endif;

      // Check *public/*group/Usrprf and user-defined/non user-defined/*ALL authority
      select;
        // User profile is *Public
        when objAutRec.OAUSR = '*PUBLIC';
          select;
            // *Public authority is not user-defined
            when objAutRec.OAOBJA <> 'USER DEF';
              cmdstr = 'GRTOBJAUT OBJ(' + %trim(objAutRec.OALIB) +
              '/' + %trim(objAutRec.OANAME) + ') OBJTYPE(' + %trim(objAutRec.OATYPE) + ') USER(' +
              %trim(objAutRec.OAUSR) + ') AUT(' + %trim(objAutRec.OAOBJA) + ') REPLACE(*NO)' ;
              returnCode = syscmd(cmdstr);
              snd-msg 'cmdstr: ' + cmdstr;
              if returnCode <> 0;
                snd-msg 'sqlcod: ' + %char(sqlcod);
                snd-msg '--- *Public and not USER DEF error ---';
              endif;
            // *Public authority is *ALL
            when objAutRec.OAOBJA = '*ALL';
              cmdstr = 'GRTOBJAUT OBJ(' + %trim(objAutRec.OALIB) +
              '/' + %trim(objAutRec.OANAME) + ') OBJTYPE(' + %trim(objAutRec.OATYPE) + ') USER(' +
              %trim(objAutRec.OAUSR) + ') AUT(' + %trim(objAutRec.OAOBJA) + ') REPLACE(*NO)' ;
              returnCode = syscmd(cmdstr);
              snd-msg 'cmdstr: ' + cmdstr;
              if returnCode <> 0;
                snd-msg 'sqlcod: ' + %char(sqlcod);
                snd-msg 'cmdstr: ' + cmdstr;
                snd-msg '--- *Public and *ALL error ---';
              endif;
            // *Public authority is user-defined
            when objAutRec.OAOBJA = 'USER DEF';
              cmdstr = 'GRTOBJAUT OBJ(' + %trim(objAutRec.OALIB) +
              '/' + %trim(objAutRec.OANAME) + ') OBJTYPE(' + %trim(objAutRec.OATYPE) + ') USER(' +
              %trim(objAutRec.OAUSR) + ') AUT(' ;
              if %trimr(objAutRec.OAOPR) = 'X';
                cmdstr = %trimr(cmdstr) + '*OBJOPR' ;
              endif;
              if %trimr(objAutRec.OAOMGT) ='X';
                cmdstr = %trimr(cmdstr) + ' *OBJMGT' ;
              endif;
              if %trimr(objAutRec.OAREAD) ='X';
                cmdstr = %trimr(cmdstr) + ' *READ' ;
              endif;
              if %trimr(objAutRec.OAADD) ='X';
                cmdstr = %trimr(cmdstr) + ' *ADD' ;
              endif;
              if %trimr(objAutRec.OAUPD) ='X';
                cmdstr = %trimr(cmdstr) + ' *UPD' ;
              endif;
              if %trimr(objAutRec.OADLT) ='X';
                cmdstr = %trimr(cmdstr) + ' *DLT' ;
              endif;
              if %trimr(objAutRec.OAEXS) ='X';
                cmdstr = %trimr(cmdstr) + ' *OBJEXIST' ;
              endif;
              if %trimr(objAutRec.OAEXEC) ='X';
                cmdstr = %trimr(cmdstr) + ' *EXECUTE' ;
              endif;
              if %trimr(objAutRec.OAALT) ='X';
                cmdstr = %trimr(cmdstr) + ' *OBJALTER' ;
              endif;
              if %trimr(objAutRec.OAREF) ='X';
                cmdstr = %trimr(cmdstr) + ' *OBJREF' ;
              endif;
              cmdstr = %trimr(cmdstr) + ') REPLACE(*NO)' ;
              returnCode = syscmd(cmdstr);
              snd-msg 'cmdstr: ' + cmdstr;
              if returnCode <> 0;
                snd-msg 'sqlcod: ' + %char(sqlcod);
                snd-msg '--- *Public and USER DEF error ---';
              endif;
            other;
              snd-msg '--- Unexpected error ---';
          endsl;
        // User profile is *Group
        when %trim(objAutRec.OAUSR) = '*GROUP' or objAutRec.OAGRPN <> '';
          select;
            // *Group authority is not user-defined
            when %trim(objAutRec.OAOBJA) <> 'USER DEF';
              cmdstr = 'GRTOBJAUT OBJ(' + %trim(objAutRec.OALIB) +
              '/' + %trim(objAutRec.OANAME) + ') OBJTYPE(' + %trim(objAutRec.OATYPE) + ') USER(' +
              %trim(objAutRec.OAGRPN) + ') AUT(' + %trim(objAutRec.OAOBJA) + ') REPLACE(*NO)' ;
              returnCode = syscmd(cmdstr);
              snd-msg 'cmdstr: ' + cmdstr;
              if returnCode <> 0;
                snd-msg 'sqlcod: ' + %char(sqlcod);
                snd-msg 'Grant *GROUP non user-defined Authority error.';
              endif;
            // *Group authority is *ALL
            when %trim(objAutRec.OAOBJA) = '*ALL';
              cmdstr = 'GRTOBJAUT OBJ(' + %trim(objAutRec.OALIB) +
              '/' + %trim(objAutRec.OANAME) + ') OBJTYPE(' + %trim(objAutRec.OATYPE) + ') USER(' +
              %trim(objAutRec.OAGRPN) + ') AUT(' + %trim(objAutRec.OAOBJA) + ') REPLACE(*NO)' ;
              returnCode = syscmd(cmdstr);
              snd-msg 'cmdstr: ' + cmdstr;
              if returnCode <> 0;
                snd-msg 'sqlcod: ' + %char(sqlcod);
                snd-msg 'Grant *GROUP *ALL Authority error.';
              endif;
            // *Group authority is user-defined
            when %trim(objAutRec.OAOBJA) = 'USER DEF';
              cmdstr = 'GRTOBJAUT OBJ(' + %trim(objAutRec.OALIB) +
              '/' + %trim(objAutRec.OANAME) + ') OBJTYPE(' + %trim(objAutRec.OATYPE) + ') USER(' +
              %trim(objAutRec.OAGRPN) + ') AUT(' ;
              if %trimr(objAutRec.OAOPR) = 'X';
                cmdstr = %trimr(cmdstr) + '*OBJOPR' ;
              endif;
              if %trimr(objAutRec.OAOMGT) ='X';
                cmdstr = %trimr(cmdstr) + ' *OBJMGT' ;
              endif;
              if %trimr(objAutRec.OAREAD) ='X';
                cmdstr = %trimr(cmdstr) + ' *READ' ;
              endif;
              if %trimr(objAutRec.OAADD) ='X';
                cmdstr = %trimr(cmdstr) + ' *ADD' ;
              endif;
              if %trimr(objAutRec.OAUPD) ='X';
                cmdstr = %trimr(cmdstr) + ' *UPD' ;
              endif;
              if %trimr(objAutRec.OADLT) ='X';
                cmdstr = %trimr(cmdstr) + ' *DLT' ;
              endif;
              if %trimr(objAutRec.OAEXS) ='X';
                cmdstr = %trimr(cmdstr) + ' *OBJEXIST' ;
              endif;
              if %trimr(objAutRec.OAEXEC) ='X';
                cmdstr = %trimr(cmdstr) + ' *EXECUTE' ;
              endif;
              if %trimr(objAutRec.OAALT) ='X';
                cmdstr = %trimr(cmdstr) + ' *OBJALTER' ;
              endif;
              if %trimr(objAutRec.OAREF) ='X';
                cmdstr = %trimr(cmdstr) + ' *OBJREF' ;
              endif;
              cmdstr = %trimr(cmdstr) + ') REPLACE(*NO)' ;
              returnCode = syscmd(cmdstr);
              snd-msg 'cmdstr: ' + cmdstr;
              if returnCode <> 0;
                snd-msg 'sqlcod: ' + %char(sqlcod);
                snd-msg '--- *Group and USER DEF error ---';
              endif;
            other;
              snd-msg '--- Unexpected error ---';
          endsl;
        // User profile is not *Public and not *Group
        other;
          select;
            // User authority is not user-defined
            when %trim(objAutRec.OAOBJA) <> 'USER DEF';
              cmdstr = 'GRTOBJAUT OBJ(' + %trim(objAutRec.OALIB) +
              '/' + %trim(objAutRec.OANAME) + ') OBJTYPE(' + %trim(objAutRec.OATYPE) + ') USER(' +
              %trim(objAutRec.OAUSR) + ') AUT(' + %trim(objAutRec.OAOBJA) + ') REPLACE(*NO)' ;
              returnCode = syscmd(cmdstr);
              snd-msg 'cmdstr: ' + cmdstr;
              if returnCode <> 0;
                snd-msg 'sqlcod: ' + %char(sqlcod);
                snd-msg '--- User and not USER DEF error ---';
              endif;
            // User authority is *ALL
            when %trim(objAutRec.OAOBJA) = '*ALL';
              cmdstr = 'GRTOBJAUT OBJ(' + %trim(objAutRec.OALIB) +
              '/' + %trim(objAutRec.OANAME) + ') OBJTYPE(' + %trim(objAutRec.OATYPE) + ') USER(' +
              %trim(objAutRec.OAUSR) + ') AUT(' + %trim(objAutRec.OAOBJA) + ') REPLACE(*NO)' ;
              returnCode = syscmd(cmdstr);
              snd-msg 'cmdstr: ' + cmdstr;
              if returnCode <> 0;
                snd-msg 'sqlcod: ' + %char(sqlcod);
                snd-msg '--- User and *ALL error ---';
              endif;
            // User authority is user-defined
            when %trim(objAutRec.OAOBJA) = 'USER DEF';
              cmdstr = 'GRTOBJAUT OBJ(' + %trim(objAutRec.OALIB) +
              '/' + %trim(objAutRec.OANAME) + ') OBJTYPE(' + %trim(objAutRec.OATYPE) + ') USER(' +
              %trim(objAutRec.OAUSR) + ') AUT(' ;
              if %trimr(objAutRec.OAOPR) = 'X';
                cmdstr = %trimr(cmdstr) + '*OBJOPR' ;
              endif;
              if %trimr(objAutRec.OAOMGT) ='X';
                cmdstr = %trimr(cmdstr) + ' *OBJMGT' ;
              endif;
              if %trimr(objAutRec.OAREAD) ='X';
                cmdstr = %trimr(cmdstr) + ' *READ' ;
              endif;
              if %trimr(objAutRec.OAADD) ='X';
                cmdstr = %trimr(cmdstr) + ' *ADD' ;
              endif;
              if %trimr(objAutRec.OAUPD) ='X';
                cmdstr = %trimr(cmdstr) + ' *UPD' ;
              endif;
              if %trimr(objAutRec.OADLT) ='X';
                cmdstr = %trimr(cmdstr) + ' *DLT' ;
              endif;
              if %trimr(objAutRec.OAEXS) ='X';
                cmdstr = %trimr(cmdstr) + ' *OBJEXIST' ;
              endif;
              if %trimr(objAutRec.OAEXEC) ='X';
                cmdstr = %trimr(cmdstr) + ' *EXECUTE' ;
              endif;
              if %trimr(objAutRec.OAALT) ='X';
                cmdstr = %trimr(cmdstr) + ' *OBJALTER' ;
              endif;
              if %trimr(objAutRec.OAREF) ='X';
                cmdstr = %trimr(cmdstr) + ' *OBJREF' ;
              endif;
              cmdstr = %trimr(cmdstr) + ') REPLACE(*NO)' ;
              returnCode = syscmd(cmdstr);
              snd-msg 'cmdstr: ' + cmdstr;
              if returnCode <> 0;
                snd-msg 'sqlcod: ' + %char(sqlcod);
                snd-msg '--- User and USER DEF error ---';
              endif;
            other;
              snd-msg '--- Unexpected error ---';
          endsl;
      endsl;
    else;
    snd-msg '--- sqlcod 100. Entry not found. Attempting to add. ---';
      if %subst(objAutRec.OAGRPN : 1 : 1) <> ' ';
        select;
        // Local object authority not found, try to add authority
          when %trim(objAutRec.OAOBJA) <> 'USER DEF';
            cmdstr = 'GRTOBJAUT OBJ(' + %trim(objAutRec.OALIB) +
            '/' + %trim(objAutRec.OANAME) + ') OBJTYPE(' + %trim(objAutRec.OATYPE) + ') USER(' +
            %trim(objAutRec.OAGRPN) + ') AUT(' + %trim(objAutRec.OAOBJA) + ') REPLACE(*NO)' ;
            returnCode = syscmd(cmdstr);
            snd-msg 'cmdstr: ' + cmdstr;
            if returnCode <> 0;
              snd-msg 'sqlcod: ' + %char(sqlcod);
              snd-msg '--- Not found and not USER DEF error ---';
            endif;
          // User authority is *ALL
          when %trim(objAutRec.OAOBJA) = '*ALL';
            cmdstr = 'GRTOBJAUT OBJ(' + %trim(objAutRec.OALIB) +
            '/' + %trim(objAutRec.OANAME) + ') OBJTYPE(' + %trim(objAutRec.OATYPE) + ') USER(' +
            %trim(objAutRec.OAGRPN) + ') AUT(' + %trim(objAutRec.OAOBJA) + ') REPLACE(*NO)' ;
            returnCode = syscmd(cmdstr);
            snd-msg 'cmdstr: ' + cmdstr;
            if returnCode <> 0;
              snd-msg 'sqlcod: ' + %char(sqlcod);
              snd-msg '--- Not found and *ALL error ---';
            endif;
          // User authority is user-defined
          when %trim(objAutRec.OAOBJA) = 'USER DEF';
            cmdstr = 'GRTOBJAUT OBJ(' + %trim(objAutRec.OALIB) +
            '/' + %trim(objAutRec.OANAME) + ') OBJTYPE(' + %trim(objAutRec.OATYPE) + ') USER(' +
            %trim(objAutRec.OAGRPN) + ') AUT(' ;
            if %trimr(objAutRec.OAOPR) = 'X';
              cmdstr = %trimr(cmdstr) + '*OBJOPR' ;
            endif;
            if %trimr(objAutRec.OAOMGT) ='X';
              cmdstr = %trimr(cmdstr) + ' *OBJMGT' ;
            endif;
            if %trimr(objAutRec.OAREAD) ='X';
              cmdstr = %trimr(cmdstr) + ' *READ' ;
            endif;
            if %trimr(objAutRec.OAADD) ='X';
              cmdstr = %trimr(cmdstr) + ' *ADD' ;
            endif;
            if %trimr(objAutRec.OAUPD) ='X';
              cmdstr = %trimr(cmdstr) + ' *UPD' ;
            endif;
            if %trimr(objAutRec.OADLT) ='X';
              cmdstr = %trimr(cmdstr) + ' *DLT' ;
            endif;
            if %trimr(objAutRec.OAEXS) ='X';
              cmdstr = %trimr(cmdstr) + ' *OBJEXIST' ;
            endif;
            if %trimr(objAutRec.OAEXEC) ='X';
              cmdstr = %trimr(cmdstr) + ' *EXECUTE' ;
            endif;
            if %trimr(objAutRec.OAALT) ='X';
              cmdstr = %trimr(cmdstr) + ' *OBJALTER' ;
            endif;
            if %trimr(objAutRec.OAREF) ='X';
              cmdstr = %trimr(cmdstr) + ' *OBJREF' ;
            endif;
            cmdstr = %trimr(cmdstr) + ') REPLACE(*NO)' ;
            returnCode = syscmd(cmdstr);
            snd-msg 'cmdstr: ' + cmdstr;
            if returnCode <> 0;
              snd-msg 'sqlcod: ' + %char(sqlcod);
              snd-msg '--- Not found and USER DEF error ---';
            endif;
          other;
            snd-msg '--- Unexpected error ---';
        endsl;
      else;
        select;
        // Local object authority not found, try to add authority
          when %trim(objAutRec.OAOBJA) <> 'USER DEF';
            cmdstr = 'GRTOBJAUT OBJ(' + %trim(objAutRec.OALIB) +
            '/' + %trim(objAutRec.OANAME) + ') OBJTYPE(' + %trim(objAutRec.OATYPE) + ') USER(' +
            %trim(objAutRec.OAUSR) + ') AUT(' + %trim(objAutRec.OAOBJA) + ') REPLACE(*NO)' ;
            returnCode = syscmd(cmdstr);
            snd-msg 'cmdstr: ' + cmdstr;
            if returnCode <> 0;
              snd-msg 'sqlcod: ' + %char(sqlcod);
              snd-msg '--- Not found and not USER DEF error ---';
            endif;
          // User authority is *ALL
          when %trim(objAutRec.OAOBJA) = '*ALL';
            cmdstr = 'GRTOBJAUT OBJ(' + %trim(objAutRec.OALIB) +
            '/' + %trim(objAutRec.OANAME) + ') OBJTYPE(' + %trim(objAutRec.OATYPE) + ') USER(' +
            %trim(objAutRec.OAUSR) + ') AUT(' + %trim(objAutRec.OAOBJA) + ') REPLACE(*NO)' ;
            returnCode = syscmd(cmdstr);
            snd-msg 'cmdstr: ' + cmdstr;
            if returnCode <> 0;
              snd-msg 'sqlcod: ' + %char(sqlcod);
              snd-msg '--- Not found and *ALL error ---';
            endif;
          // User authority is user-defined
          when %trim(objAutRec.OAOBJA) = 'USER DEF';
            cmdstr = 'GRTOBJAUT OBJ(' + %trim(objAutRec.OALIB) +
            '/' + %trim(objAutRec.OANAME) + ') OBJTYPE(' + %trim(objAutRec.OATYPE) + ') USER(' +
            %trim(objAutRec.OAUSR) + ') AUT(' ;
            if %trimr(objAutRec.OAOPR) = 'X';
              cmdstr = %trimr(cmdstr) + '*OBJOPR' ;
            endif;
            if %trimr(objAutRec.OAOMGT) ='X';
              cmdstr = %trimr(cmdstr) + ' *OBJMGT' ;
            endif;
            if %trimr(objAutRec.OAREAD) ='X';
              cmdstr = %trimr(cmdstr) + ' *READ' ;
            endif;
            if %trimr(objAutRec.OAADD) ='X';
              cmdstr = %trimr(cmdstr) + ' *ADD' ;
            endif;
            if %trimr(objAutRec.OAUPD) ='X';
              cmdstr = %trimr(cmdstr) + ' *UPD' ;
            endif;
            if %trimr(objAutRec.OADLT) ='X';
              cmdstr = %trimr(cmdstr) + ' *DLT' ;
            endif;
            if %trimr(objAutRec.OAEXS) ='X';
              cmdstr = %trimr(cmdstr) + ' *OBJEXIST' ;
            endif;
            if %trimr(objAutRec.OAEXEC) ='X';
              cmdstr = %trimr(cmdstr) + ' *EXECUTE' ;
            endif;
            if %trimr(objAutRec.OAALT) ='X';
              cmdstr = %trimr(cmdstr) + ' *OBJALTER' ;
            endif;
            if %trimr(objAutRec.OAREF) ='X';
              cmdstr = %trimr(cmdstr) + ' *OBJREF' ;
            endif;
            cmdstr = %trimr(cmdstr) + ') REPLACE(*NO)' ;
            returnCode = syscmd(cmdstr);
            snd-msg 'cmdstr: ' + cmdstr;
            if returnCode <> 0;
              snd-msg 'sqlcod: ' + %char(sqlcod);
              snd-msg '--- Not found and USER DEF error ---';
            endif;
          other;
            snd-msg '--- Unexpected error ---';
        endsl;
      endif;
    endif;
  endif;

  EXEC SQL
    fetch next from objaut into :objAutRec.oasyst,
                                :objAutRec.oalib,
                                :objAutRec.oaname,
                                :objAutRec.oatype,
                                :objAutRec.oausr,
                                :objAutRec.oaobja,
                                :objAutRec.oaown,
                                :objAutRec.oagrpn,
                                :objAutRec.oaopr,
                                :objAutRec.oaomgt,
                                :objAutRec.oaread,
                                :objAutRec.oaadd,
                                :objAutRec.oaupd,
                                :objAutRec.oadlt,
                                :objAutRec.oaamgt,
                                :objAutRec.oaanam,
                                :objAutRec.oaexec,
                                :objAutRec.oaalt,
                                :objAutRec.oaref;
  snd-msg '----- Record End -----';
ENDDO;

exec sql
    close objaut;

*inlr = *on;
return;
