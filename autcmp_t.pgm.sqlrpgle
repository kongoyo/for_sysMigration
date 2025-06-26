**FREE
ctl-opt option(*srcstmt) actgrp(*caller) ;

// declare user-input variable

dcl-pi *n;
  exelib char(10);
end-pi;

// declare compare source data structure
// DCL-DS objAutRec EXTNAME('OAAS101N/OBJAUT101') QUALIFIED;
// END-DS;

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
dcl-s objnm_Nul int(5);
dcl-s objtype varchar(8);
dcl-s objtp_Nul int(5);
dcl-s objlongschema varchar(128);
dcl-s objlsc_Nul int(5);

// Get current system name 
exec sql 
  values current server into :cur_sysnm;
snd-msg '--------------------------------------------------';
snd-msg ' Current SysName : ' + cur_sysnm;
cur_sysnm = 'AS101N';
snd-msg 'Modified SysName : ' + cur_sysnm;
snd-msg '--------------------------------------------------';

// declare liblst cursor
exec sql
  declare liblst cursor for
    Select schema_name
         from qsys2.sysschemas 
         where schema_name = 'DDSCINFO'; 
            // or schema_name = 'STEVE';
      // Where schema_name <> '#COBLIB'
      //       And schema_name <> '#LIBRARY'
      //       And schema_name <> '#RPGLIB'
      //       And schema_name Not Like 'Q%'
      //       And schema_name Not Like 'SYSIBM%'
      //       And schema_name <> 'SYSTOOLS'
      //       And schema_name <> 'SYSPROC';  

exec sql
  open liblst;
  
exec sql
  fetch from liblst into :schema_name;
// *** Process Library List
dow sqlcod = 0;
  if sqlcod = 0;
    // declare objlst cursor
    exec sql 
      declare objlst cursor for 
        Select objname, objtype, objlongschema
        From Table (
            qsys2.object_statistics(
                object_schema => :schema_name, 
                objtypelist => '*ALL')
        );

    exec sql 
      open objlst;
    
    exec sql 
      fetch objlst into :objname :objnm_Nul,
                        :objtype :objtp_Nul,
                        :objlongschema :objlsc_Nul;
    // *** Process Object List
    dow sqlcod = 0;
      if sqlcod = 0;
        if objnm_Nul <> -1 and objtp_Nul <> -1 and objlsc_Nul <> -1;
          // snd-msg '--------------------------------------------------';
          // snd-msg ' Object Lib  : ' + objlongschema;
          // snd-msg ' Object Name : ' + objname;
          // snd-msg ' Object Type : ' + objtype;

          // Get current object authority
          // get_cur_objaut(cur_sysnm:objlongschema:objlsc_Nul:objname:objnm_Nul:objtype:objtp_Nul);

          // *** Execute find and change object authority procedure
          find_chg_objaut(cur_sysnm:objlongschema:objlsc_Nul:objname:objnm_Nul:objtype:objtp_Nul);
        endif;
      endif;

      exec sql 
        fetch objlst into :objname :objnm_Nul,
                          :objtype :objtp_Nul,
                          :objlongschema :objlsc_Nul;

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
    objlib varchar(128);
    objlib_Nul int(5);
    objname varchar(10);
    objnm_Nul int(5);
    objtype varchar(8);
    objtp_Nul int(5);
  end-pi;

  dcl-s srclbnm char(10);
  dcl-s srcobnm char(10);
  dcl-s srclbob char(21);

// from_colobjaut_file
  dcl-s oalib  char(10);  // Library
  dcl-s oaname char(10);  // Object
  dcl-s oatype char(8);   // Object_type
  dcl-s oausr  char(10);  // user_profile
  dcl-s oaobja char(8);   // object_authority
  dcl-s oaown  char(10);  // object_owner
  dcl-s oagrpn char(10);  // object_group_name
  dcl-s oaopr  char(1);   // operational
  dcl-s oaomgt char(1);   // object_management
  dcl-s oaexs  char(1);   // object_exist
  dcl-s oaread char(1);   // data_read
  dcl-s oaadd  char(1);   // data_add
  dcl-s oaupd  char(1);   // data_update
  dcl-s oadlt  char(1);   // data_delete
  dcl-s oaamgt char(1);   // auth_list_mgmt
  dcl-s oaanam char(10);  // auth_list_name
  dcl-s oaexec char(1);   // data_execute
  dcl-s oaalt  char(1);   // object_alter
  dcl-s oaref  char(1);   // object_ref

  dcl-s stmt varchar(512);

// from current_system_object
  dcl-s system_object_schema varchar(10); // Library
  dcl-s system_object_name  varchar(10);  // Object
  dcl-s object_type         varchar(8);   // Object_type
  dcl-s authorization_name  varchar(10);  // user_profile
  dcl-s object_authority    varchar(12);  // object_authority
  dcl-s owner               varchar(10);  // object_owner
  dcl-s primary_group       varchar(10);  // object_group_name
  dcl-s prigrp_Nul          int(5);       // primary_group_Null_ind
  dcl-s object_operational  varchar(3);   // operational
  dcl-s object_management   varchar(3);   // object_management
  dcl-s object_existence    varchar(3);   // object_exist
  dcl-s data_read           varchar(3);   // data_read
  dcl-s data_add            varchar(3);   // data_add
  dcl-s data_update         varchar(3);   // data_update
  dcl-s data_delete         varchar(3);   // data_delete
  dcl-s autl_mgmt           varchar(3);   // auth_list_mgmt
  dcl-s authorization_list  varchar(10);  // auth_list_name
  dcl-s authl_Nul           int(5);       // auth_list_Nul_ind
  dcl-s data_execute        varchar(3);   // data_execute
  dcl-s object_alter        varchar(3);   // object_alter
  dcl-s object_reference    varchar(3);   // object_ref

  dcl-s cur_stmt varchar(512);

  // Procedure Begin

  srclbnm = 'OAAS101N';
  srcobnm = 'OBJAUT' + %subst(%trim(cur_sysnm) : 3 : 3 ); 
  srclbob = %trimr(srclbnm) + '.' + %trim(srcobnm);

  if objlib_Nul <> -1 and objnm_Nul <> -1 and objtp_Nul <> -1 ;
    // from_colobjaut_file
    stmt = 'select oalib, oaname, oatype, oausr, oaobja, oaown, oagrpn, oaopr, oaomgt, ' +
           'oaexs, oaread, oaadd, oaupd, oadlt, oaamgt, oaanam, oaexec, oaalt, oaref' + 
           ' from ' + %trim(srclbob) +
           ' where oalib = ''' + %trim(objlib) + '''' +
           ' and oaname = ''' + %trim(objname) + '''' +
           ' and oatype = ''' + %trim(objtype) + '''' +
           ' order by oalib, oaname, oatype, oausr' ;
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
      snd-msg '----- Record Begin -----';

      if sqlcod = 0;
        cur_stmt = 'Select ' +
           'system_object_schema, system_object_name, object_type, ' +
           'authorization_name, object_authority,owner, ' +
           'Cast(Coalesce(primary_group, '' '') As Char(10)) as primary_group, ' +
           'object_operational, object_management, object_existence, ' +
           'data_read, data_add, data_update, ' +
           'authorization_list_management, ' +
           'cast(coalesce(authorization_list, '' '') As Char(10)) as authorization_list, ' + 
           'data_delete, data_execute, ' +
           'object_alter, object_reference ' +
           'into :system_object_schema, :system_object_name, :object_type, ' +
           ':authorization_name,            // user_profile ' +
:object_authority,              // object_authority
:owner,                         // object_owner
:primary_group :prigrp_Nul,            // object_group_name
:object_operational,            // operational
:object_management,             // object_management
:object_existence,              // object_exist
:data_read,                     // data_read
:data_add,                      // data_add
:data_update,                   // data_update
:autl_mgmt,                     // data_delete
:authorization_list :authl_Nul, // auth_list_mgmt
:data_delete,                   // auth_list_name
:data_execute,                  // data_execute
:object_alter,                  // object_alter
:object_reference ;             // object_ref'
           
           
           
           
           
           
           
           
           
           
           
           
           
           
           
           
           
           
           
           
           
           'From qsys2.object_privileges ' +
           'Where system_object_schema = ''' + %trim(objlib) + ''' ' +
           'And system_object_name = ''' + %trim(objname) + ''' ' +
           'And object_type = ''' + %trim(objtype) + ''' ' +
           'And authorization_name = ''' + %trim(oausr) + ''' ' +
           'order by system_object_schema, system_object_name, object_type, authorization_name' +
           'into ?'; 
        
        // snd-msg cur_stmt;
        
        exec sql prepare cur_S1 from :cur_stmt;
      
        exec sql declare cur_c1 cursor for cur_S1;
      
        exec sql open cur_c1;
      
        exec sql fetch from cur_c1 into :system_object_schema,          // Library
                                        :system_object_name,            // Object
                                        :object_type,                   // object_type
                                        :authorization_name,            // user_profile
                                        :object_authority,              // object_authority
                                        :owner,                         // object_owner
                                        :primary_group :prigrp_Nul,     // object_group_name
                                        :object_operational,            // operational
                                        :object_management,             // object_management
                                        :object_existence,              // object_exist
                                        :data_read,                     // data_read
                                        :data_add,                      // data_add
                                        :data_update,                   // data_update
                                        :autl_mgmt,                     // data_delete
                                        :authorization_list :authl_Nul, // auth_list_mgmt
                                        :data_delete,                   // auth_list_name
                                        :data_execute,                  // data_execute
                                        :object_alter,                  // object_alter
                                        :object_reference ;             // object_ref
    
        dow sqlcod = 0;
          snd-msg '----- Record Begin -----';
    
          if sqlcod = 0;
            snd-msg 'Curr_library: ' + system_object_schema;
            snd-msg 'File_library: ' + oalib;

            snd-msg 'Curr_object : ' + system_object_name;
            snd-msg 'File_object : ' + oaname;

            snd-msg 'Curr_objtyp : ' + objtype;
            snd-msg 'File_objtyp : ' + oatype;


            snd-msg 'Curr_usrprf : ' + authorization_name;
            snd-msg 'File_usrprf : ' + oausr;

            snd-msg 'Curr_objaut : ' + object_authority;
            snd-msg 'File_objaut : ' + oaobja;

            snd-msg 'Curr_owner  : ' + owner;
            snd-msg 'File_owner  : ' + oaown;

          endif;
      
          exec sql fetch from cur_c1 into :system_object_schema,
                                          :system_object_name,
                                          :object_type,
                                          :authorization_name,            // user_profile
                                          :object_authority,              // object_authority
                                          :owner,                         // object_owner
                                          :primary_group :prigrp_Nul,            // object_group_name
                                          :object_operational,            // operational
                                          :object_management,             // object_management
                                          :object_existence,              // object_exist
                                          :data_read,                     // data_read
                                          :data_add,                      // data_add
                                          :data_update,                   // data_update
                                          :autl_mgmt,                     // data_delete
                                          :authorization_list :authl_Nul, // auth_list_mgmt
                                          :data_delete,                   // auth_list_name
                                          :data_execute,                  // data_execute
                                          :object_alter,                  // object_alter
                                          :object_reference ;             // object_ref
      
        enddo;
      
        exec sql close cur_c1;
    
      endif;

      exec sql fetch from c1 into :oalib,
                                  :oaname,
                                  :oatype,
                                  :oausr, 
                                  :oaobja,
                                  :oaown, 
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

  endif;

end-proc;