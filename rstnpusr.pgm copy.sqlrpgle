**FREE
//
// 呼叫時需要輸入磁帶機名稱，可用TAPXX或是TAPMLBXX
// 查詢 qsys2.user_info_basic，先取得 no_password_indicator 為 YES 的帳號清單
// 查詢 table ( qsys2.qsys2.object_statistics ) 得到 save_volume 的資訊
// 組合指令 RSTUSRPRF 指定 VOLUME 進行倒檔
// 
ctl-opt option(*srcstmt) dftactgrp(*no);
// Declare User input Tape device
dcl-pi *n;
  tapdev char(8);
end-pi;
// Declare data structures
DCL-DS nonpwusr QUALIFIED;
  usrprf varchar(10);
  nopwd  varchar(3);
END-DS;
//
DCL-DS usrsavdev QUALIFIED;
  objname     varchar(10);
  objtype     varchar(8);
  save_device varchar(5);
  save_volume varchar(71);
  save_seqnum packed(10:0);
END-DS;
// Declare null indicators for usrsavdev fields
dcl-s sav_devNulInd int(5) INZ;
dcl-s sav_volNulInd int(5) INZ;
dcl-s sav_seqnNulInd int(5) INZ;
//
dcl-pr syscmd int(10) ExtProc('system');
  *n Pointer Value Options(*String);
end-pr;
//
dcl-s cmdstr char(500) inz;
dcl-s returnCode int(5) inz;
// Declare cursor for non-password users
EXEC SQL
  DECLARE nonpwusr_cur CURSOR FOR
    SELECT authorization_name,
           no_password_indicator
    FROM qsys2.user_info_basic
    // Test case: where authorization_name = 'IBMECS';
    WHERE NO_PASSWORD_INDICATOR = 'YES';

// Open the cursor
EXEC SQL
  OPEN nonpwusr_cur;

// Fetch the first record
EXEC SQL
  FETCH NEXT FROM nonpwusr_cur
  INTO :nonpwusr.usrprf,
       :nonpwusr.nopwd;

// Loop through non-password user profiles
DOW SQLCOD = 0;

  snd-msg '----- Record Begin -----';
  snd-msg 'User Profile : ' + %trim(nonpwusr.usrprf) +
          ' (No Password: ' + %trim(nonpwusr.nopwd) + ')';

  // Retrieve object statistics for the current user profile
  EXEC SQL
    SELECT objname,
           objtype,
           save_device,
           save_volume,
           save_sequence_number
    INTO :usrsavdev.objname,
         :usrsavdev.objtype,
         :usrsavdev.save_device :sav_devNulInd,
         :usrsavdev.save_volume :sav_volNulInd,
         :usrsavdev.save_seqnum :sav_seqnNulInd
    FROM TABLE(
           qsys2.object_statistics(
             object_schema => 'QSYS',
             objtypelist => '*USRPRF',
             object_name => :nonpwusr.usrprf
           )
         );

  // Check SQLCOD after the SELECT statement
  IF SQLCOD = 0;
    // Object statistics found
    //
    snd-msg '  Object Name: ' + %trim(usrsavdev.objname);
    snd-msg '  Object Type: ' + %trim(usrsavdev.objtype);
    // Restore *usrprf
    cmdstr = 'RSTUSRPRF DEV(' + %trim(tapdev) +
      ') USRPRF(' + %trim(usrsavdev.objname) +
      ') VOL(' + %trim(usrsavdev.save_volume) +
      ') SEQNBR(' + %trim(%char(usrsavdev.save_seqnum)) +
      ') ALWOBJDIF(*ALL) SECDTA(*USRPRF)';
    snd-msg 'Executed command: ' + cmdstr;
    returnCode = syscmd(cmdstr);
    if returnCode <> 0;
      snd-msg 'sqlcod: ' + %char(sqlcod);
      snd-msg '--- Restore *usrprf error ---';
    endif;
    // Restore *pvtaut
    cmdstr = 'RSTUSRPRF DEV(' + %trim(tapdev) +
      ') USRPRF(' + %trim(usrsavdev.objname) +
      ') VOL(' + %trim(usrsavdev.save_volume) +
      ') SEQNBR(' + %trim(%char(usrsavdev.save_seqnum)) +
      ') ALWOBJDIF(*ALL) SECDTA(*PVTAUT)';
    snd-msg 'Executed command: ' + cmdstr;
    returnCode = syscmd(cmdstr);
    if returnCode <> 0;
      snd-msg 'sqlcod: ' + %char(sqlcod);
      snd-msg '--- Restore *pvtaut error ---';
    endif;
    // Restore *pwdgrp
    cmdstr = 'RSTUSRPRF DEV(' + %trim(tapdev) +
      ') USRPRF(' + %trim(usrsavdev.objname) +
      ') VOL(' + %trim(usrsavdev.save_volume) +
      ') SEQNBR(' + %trim(%char(usrsavdev.save_seqnum)) +
      ') ALWOBJDIF(*ALL) SECDTA(*PWDGRP)';
    snd-msg 'Executed command: ' + cmdstr;
    returnCode = syscmd(cmdstr);
    if returnCode <> 0;
      snd-msg 'sqlcod: ' + %char(sqlcod);
      snd-msg '--- Restore *pwdgrp error ---';
    endif;
    //
    // Check for null indicators before displaying
    // IF sav_devNulInd = 0;
    //   snd-msg '  Save Device: ' + %trim(usrsavdev.save_device);
    // ELSE;
    //   snd-msg '  Save Device: *NULL';
    // ENDIF;
	// 
    // IF sav_volNulInd = 0;
    //   snd-msg '  Save Volume: ' + %trim(usrsavdev.save_volume);
    // ELSE;
    //   snd-msg '  Save Volume: *NULL';
    // ENDIF;
	// 
    // IF sav_seqnNulInd = 0;
    //   snd-msg '  Save SeqNum: ' + %char(usrsavdev.save_seqnum);
    // ELSE;
    //   snd-msg '  Save SeqNum: *NULL';
    // ENDIF;

  ELSEIF SQLCOD = 100;
    // No rows found for object statistics (user profile might not have save device info)
    snd-msg '  No object statistics found for this user profile.';
  ELSE;
    // Other SQL error
    snd-msg '  Error retrieving object statistics (SQLCOD: ' + %char(SQLCOD) + ')';
  ENDIF;

  snd-msg '----- Record End -----';

  // Fetch the next record from the non-password user cursor
  EXEC SQL
    FETCH NEXT FROM nonpwusr_cur
    INTO :nonpwusr.usrprf,
         :nonpwusr.nopwd;

ENDDO;

// Close the cursor
EXEC SQL
  CLOSE nonpwusr_cur;
//
*INLR = *ON;
RETURN;
