**FREE
ctl-opt option(*srcstmt) actgrp(*caller) ;

// cur_sysnm    => 取得現行主機名稱
// exelib       => 可以指定要執行的Library。如果輸入*ALL，則執行全部 Library。
// save_volume  => 顯示物件來自於哪捲磁帶
// srclbob      => 組成權限檔路徑 "Library.Object"
// srclbnm      => 權限檔存放位置 "DDSCINFO"

// declare user-input variable
dcl-pi *n;
  exelib char(10);
end-pi;

dcl-s stmt varchar(512);

dcl-pr syscmd int(10) ExtProc('system');
  *n Pointer Value Options(*String);
end-pr;

dcl-s cmdstr char(500) inz('');
dcl-s returnCode int(3);

// Get current system name
dcl-s cur_sysnm varchar(10) inz;

// declare schema related
dcl-s schema_name varchar(128);

dcl-s objname varchar(10);
dcl-s objtype varchar(8);
dcl-s objlongschema varchar(128);
dcl-s save_volume varchar(71);

// Get current system name 
exec sql 
  values current server into :cur_sysnm;
snd-msg '--------------------------------------------------';
cur_sysnm = 'KSG01N';
snd-msg ' Current SysName : ' + cur_sysnm;
snd-msg '--------------------------------------------------';

// declare liblst cursor
if exelib = '*ALL' or exelib = '*all';
  stmt = 'Select schema_name ' +
         'from qsys2.sysschemas ' + 
         'Where schema_name <> ''#COBLIB'' ' +
         'And schema_name <> ''#LIBRARY'' ' +
         'And schema_name <> ''#RPGLIB'' ' +
         'And schema_name Not Like ''Q%'' ' +
         'And schema_name <> ''SYSIBM'' ' +
         'And schema_name <> ''SYSIBMADM'' ' +
         'And schema_name <> ''SYSTOOLS'' ' +
         'And schema_name <> ''SYSPROC'' ';

elseif exelib = '#COBLIB' or exelib = '#LIBRARY' or exelib = '#RPGLIB' or
       %subst(exelib : 1 : 1) = 'Q' or exelib = 'SYSIBM' or exelib = 'SYSIBMADM' or 
       exelib = 'SYSTOOLS' or exelib = 'SYSPROC';
  snd-msg ' *** Please do not input System Library Name! *** ';
  *inlr = *on; 
  return;
else;
  stmt = 'Select schema_name ' +
         'from qsys2.sysschemas ' + 
         'where schema_name = ''' + %upper(%trim(exelib)) + ''' ' + 
         'And schema_name <> ''#COBLIB'' ' +
         'And schema_name <> ''#LIBRARY'' ' +
         'And schema_name <> ''#RPGLIB'' ' +
         'And schema_name Not Like ''Q%'' ' +
         'And schema_name <> ''SYSIBM'' ' +
         'And schema_name <> ''SYSIBMADM'' ' +
         'And schema_name <> ''SYSTOOLS'' ' +
         'And schema_name <> ''SYSPROC'' ';
endif;

exec sql prepare preliblst from :stmt;

exec sql declare liblst cursor for preliblst;

exec sql open liblst;
  
exec sql
  fetch from liblst into :schema_name;
// *** Process Library List
dow sqlcod = 0;
  if sqlcod = 0;
    // declare objlst cursor
    exec sql 
      declare objlst cursor for 
        Select cast(Coalesce(objname,'*NONE') AS char(10)) AS objname, 
               cast(coalesce(objtype,'*NONE') AS char(8)) AS objtype, 
               cast(coalesce(objlongschema,'*NONE') AS char(128)) AS objlongschema,
               cast(coalesce(save_volume,'*NONE') AS char(71)) AS save_volume
        From Table (
            qsys2.object_statistics(
                object_schema => :schema_name, 
                objtypelist => '*ALL')
        );

    exec sql 
      open objlst;
    
    exec sql 
      fetch objlst into :objname,
                        :objtype,
                        :objlongschema,
                        :save_volume;
    // *** Process Object List
    dow sqlcod = 0;
      if sqlcod = 0;
        // snd-msg 'Input: ' + %trim(objlongschema) + '/' + %trim(objname) + '/' + %trim(objtype) + '.';
        find_chg_objaut(cur_sysnm:save_volume:objlongschema:objname:objtype);
      endif;
      //
      exec sql 
        fetch objlst into :objname,
                          :objtype,
                          :objlongschema,
                          :save_volume;
    enddo;

    exec sql 
      close objlst;
  
  endif;

  exec sql
    fetch from liblst into :schema_name;

enddo;

exec sql
  close liblst; 

*inlr = *on ;
return ;


dcl-proc find_chg_objaut;
  dcl-pi *n ;
    cur_sysnm varchar(10);
    save_volume varchar(71);
    objlib varchar(128);
    objname varchar(10);
    objtype varchar(8);
  end-pi;

  dcl-s srclbnm char(10);
  dcl-s srcobnm char(10);
  dcl-s srclbob char(21);

  // from_file
  dcl-s oalib  char(10);  // Library
  dcl-s oaname char(10);  // Object
  dcl-s oatype char(8);   // Object_type
  dcl-s oausr  char(10);  // user_profile
  dcl-s oaobja char(12);   // object_authority
  dcl-s oaown  char(10);  // object_owner
  dcl-s oapgrp char(10);  // Primary_group
  dcl-s oagrpn char(10);  // object_group_name
  dcl-s oaopr  char(3);   // operational
  dcl-s oaomgt char(3);   // object_management
  dcl-s oaexs  char(3);   // object_exist
  dcl-s oaread char(3);   // data_read
  dcl-s oaadd  char(3);   // data_add
  dcl-s oaupd  char(3);   // data_update
  dcl-s oadlt  char(3);   // data_delete
  dcl-s oaamgt char(3);   // auth_list_mgmt
  dcl-s oaanam char(10);  // auth_list_name
  dcl-s oaexec char(3);   // data_execute
  dcl-s oaalt  char(3);   // object_alter
  dcl-s oaref  char(3);   // object_ref

  dcl-s stmt varchar(512);

  // from_current_object
  dcl-s system_object_schema varchar(10); // Library
  dcl-s system_object_name  varchar(10);  // Object
  dcl-s object_type         varchar(8);   // Object_type
  dcl-s authorization_name  varchar(10);  // user_profile
  dcl-s object_authority    varchar(12);  // object_authority
  dcl-s owner               varchar(10);  // object_owner
  dcl-s primary_group       varchar(10);  // object_group_name
  dcl-s object_operational  varchar(3);   // operational
  dcl-s object_management   varchar(3);   // object_management
  dcl-s object_existence    varchar(3);   // object_exist
  dcl-s data_read           varchar(3);   // data_read
  dcl-s data_add            varchar(3);   // data_add
  dcl-s data_update         varchar(3);   // data_update
  dcl-s data_delete         varchar(3);   // data_delete
  dcl-s autl_mgmt           varchar(3);   // auth_list_mgmt
  dcl-s authorization_list  varchar(10);  // auth_list_name
  dcl-s data_execute        varchar(3);   // data_execute
  dcl-s object_alter        varchar(3);   // object_alter
  dcl-s object_reference    varchar(3);   // object_ref
  dcl-s object_owner        varchar(3);   // object_owner_ind

  dcl-pr syscmd int(10) ExtProc('system');
    *n Pointer Value Options(*String);
  end-pr;

  dcl-s cmdstr varchar(512);
  dcl-s returnCode int(5);

  // Procedure Begin  
  srclbnm = 'OAKSG01N';     // KGI => 'DDSCINFO'
  // save_volume = 'F02Y25';   // KGI => 'XXXY25'
  if save_volume = '*NONE';
    save_volume = %subst(%trim(cur_sysnm) : 3 : 3 );
    srcobnm = 'OBJAUT' + %subst(%trim(cur_sysnm) : 3 : 3 ); 
    srclbob = %trimr(srclbnm) + '.' + %trim(srcobnm);
  else;
    save_volume = %subst(%trim(save_volume) : 1 : 3 );
    srcobnm = 'OBJAUT' + %subst(%trim(save_volume) : 1 : 3 ); 
    srclbob = %trimr(srclbnm) + '.' + %trim(srcobnm);
  endif;

  // from_file
  stmt = 'select oalib, oaname, oatype, oausr, oaobja, oaown, oapgrp, oagrpn, oaopr, oaomgt, ' +
           'oaexs, oaread, oaadd, oaupd, oadlt, oaamgt, oaanam, oaexec, oaalt, oaref ' + 
           'from ' + %trim(srclbob) + ' ' +
           'where oalib = ''' + %trim(objlib) + ''' ' +
           'and oaname = ''' + %trim(objname) + ''' ' +
           'and oatype = ''' + %trim(objtype) + ''' ' +
           'order by oalib, oaname, oatype, oausr ' ;
    // snd-msg stmt;
    
  exec sql prepare S1 from :stmt;
  
  exec sql declare c1 cursor for S1;
  
  exec sql open c1;
  
  exec sql fetch from c1 into :oalib,
                              :oaname,
                              :oatype,
                              :oausr, 
                              :oaobja,
                              :oaown,
                              :oapgrp, 
                              :oagrpn,
                              :oaopr, 
                              :oaomgt,
                              :oaexs, 
                              :oaread,
                              :oaadd, 
                              :oaupd, 
                              :oadlt, 
                              :oaamgt,
                              :oaanam,
                              :oaexec,
                              :oaalt, 
                              :oaref ;
  
  dow sqlcod = 0;

    if sqlcod = 0;

      // *** important ***
      if %trim(oausr) = '*GROUP';
        oausr = %trim(oagrpn);
      endif;
      if %trim(oaobja) = 'USER DEF';
        oaobja = 'USER DEFINED';
      endif;
      if %trim(oaopr) = 'X';
        oaopr = 'YES';
      else;
        oaopr = 'NO';
      endif;
      if %trim(oaomgt) = 'X';
        oaomgt = 'YES';
      else;
        oaomgt = 'NO';
      endif;
      if %trim(oaexs) = 'X';
        oaexs = 'YES';
      else;
        oaexs = 'NO';
      endif;
      if %trim(oaread) = 'X';
        oaread = 'YES';
      else;
        oaread = 'NO';
      endif;
      if %trim(oaadd) = 'X';
        oaadd = 'YES';
      else;
        oaadd = 'NO';
      endif;
      if %trim(oaupd) = 'X';
        oaupd = 'YES';
      else;
        oaupd = 'NO';
      endif;
      if %trim(oadlt) = 'X';
        oadlt = 'YES';
      else;
        oadlt = 'NO';
      endif;
      if %trim(oaexec) = 'X';
        oaexec = 'YES';
      else;
        oaexec = 'NO';
      endif;
      if %trim(oaalt) = 'X';
        oaalt = 'YES';
      else;
        oaalt = 'NO';
      endif;
      if %trim(oaref) = 'X';
        oaref = 'YES';
      else;
        oaref = 'NO';
      endif;
      if %trim(oaamgt) = 'X';
        oaamgt = 'YES';
      else;
        oaamgt = 'NO';
      endif;

      exec sql 
          Select  system_object_schema, system_object_name, object_type,
                  authorization_name, object_authority, owner,
                  Cast(Coalesce(primary_group, '*NONE') As Char(10)) as primary_group,
                  object_operational, object_management, object_existence,
                  data_read, data_add, data_update, authorization_list_management,
                  cast(coalesce(authorization_list, '*NONE') As Char(10)) as authorization_list,
                  data_delete, data_execute, object_alter, object_reference, object_owner
          into    :system_object_schema, :system_object_name, :object_type,
                  :authorization_name, :object_authority, :owner, 
                  :primary_group,  
                  :object_operational, :object_management, :object_existence,
                  :data_read, :data_add, :data_update, :autl_mgmt, 
                  :authorization_list,
                  :data_delete, :data_execute, :object_alter, :object_reference, :object_owner
          From qsys2.object_privileges
          Where system_object_schema = trim(:objlib)
            And system_object_name = trim(:objname)
            And object_type = trim(:objtype)
            And authorization_name = trim(:oausr) ;
      
      // snd-msg 'from_curr sqlcod : ' + %char(sqlcod);
      if sqlcod = 0;
        snd-msg '*** From : ' + %trim(save_volume) + ' ***'; 
        snd-msg '  from_file: ' + %trim(oalib) + '/' + %trim(oaname) + '/' + %trim(oatype) + 
                '/' + %trim(oausr) + '.';
        snd-msg '  from_curr: ' + %trim(objlib) + '/' + %trim(objname) + '/' + %trim(objtype) + 
                  '/' + %trim(authorization_name) + '.';
        if %trim(oausr) = '*PUBLIC' and %trim(owner) <> %trim(oaown);
          snd-msg '  ----- Owner diff -----';
          snd-msg '  from_file: ' + %trim(oaown) + '.';
          snd-msg '  from_curr: ' + %trim(owner) + '.';        
          cmdstr =  'CHGOBJOWN OBJ(' + %trim(objlib) + '/' +
                    %trim(objname) + ') OBJTYPE(' + %trim(objtype) +
                    ') NEWOWN(' + %trim(oaown) + ')' ;
          // returnCode = syscmd(cmdstr);
          snd-msg '  cmdstr: ' + cmdstr;
          // if returnCode <> 0;
          //   snd-msg 'sqlcod: ' + %char(sqlcod);
          //   snd-msg 'Change object owner error.';
          // endif;
        endif;
        if %trim(oausr) = '*PUBLIC' and %trim(authorization_list) <> %trim(oaanam);
          snd-msg '  ----- Authority List diff -----';
          snd-msg '  from_file: ' + %trim(oaanam) + '.';
          snd-msg '  from_curr: ' + %trim(authorization_list) + '.';
          cmdstr =  'GRTOBJAUT OBJ(' + %trim(objlib) + '/' +
                    %trim(objname) + ') OBJTYPE(' + %trim(objtype) +
                    ') AUTL(' + %trim(oaanam) + ')' ;
          // returnCode = syscmd(cmdstr);
          snd-msg '  cmdstr: ' + cmdstr;
          // if returnCode <> 0;
          //   snd-msg 'sqlcod: ' + %char(sqlcod);
          //   snd-msg 'Change object owner error.';
          // endif;
        endif;
        if %trim(oausr) = '*PUBLIC' and %trim(autl_mgmt) <> %trim(oaamgt);
          snd-msg '  ----- Authority List management diff -----';
          snd-msg '  from_file: ' + %trim(oaamgt) + '.';
          snd-msg '  from_curr: ' + %trim(autl_mgmt) + '.';
          cmdstr =  'GRTOBJAUT OBJ(' + %trim(objlib) + '/' +
                    %trim(objname) + ') OBJTYPE(' + %trim(objtype) +
                    ') USER(*PUBLIC) AUT(*AUTL)' ;
          // returnCode = syscmd(cmdstr);
          snd-msg '  cmdstr: ' + cmdstr;
          // if returnCode <> 0;
          //   snd-msg 'sqlcod: ' + %char(sqlcod);
          //   snd-msg 'Change object owner error.';
          // endif;
        endif;
        if %trim(object_authority) <> %trim(oaobja) or 
           %trim(object_operational) <> %trim(oaopr) or
           %trim(object_management) <> %trim(oaomgt) or 
           %trim(object_existence) <> %trim(oaexs) or
           %trim(data_read) <> %trim(oaread) or
           %trim(data_add) <> %trim(oaadd) or
           %trim(data_update) <> %trim(oaupd) or
           %trim(data_delete) <> %trim(oadlt) or
           %trim(data_execute) <> %trim(oaexec) or
           %trim(object_alter) <> %trim(oaalt) or
           %trim(object_reference) <> %trim(oaref);
          snd-msg '  ----- Authority diff -----';
          snd-msg '  from_file: ' + %trim(oaobja) + '.';
          snd-msg '  from_file: ' + %trim(oaopr) + '/' + %trim(oaomgt) + '/' + %trim(oaexs) + 
                  '/' + %trim(oaread) + '/' + %trim(oaadd) + '/' + %trim(oaupd) + 
                  '/' + %trim(oadlt) + '/' + %trim(oaexec) + '/' + %trim(oaalt) +
                  '/' + %trim(oaref) + '.';
          snd-msg 'from_curr: ' + %trim(object_authority) + '.';
          snd-msg 'from_curr: ' + %trim(object_operational) + '/' + %trim(object_management) + 
                  '/' + %trim(object_existence) + 
                  '/' + %trim(data_read) + '/' + %trim(data_add) + '/' + %trim(data_update) + 
                  '/' + %trim(data_delete) + '/' + %trim(data_execute) + '/' + %trim(object_alter) +
                  '/' + %trim(object_reference) + '.';
          select;
          // Object authority is USER DEF
            when %trim(oaobja) <> 'USER DEFINED';
              cmdstr = 'GRTOBJAUT OBJ(' + %trim(oalib) +
              '/' + %trim(oaname) + ') OBJTYPE(' + %trim(oatype) + ') USER(' +
              %trim(oausr) + ') AUT(' + %trim(oaobja) + ') REPLACE(*NO)' ;
              // returnCode = syscmd(cmdstr);
              snd-msg '  cmdstr: ' + cmdstr;
              // if returnCode <> 0;
              //   snd-msg 'sqlcod: ' + %char(sqlcod);
              //   snd-msg 'Grant object non user-defined authority error.';
              // endif;
            // Object authority is *ALL
            when %trim(oaobja) = '*ALL';
              cmdstr = 'GRTOBJAUT OBJ(' + %trim(oalib) +
              '/' + %trim(oaname) + ') OBJTYPE(' + %trim(oatype) + ') USER(' +
              %trim(oausr) + ') AUT(' + %trim(oaobja) + ') REPLACE(*NO)' ;
              // returnCode = syscmd(cmdstr);
              snd-msg '  cmdstr: ' + cmdstr;
              // if returnCode <> 0;
              //   snd-msg 'sqlcod: ' + %char(sqlcod);
              //   snd-msg 'Grant object *ALL authority error.';
              // endif;
            // Object authority is user-defined
            when %trim(oaobja) = 'USER DEFINED';
              cmdstr = 'GRTOBJAUT OBJ(' + %trim(oalib) +
              '/' + %trim(oaname) + ') OBJTYPE(' + %trim(oatype) + ') USER(' +
              %trim(oausr) + ') AUT(' ;
              if %trimr(oaopr) = 'YES';
                cmdstr = %trimr(cmdstr) + '*OBJOPR' ;
              endif;
              if %trimr(oaomgt) ='YES';
                cmdstr = %trimr(cmdstr) + ' *OBJMGT' ;
              endif;
              if %trimr(oaread) ='YES';
                cmdstr = %trimr(cmdstr) + ' *READ' ;
              endif;
              if %trimr(oaadd) ='YES';
                cmdstr = %trimr(cmdstr) + ' *ADD' ;
              endif;
              if %trimr(oaupd) ='YES';
                cmdstr = %trimr(cmdstr) + ' *UPD' ;
              endif;
              if %trimr(oadlt) ='YES';
                cmdstr = %trimr(cmdstr) + ' *DLT' ;
              endif;
              if %trimr(oaexs) ='YES';
                cmdstr = %trimr(cmdstr) + ' *OBJEXIST' ;
              endif;
              if %trimr(oaexec) ='YES';
                cmdstr = %trimr(cmdstr) + ' *EXECUTE' ;
              endif;
              if %trimr(oaalt) ='YES';
                cmdstr = %trimr(cmdstr) + ' *OBJALTER' ;
              endif;
              if %trimr(oaref) ='YES';
                cmdstr = %trimr(cmdstr) + ' *OBJREF' ;
              endif;
              cmdstr = %trimr(cmdstr) + ') REPLACE(*NO)' ;
              // returnCode = syscmd(cmdstr);
              snd-msg '  cmdstr: ' + cmdstr;
              // if returnCode <> 0;
              //   snd-msg 'sqlcod: ' + %char(sqlcod);
              //   snd-msg '--- Grant object USER DEF authority error ---';
              // endif;
            other;
              snd-msg '  --- Unexpected error ---';
          endsl;
          snd-msg '----- Record End -----';
        endif;
      elseif sqlcod = 100;
        snd-msg '*** From : ' + %trim(save_volume) + ' ***'; 
        snd-msg '  ----- Authority missing -----';
        snd-msg '  From_file Object authority : ' + %trim(oaobja);
        snd-msg '  Object authority not found. Grant object authority. ' ;
        select;
        // Object authority is USER DEF
          when %trim(oaobja) <> 'USER DEFINED';
            cmdstr = 'GRTOBJAUT OBJ(' + %trim(oalib) +
            '/' + %trim(oaname) + ') OBJTYPE(' + %trim(oatype) + ') USER(' +
            %trim(oausr) + ') AUT(' + %trim(oaobja) + ') REPLACE(*NO)' ;
            // returnCode = syscmd(cmdstr);
            snd-msg '  cmdstr: ' + cmdstr;
            // if returnCode <> 0;
            //   snd-msg 'sqlcod: ' + %char(sqlcod);
            //   snd-msg 'Grant object non user-defined authority error.';
            // endif;
          // Object authority is *ALL
          when %trim(oaobja) = '*ALL';
            cmdstr = 'GRTOBJAUT OBJ(' + %trim(oalib) +
            '/' + %trim(oaname) + ') OBJTYPE(' + %trim(oatype) + ') USER(' +
            %trim(oausr) + ') AUT(' + %trim(oaobja) + ') REPLACE(*NO)' ;
            // returnCode = syscmd(cmdstr);
            snd-msg '  cmdstr: ' + cmdstr;
            // if returnCode <> 0;
            //   snd-msg 'sqlcod: ' + %char(sqlcod);
            //   snd-msg 'Grant object *ALL authority error.';
            // endif;
          // Object authority is user-defined
          when %trim(oaobja) = 'USER DEFINED';
            cmdstr = 'GRTOBJAUT OBJ(' + %trim(oalib) +
            '/' + %trim(oaname) + ') OBJTYPE(' + %trim(oatype) + ') USER(' +
            %trim(oausr) + ') AUT(' ;
            if %trimr(oaopr) = 'YES';
              cmdstr = %trimr(cmdstr) + '*OBJOPR' ;
            endif;
            if %trimr(oaomgt) ='YES';
              cmdstr = %trimr(cmdstr) + ' *OBJMGT' ;
            endif;
            if %trimr(oaread) ='YES';
              cmdstr = %trimr(cmdstr) + ' *READ' ;
            endif;
            if %trimr(oaadd) ='YES';
              cmdstr = %trimr(cmdstr) + ' *ADD' ;
            endif;
            if %trimr(oaupd) ='YES';
              cmdstr = %trimr(cmdstr) + ' *UPD' ;
            endif;
            if %trimr(oadlt) ='YES';
              cmdstr = %trimr(cmdstr) + ' *DLT' ;
            endif;
            if %trimr(oaexs) ='YES';
              cmdstr = %trimr(cmdstr) + ' *OBJEXIST' ;
            endif;
            if %trimr(oaexec) ='YES';
              cmdstr = %trimr(cmdstr) + ' *EXECUTE' ;
            endif;
            if %trimr(oaalt) ='YES';
              cmdstr = %trimr(cmdstr) + ' *OBJALTER' ;
            endif;
            if %trimr(oaref) ='YES';
              cmdstr = %trimr(cmdstr) + ' *OBJREF' ;
            endif;
            cmdstr = %trimr(cmdstr) + ') REPLACE(*NO)' ;
            // returnCode = syscmd(cmdstr);
            snd-msg '  cmdstr: ' + cmdstr;
            // if returnCode <> 0;
            //   snd-msg 'sqlcod: ' + %char(sqlcod);
            //   snd-msg '--- Grant object USER DEF authority error ---';
            // endif;
          other;
            snd-msg '  --- Unexpected error ---';
        endsl;
        snd-msg '----- Record End -----';
      else;
        snd-msg '  --- Unexpected error ---';
      endif;
    endif;

    exec sql fetch from c1 into :oalib,
                                  :oaname,
                                  :oatype,
                                  :oausr, 
                                  :oaobja,
                                  :oaown,
                                  :oapgrp, 
                                  :oagrpn,
                                  :oaopr, 
                                  :oaomgt,
                                  :oaexs, 
                                  :oaread,
                                  :oaadd, 
                                  :oaupd, 
                                  :oadlt, 
                                  :oaamgt,
                                  :oaanam,
                                  :oaexec,
                                  :oaalt, 
                                  :oaref ;
  
  enddo;
  
  exec sql close c1;

end-proc;