**free

ctl-opt actgrp(*caller) option(*srcstmt) ; // Add debug options

dcl-ds cfgsrc qualified template;
  srcseq zoned(6) inz;
  srcdat zoned(6) inz;
  srcdta char(120) inz;
end-ds;

dcl-ds cfgtbl qualified template;
  ctld char(10) inz;
  linktype char(10) inz;
  rmtintneta char(15) inz;
  lclintneta char(15) inz;
  rmtcpname char(10) inz;
end-ds;

dcl-ds srcdtar likeds(cfgsrc);
dcl-ds cfgtblr likeds(cfgtbl);

dcl-s currentParsedLine char(120);
dcl-s pendingCommand char(6000) inz;
dcl-s commandEndsHereThisLine ind inz(*off); // Renamed for clarity: indicates if the *current line* signifies the end o

dcl-s startPos int(10);
dcl-s endPos int(10);
dcl-s length int(10);

dcl-s sqlSuccess ind;
dcl-s isNewCommandStart ind;
// dcl-s currentCommand char(6000) inz; // This variable will now be passed as a parameter to the procedure.

exec sql
   drop table qtemp.cfgtbl if exists;

exec sql
   SET TRANSACTION ISOLATION LEVEL NO COMMIT;

exec sql
   create table qtemp.cfgtbl (
      ctld varchar(10),
      linktype varchar(10),
      rmtintneta varchar(15),
      lclintneta varchar(15),
      rmtcpname varchar(10)
   );

// --- SQL Cursor Declaration and Open ---
exec sql
   declare c1 cursor for
      select SRCSEQ, SRCDAT, SRCDTA from qtemp.qclsrc order by srcseq;

exec sql
   open c1;

// dsply ('Program started. Opening cursor...'); // Debug: Program Start

// --- Main Processing Loop ---
dow sqlcod = 0;
  sqlSuccess = *on;

  exec sql
      fetch next from c1 into :srcdtar.srcseq, :srcdtar.srcdat, :srcdtar.srcdta;

  if sqlcod = 100; // End of data
    sqlSuccess = *off;
    // Process any remaining command in pendingCommand before exiting loop
    if %len(%trim(pendingCommand)) > 0;
      // dsply ('Processing final pending command (EOF)...'); // Debug: Final Command
      ProcessCommand(pendingCommand); // Call the procedure
      clear pendingCommand;
    endif;
  elseif sqlcod <> 0; // Other SQL error
    sqlSuccess = *off;
    // dsply ('SQL FETCH Error! SQLCOD: ' + %char(sqlcod)); // Debug: SQL Error
  endif;

  if sqlSuccess;
    currentParsedLine = %trimr(srcdtar.srcdta); // Trim trailing blanks
    // Check if the current line is a command start (like CRTCTLAPPC)
    isNewCommandStart = *off;
    if %scan('CRTCTLAPPC' : %trim(srcdtar.srcdta)) = 1;
      isNewCommandStart = *on;
    endif;

    // Determine if this line ends the command (no '+' at end)
    // If it ends with '+', it's NOT the end of the command.
    commandEndsHereThisLine = *on; // Assume it ends unless we find a '+'
    If %scan('+':currentParsedLine) > 1;
      startPos = %scan('+':currentParsedLine);
      currentParsedLine = %subst(currentParsedLine : 1 : startPos); // Remove '+'
      commandEndsHereThisLine = *off; // Command continues
      // dsply ('   Line ends with + . Command continues.'); // Debug: Line continues
    else;
      // dsply ('   Line ends without +. Command ends here.'); // Debug: Line ends
    endif;

    // --- Core Logic for Processing and Appending ---
    // If a NEW command starts AND there's something in pendingCommand,
    // it means the PREVIOUS command has just implicitly ended. Process it.
    if isNewCommandStart and %len(%trim(pendingCommand)) > 0;
      ProcessCommand(pendingCommand); // Call the procedure
      clear pendingCommand; // Clear buffer for the new command
    endif;

    // Append the current line to the pending command buffer
    if %len(%trim(pendingCommand)) > 0;
      pendingCommand = %trimr(pendingCommand) + ' ' + %trim(currentParsedLine);
    else;
      pendingCommand = %trim(currentParsedLine); // First line of a new command
    endif;

    // Check for buffer overflow
    if %len(%trimr(pendingCommand)) > %len(pendingCommand);
      pendingCommand = %subst(pendingCommand:1:%len(pendingCommand));
    endif;

    // If the current line is the actual end of a command (no '+')
    // AND there's content in pendingCommand, then process this complete command.
    if commandEndsHereThisLine and %len(%trim(pendingCommand)) > 0;
      ProcessCommand(pendingCommand); // Call the procedure
      clear pendingCommand; // Command processed, clear buffer for next one
    endif;

  endif; // End if sqlSuccess
enddo; // End of DOW loop

// --- Close Cursor ---
exec sql
   close c1;

exec sql
   drop table ddscinfo.cfgtbl if exists;

exec sql
   create table ddscinfo.cfgtbl as (
      select ctld, linktype, rmtintneta, lclintneta, rmtcpname from qtemp.cfgtbl
   ) with data;

*inlr = *on;
return;

// === ProcessCommand Procedure ===**
// This procedure extracts configuration details from a complete command string.
dcl-proc ProcessCommand;
  dcl-pi ProcessCommand;
    inCommand char(6000) const; // Input parameter to receive the full command string
  end-pi;

  // Local variables for this procedure (no need to DCL-S them in main)
  dcl-s localStartPos int(10);
  dcl-s localEndPos int(10);
  dcl-s localLength int(10);

  // Make a copy of the input command to work with (optional, but good practice if inCommand might be modified)
  dcl-s parsedCommand char(6000);
  parsedCommand = inCommand;
  clear cfgtblr; // Clear structure for new data

  // 1. Check if it's an APPC command
  if %scan('CRTCTLAPPC' : %trim(parsedCommand)) = 1;
    // Extract CTLD value
    localStartPos = %scan('CTLD(' : parsedCommand);
    if localStartPos > 0;
      localStartPos = localStartPos + %len('CTLD(');
      localEndPos = %scan(')' : parsedCommand : localStartPos);
      if localEndPos > localStartPos;
        localLength = localEndPos - localStartPos;
        cfgtblr.ctld = %subst(parsedCommand : localStartPos : localLength);
      endif;
    endif;

    // Extract LINKTYPE value
    localStartPos = %scan('LINKTYPE(' : parsedCommand);
    if localStartPos > 0;
      localStartPos = localStartPos + %len('LINKTYPE(');
      localEndPos = %scan(')' : parsedCommand : localStartPos);
      if localEndPos > localStartPos;
        localLength = localEndPos - localStartPos;
        cfgtblr.linktype = %subst(parsedCommand : localStartPos : localLength);
      endif;
    endif;

    // Extract RMTINTNETA value
    localStartPos = %scan('RMTINTNETA(' : parsedCommand);
    if localStartPos > 0;
      localStartPos = localStartPos + %len('RMTINTNETA(');
      localEndPos = %scan(')' : parsedCommand : localStartPos);
      if localEndPos > localStartPos;
        localLength = localEndPos - localStartPos;
        cfgtblr.rmtintneta = %subst(parsedCommand : localStartPos : localLength);
      endif;
    endif;

    // Extract LCLINTNETA value
    localStartPos = %scan('LCLINTNETA(' : parsedCommand);
    if localStartPos > 0;
      localStartPos = localStartPos + %len('LCLINTNETA(');
      localEndPos = %scan(')' : parsedCommand : localStartPos);
      if localEndPos > localStartPos;
        localLength = localEndPos - localStartPos;
        cfgtblr.lclintneta = %subst(parsedCommand : localStartPos : localLength);
      endif;
    endif;

    // Extract RMTCPNAME value
    localStartPos = %scan('RMTCPNAME(' : parsedCommand);
    if localStartPos > 0;
      localStartPos = localStartPos + %len('RMTCPNAME(');
      localEndPos = %scan(')' : parsedCommand : localStartPos);
      if localEndPos > localStartPos;
        localLength = localEndPos - localStartPos;
        cfgtblr.rmtcpname = %subst(parsedCommand : localStartPos : localLength);
      endif;
    endif;

    // --- Filter and Display / Insert ---
    if %trim(cfgtblr.linktype) = '*HPRIP' and
         %trim(cfgtblr.rmtintneta) <> '' and
         %trim(cfgtblr.lclintneta) <> '';

      // dsply ('--- Parsed APPC Config (MATCH) ---'); // Debug: Match found
      // dsply ('CTLD: ' + %trim(cfgtblr.ctld));
      // dsply ('LINKTYPE: ' + %trim(cfgtblr.linktype));
      // dsply ('RMTINTNETA: ' + %trim(cfgtblr.rmtintneta));
      // dsply ('LCLINTNETA: ' + %trim(cfgtblr.lclintneta));
      // dsply ('RMTCPNAME: ' + %trim(cfgtblr.rmtcpname));
      // dsply ('--------------------------');

      exec sql
            INSERT INTO qtemp.cfgtbl (CTLD, LINKTYPE, RMTINTNETA, LCLINTNETA, RMTCPNAME)
            VALUES (:cfgtblr.ctld, :cfgtblr.linktype, :cfgtblr.rmtintneta, :cfgtblr.lclintneta, :cfgtblr.rmtcpname);
      if sqlcod <> 0;
        snd-msg ('SQL INSERT Error! SQLCOD: ' + %char(sqlcod));
      else;
        snd-msg ('SQL INSERT Successful.');
      endif;

    else;
      // dsply ('--- Parsed APPC Config (NO MATCH for filter) ---'); // Debug: No match
      // dsply ('   CTLD: ' + %trim(cfgtblr.ctld));
      // dsply ('   LINKTYPE: ' + %trim(cfgtblr.linktype));
      // dsply ('   RMTINTNETA: ' + %trim(cfgtblr.rmtintneta));
      // dsply ('   LCLINTNETA: ' + %trim(cfgtblr.lclintneta));
      // dsply ('--------------------------');
    endif;

  else;
    // dsply ('ProcessCommand: Not a CRTCTLAPPC command.'); // Debug: Not APPC
  endif;

end-proc; // End of ProcessCommand procedure
