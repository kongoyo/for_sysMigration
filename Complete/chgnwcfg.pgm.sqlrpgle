**FREE
// CALL PGM(STEVE/CHGNWCFG)
// 
ctl-opt option(*srcstmt) dftactgrp(*no);
//
dcl-s logsts char(1); // T: Log Title  C: Log Continue  E: Log Ending
dcl-s logtxt char(600);
dcl-s cur_sysnm char(8);
// Main procedure

clear logtxt;
logsts = 'T';
writelog(logsts : logtxt);

clear logtxt;
logsts = 'C';
logtxt = 'Remote system process start';
writelog(logsts:logtxt);
// exec sql values current server into :cur_sysnm;
// for Test Only
cur_sysnm = 'KSF03N';
// for Test Only
exec sql set option commit = *none ;

// do something from here
for_othsys(cur_sysnm);
// to here.

clear logtxt;
logsts = 'C';
logtxt = 'Remote system process end';
writelog(logsts : logtxt);

clear logtxt;
logsts = 'C';
logtxt = 'Local system process start';
writelog(logsts : logtxt);

// do something from here
for_cursys(cur_sysnm);
// to here.

clear logtxt;
logsts = 'C';
logtxt = 'Local system process end';
writelog(logsts : logtxt);

clear logtxt;
logsts = 'E';
writelog(logsts : logtxt);
*inlr = *on;
return;

dcl-proc for_cursys;
    dcl-pi *n;
        cur_sysnm char(8) const;
    end-pi;
    dcl-ds curroute qualified;
        route_type char(8);
        route_destination char(15);
        subnet_mask char(15);
        next_hop char(15);
    end-ds;
    dcl-ds cursysip qualified;
        internet_address char(45);
        subnet_mask char(15);
        line_description char(10);
        associated_local_interface char(15);
        autostart char(3);
        preferred_interface_list char(159);
    end-ds;
    dcl-ds curhosttbl qualified;
        internet char(15);
        hostnme1 char(255);
        hostnme2 char(255);
    end-ds;
    dcl-ds curlind qualified;
        line_description char(10);
    end-ds;
    dcl-ds orgrdb qualified;
        rdb_name char(18);
        rdb_alias char(18);
        remote_location_type char(4);
        remote_location char(254);
        preferred_authentication char(10);
        lower_authentication char(11);
        encryption_algorithm char(4);
        secure_connection char(5);
    end-ds;
    dcl-ds orgroute likeds(curroute);
    dcl-ds orgsysip likeds(cursysip);
    dcl-ds orghosttbl likeds(curhosttbl);

    dcl-s stmt char(500);
    dcl-s org_sysnm char(8);
    dcl-s startPos int(10);
    dcl-s option char(3); // lcl: for local   rmt: for remote 
    dcl-s cmdstr char(500);
    dcl-s returnCode int(5);
    // 
    clear logtxt;
    logsts = 'C';
    logtxt = '--- Current System is ' + %trim(cur_sysnm) + ' ---';
    writelog(logsts : logtxt);

    // gather current route info and save to a table
    clear logtxt;
    logsts = 'C';
    logtxt = '-  gather current route info and save to a table';
    writelog(logsts : logtxt);

    // stmt = 'create table ' + %trim(objlongschema)+ '.' + %trim(objname) + ' as (' +
    //     'select * from qsys2.netstat_interface_info' +
    //     ') with data';
    // exec sql prepare precursys from :stmt;
    // exec sql execute precursys;
    clear stmt;
    stmt = 'drop table ddscinfo.currout' + %subst(%trim(cur_sysnm) : 3 : 3) + ' if exists';
    exec sql prepare precurrout from :stmt;
    exec sql execute precurrout;

    clear stmt;
    stmt = 'create table ddscinfo.currout' + %subst(%trim(cur_sysnm) : 3 : 3) + ' as (' +
                        'select * from qsys2.netstat_route_info' +
                        ') with data';
    exec sql prepare precurrout from :stmt;
    exec sql execute precurrout;

    // exec sql drop table ddscinfo.curroute if exists;
    // exec sql create table ddscinfo.curroute as (
    //                     select * from qsys2.netstat_route_info
    //                     ) with data;
    // exec sql commit;

    // remove current systm route from table (route_type varchar(8) 'DFTROUTE' or 'NET')
    // select * from ddscinfo.curroute where route_type <> 'DIRECT';
    // CL: RMVTCPRTE RTEDEST('xx.xx.xx.xx') SUBNETMASK('xx.xx.xx.0') NEXTHOP('xx.xx.xx.xx')
    clear logtxt;
    logsts = 'C';
    logtxt = '-  remove current systm route from table';
    writelog(logsts : logtxt);

    clear stmt;
    stmt = 'select route_type, route_destination, subnet_mask, next_hop' + 
                ' from ddscinfo.currout' + %subst(%trim(cur_sysnm) : 3 : 3) + 
                ' where route_type <> ''DIRECT''';
    exec sql prepare precurrout from :stmt;
    exec sql declare curroute cursor for precurrout;
    exec sql open curroute;
    exec sql fetch from curroute into :curroute;
    // exec sql declare curroute cursor for 
    //             select route_type, route_destination, subnet_mask, next_hop 
    //             from ddscinfo.curroute where route_type <> 'DIRECT';
    // exec sql open curroute;
    // exec sql fetch from curroute into :curroute;
    dow sqlcod = 0;
        if sqlcod = 0;
        // snd-msg curroute.route_type;
        // do something from here
            if curroute.route_type = 'DFTROUTE';
                option = 'lcl';
                cmdstr = 'RMVTCPRTE RTEDEST(*' + %trim(curroute.route_type) + 
                            ') SUBNETMASK(*NONE) ' +
                            'NEXTHOP(''' + %trim(curroute.next_hop) + ''')';
                process_Command(option:cmdstr:returnCode);
                clear cmdstr;
                clear curroute.route_destination;
                clear curroute.subnet_mask;
                clear curroute.next_hop;
            elseif curroute.route_type = 'NET';
                option = 'lcl';
                cmdstr = 'RMVTCPRTE RTEDEST(''' + %trim(curroute.route_destination) + 
                            ''') SUBNETMASK(''' + %trim(curroute.subnet_mask) + 
                            ''') NEXTHOP(''' + %trim(curroute.next_hop) + ''')';
                process_Command(option:cmdstr:returnCode);
                clear cmdstr;
                clear curroute.route_destination;
                clear curroute.subnet_mask;
                clear curroute.next_hop;
            else;
            endif;
        // to here
            exec sql fetch from curroute into :curroute;
        endif;
    enddo;
    exec sql close curroute;

    //
    // add original system route from table (route_type varchar(8) 'DFTROUTE' or 'NET')
    // CL: ADDTCPRTE RTEDEST('xx.xx.xx.xx') SUBNETMASK('xx.xx.xx.0') NEXTHOP('xx.xx.xx.xx')
    clear logtxt;
    logsts = 'C';
    logtxt = '-  add original system route from table';
    writelog(logsts : logtxt);

    clear stmt;
    stmt = 'select route_type, route_destination, subnet_mask, next_hop' + 
                ' from ddscinfo.orgrout' + %subst(%trim(cur_sysnm) : 3 : 3) + 
                ' where route_type <> ''DIRECT''';
    // snd-msg %trim(stmt);
    exec sql prepare preorgrout from :stmt;
    exec sql declare orgroute cursor for preorgrout;
    exec sql open orgroute;
    exec sql fetch from orgroute into :orgroute;
    dow sqlcod = 0;
        if sqlcod = 0;
        // snd-msg orgroute.route_type;
        // do something from here
            if orgroute.route_type = 'DFTROUTE';
                option = 'lcl';
                cmdstr = 'ADDTCPRTE RTEDEST(*' + %trim(orgroute.route_type) + 
                            ') SUBNETMASK(*NONE) ' +
                            'NEXTHOP(''' + %trim(orgroute.next_hop) + ''')';
                process_Command(option:cmdstr:returnCode);
                clear cmdstr;
                clear orgroute.route_destination;
                clear orgroute.subnet_mask;
                clear orgroute.next_hop;
            elseif orgroute.route_type = 'NET';
                option = 'lcl';
                cmdstr = 'ADDTCPRTE RTEDEST(''' + %trim(orgroute.route_destination) + 
                            ''') SUBNETMASK(''' + %trim(orgroute.subnet_mask) + 
                            ''') NEXTHOP(''' + %trim(orgroute.next_hop) + ''')';
                process_Command(option:cmdstr:returnCode);
                clear cmdstr;
                clear orgroute.route_destination;
                clear orgroute.subnet_mask;
                clear orgroute.next_hop;
            else;
            endif;
        // to here
            exec sql fetch from orgroute into :orgroute;
        endif;
    enddo;
    exec sql close orgroute;

    // gather current ip address and save to a table
    clear logtxt;
    logsts = 'C';
    logtxt = '-  gather current ip address and save to a table';
    writelog(logsts : logtxt);

    clear stmt;
    stmt = 'drop table ddscinfo.cursysi' + %subst(%trim(cur_sysnm) : 3 : 3) + ' if exists';
    exec sql prepare precursysip from :stmt;
    exec sql execute precursysip;

    clear stmt;
    stmt = 'create table ddscinfo.cursysi' + %subst(%trim(cur_sysnm) : 3 : 3) + ' as (' +
                        'select * from qsys2.netstat_interface_info' +
                        ') with data';
    exec sql prepare precursysip from :stmt;
    exec sql execute precursysip;

    // stop all current ip address (LIND or *VIRTUALIP)
    // select * from ddscinfo.cursysip where line_description <> '*LOOPBACK';
    // CL: ENDTCPIFC INTNETADR('xx.xx.xx.xx')
    // remove current ip address
    // CL: RMVTCPIFC INTNETADR('xx.xx.xx.xx')
    clear logtxt;
    logsts = 'C';
    logtxt = '-  Stop and remove all current ip address';
    writelog(logsts : logtxt);


    clear stmt;
    stmt = 'select internet_address,' + 
            'coalesce(subnet_mask,''*NONE'') as subnet_mask,' + 
            'line_description,' + 
            'coalesce(associated_local_interface,''*NONE'') as associated_local_interface,' + 
            'autostart,' + 
            'coalesce(preferred_interface_list,''*NONE'') as preferred_interface_list ' +
            'from ddscinfo.cursysi' + %subst(%trim(cur_sysnm) : 3 : 3) + ' ' +
            'where line_description <> ''*LOOPBACK''';
    // snd-msg %trim(stmt);
    exec sql prepare precursysip from :stmt;
    exec sql declare cursysip cursor for precursysip;
    exec sql open cursysip;
    exec sql fetch from cursysip into :cursysip;

    dow sqlcod = 0;
        if sqlcod = 0;
            // snd-msg cursysip.internet_address;
            // do something from here
            option = 'lcl';
            cmdstr = 'ENDTCPIFC INTNETADR(''' + %trim(cursysip.internet_address) + ''')';
            process_Command(option:cmdstr:returnCode);

            option = 'lcl';
            cmdstr = 'RMVTCPIFC INTNETADR(''' + %trim(cursysip.internet_address) + ''')';
            process_Command(option:cmdstr:returnCode);

            clear cmdstr;
            clear cursysip.preferred_interface_list;
            clear cursysip.associated_local_interface;
            clear cursysip.autostart;
            clear cursysip.subnet_mask;
            clear cursysip.line_description;
            clear cursysip.internet_address;
            // to here
            exec sql fetch from cursysip into :cursysip;
        endif;
    enddo;
    exec sql close cursysip;

    // vary off line description
    clear logtxt;
    logsts = 'C';
    logtxt = '-  Vary off line description';
    writelog(logsts : logtxt);

    clear stmt;
    stmt = 'select distinct(line_description) ' +
            'from ddscinfo.cursysi' + %subst(%trim(cur_sysnm) : 3 : 3) + ' ' +
            'where line_description <> ''*LOOPBACK''';
    // snd-msg %trim(stmt);
    exec sql prepare precurlind from :stmt;
    exec sql declare curlind cursor for precurlind;
    exec sql open curlind;
    exec sql fetch from curlind into :curlind;

    dow sqlcod = 0;
        if sqlcod = 0;
            // snd-msg cursysip.internet_address;
            // do something from here
            if curlind.line_description <> '*VIRTUALIP';
                option = 'lcl';
                cmdstr = 'VRYCFG CFGOBJ(' + %trim(curlind.line_description) + ') CFGTYPE(*LIN) STATUS(*OFF) FRCVRYOFF(*YES)';
                process_Command(option:cmdstr:returnCode);
            endif;
            clear cmdstr;
            clear curlind.line_description;
            // to here
            exec sql fetch from curlind into :curlind;
        endif;
    enddo;
    exec sql close curlind;

    // remove host table entry for current system
    // select trim(internet), trim(hostnme1), trim(hostnme2) from qusrsys.qatochost;
    clear logtxt;
    logsts = 'C';
    logtxt = '-  Remove host table entry for current system';
    writelog(logsts : logtxt);

    clear stmt;
    stmt = 'drop table ddscinfo.curhost' + %subst(%trim(cur_sysnm) : 3 : 3) + ' if exists';
    exec sql prepare precurhosttbl from :stmt;
    exec sql execute precurhosttbl;

    clear stmt;
    stmt = 'create table ddscinfo.curhost' + %subst(%trim(cur_sysnm) : 3 : 3) + ' as (' +
                        'select * from qusrsys.qatochost' +
                        ') with data';
    exec sql prepare precurhosttbl from :stmt;
    exec sql execute precurhosttbl;

    stmt = 'select trim(internet), trim(hostnme1), trim(hostnme2) ' + 
            'from ddscinfo.curhost' + %subst(%trim(cur_sysnm) : 3 : 3) + ' ' + 
            'where trim(hostnme1) = ''' + %trim(cur_sysnm) + ''' ' + 
            'or trim(hostnme2) = ''' + %trim(cur_sysnm) + '''';
    exec sql prepare precurhosttbl from :stmt;
    exec sql declare curhosttbl cursor for precurhosttbl;
    exec sql open curhosttbl;
    exec sql fetch from curhosttbl into :curhosttbl;
    dow sqlcod = 0;
        if sqlcod = 0;
        // snd-msg curhosttbl.internet;
        // do something from here
            option = 'lcl';
            cmdstr = 'RMVTCPHTE INTNETADR(''' + %trim(curhosttbl.internet) + ''')';
            process_Command(option:cmdstr:returnCode);
            clear cmdstr;
            clear curhosttbl.internet;
            clear curhosttbl.hostnme1;
            clear curhosttbl.hostnme2;
            exec sql fetch from curhosttbl into :curhosttbl;
        endif;
    enddo;
    exec sql close curhosttbl;

    // change host table entry for original system
    clear logtxt;
    logsts = 'C';
    logtxt = '-  Change host table entry for original system';
    writelog(logsts : logtxt);

    org_sysnm = %scanrpl('N' : '' : %trim(cur_sysnm));
    stmt = 'select trim(internet), trim(hostnme1), trim(hostnme2) ' + 
            'from ddscinfo.orghost' + %subst(%trim(cur_sysnm) : 3 : 3) + ' ' +
            'where trim(hostnme1) = ''' + %trim(org_sysnm) + ''' ' + 
            'or trim(hostnme2) = ''' + %trim(org_sysnm) + '''';
    exec sql prepare preorghosttbl from :stmt;
    exec sql declare orghosttbl cursor for preorghosttbl;
    exec sql open orghosttbl;
    exec sql fetch from orghosttbl into :orghosttbl;
    dow sqlcod = 0;
        if sqlcod = 0;
        // do something from here
            option = 'lcl';
            cmdstr = 'CHGTCPHTE INTNETADR(''' + %trim(orghosttbl.internet) + ''')' +
                    ' HOSTNAME(''' + %trim(orghosttbl.hostnme1) + ''' ' + 
                    '''' + %trim(orghosttbl.hostnme2) + ''')';
            process_Command(option:cmdstr:returnCode);
            clear cmdstr;
            clear orghosttbl.hostnme1;
            clear orghosttbl.hostnme2;
            clear orghosttbl.internet;
            exec sql fetch from orghosttbl into :orghosttbl;
        endif;
    enddo;

    // change to original domain info
    // CL: CHGTCPDMN HOSTNAME('XXX')
    clear logtxt;
    logsts = 'C';
    logtxt = '-  Change to original domain info';
    writelog(logsts : logtxt);
    
    clear cmdstr;
    cmdstr = 'CHGTCPDMN HOSTNAME(''' + %trim(org_sysnm) + ''')';
    process_Command(option:cmdstr:returnCode);
    
    // change to original rdb directory entry
    // select * from qsys2.rdb_entry_info where remote_location = '*LOCAL';
    // CL: RMVRDBDIRE RDB(xxx)
    clear logtxt;
    logsts = 'C';
    logtxt = '-  Change to original rdb directory entry';
    writelog(logsts : logtxt);

    clear stmt;
    stmt = 'Select RDB_NAME, ' +
                'Coalesce(RDB_ALIAS, '''') As RDB_ALIAS, ' +
                'REMOTE_LOCATION_TYPE, ' +
                'REMOTE_LOCATION, ' +
                'PREFERRED_AUTHENTICATION, ' +
                'LOWER_AUTHENTICATION, ' +
                'ENCRYPTION_ALGORITHM, ' +
                'SECURE_CONNECTION ' +
                'From QSYS2.RDB_ENTRY_INFO';
    exec sql prepare preorgrdb from :stmt;
    exec sql declare orgrdb cursor for preorgrdb;
    exec sql open orgrdb;
    exec sql fetch from orgrdb into :orgrdb;
    dow sqlcod = 0;
        if sqlcod = 0;
        // do something from here
            if orgrdb.remote_location_type = '*LOCAL';
                option = 'lcl';
                cmdstr = 'RMVRDBDIRE RDB(''' + %trim(orgrdb.rdb_name) + ''')';
                process_Command(option:cmdstr:returnCode);
                clear cmdstr;
                clear orgrdb.rdb_name;
                clear orgrdb.rdb_alias;
                clear orgrdb.remote_location_type;
                clear orgrdb.remote_location;
                clear orgrdb.preferred_authentication;
                clear orgrdb.lower_authentication;
                clear orgrdb.encryption_algorithm;
                clear orgrdb.secure_connection;
                exec sql fetch from orgrdb into :orgrdb;
            endif;
        endif;
    enddo;
    exec sql close orgrdb;

    // add original ip address and start
    // CL: ADDTCPIFC INTNETADR('xx.xx.xx.xx') LIND(xxxxx *NONE) SUBNETMASK('xx.xx.xx.0')
    clear logtxt;
    logsts = 'C';
    logtxt = '-  Add original ip address and start';
    writelog(logsts : logtxt);

    clear stmt;
    stmt = 'select internet_address,' + 
            'coalesce(subnet_mask,''*NONE'') as subnet_mask,' + 
            'line_description,' + 
            'coalesce(associated_local_interface,''*NONE'') as associated_local_interface,' + 
            'autostart,' + 
            'coalesce(preferred_interface_list,''*NONE'') as preferred_interface_list ' +
            'from ddscinfo.orgsysi' + %subst(%trim(cur_sysnm) : 3 : 3) + ' ' +
            'where line_description <> ''*LOOPBACK''';
    exec sql prepare preorgsysip from :stmt;
    exec sql declare orgsysip cursor for preorgsysip;
    exec sql open orgsysip;
    exec sql fetch from orgsysip into :orgsysip;
    dow sqlcod = 0;
        if sqlcod = 0;
            // snd-msg orgsysip.internet_address;
            // do something from here
            option = 'lcl';
            cmdstr = 'ADDTCPIFC INTNETADR(''' + %trim(orgsysip.internet_address) + ''')' +
                    ' LIND(' + %trim(orgsysip.line_description) + ')' +
                    ' SUBNETMASK(''' + %trim(orgsysip.subnet_mask) + ''')' +
                    ' AUTOSTART(*' + %trim(orgsysip.autostart) + ')';
            if %len(%trim(orgsysip.preferred_interface_list)) > 0;
                orgsysip.preferred_interface_list = %scanrpl(' ' : ''' ''' : %trim(orgsysip.preferred_interface_list));
                cmdstr = %trimr(cmdstr) + ' PREFIFC(''' + %trim(orgsysip.preferred_interface_list) + ''')';
            endif;
            if %len(%trim(orgsysip.associated_local_interface)) > 0;
                cmdstr = %trimr(cmdstr) + ' LCLIFC(''' + %trim(orgsysip.associated_local_interface) + ''')';
            endif;
            process_Command(option:cmdstr:returnCode);

            option = 'lcl';
            cmdstr = 'STRTCPIFC INTNETADR(''' + %trim(orgsysip.internet_address) + ''')';
            process_Command(option:cmdstr:returnCode);
            clear cmdstr;
            clear orgsysip.preferred_interface_list;
            clear orgsysip.associated_local_interface;
            clear orgsysip.autostart;
            clear orgsysip.subnet_mask;
            clear orgsysip.line_description;
            clear orgsysip.internet_address;
            // to here
            exec sql fetch from orgsysip into :orgsysip;
        endif;
    enddo;

    // change to original system name
    // CL: CHGNETA SYSNAME(xxx) LCLCPNAME(xxx) LCLLOCNAME(xxx) NWSDOMAIN(xxx)
    clear logtxt;
    logsts = 'C';
    logtxt = '-  change to original system name';
    writelog(logsts : logtxt);

    option = 'lcl';
    cmdstr = 'CHGNETA SYSNAME(''' + %trim(org_sysnm) + ''')' +
            ' LCLCPNAME(''' + %trim(org_sysnm) + ''')' +
            ' LCLLOCNAME(''' + %trim(org_sysnm) + ''')' +
            ' NWSDOMAIN(''' + %trim(org_sysnm) + ''')';
    process_Command(option:cmdstr:returnCode);

    // pwrdwnsys system
    // CL: PWRDWNSYS OPTION(*IMMED) RESTART(*YES) 
    option = 'lcl';
    cmdstr = 'PWRDWNSYS OPTION(*IMMED) RESTART(*YES)';
    process_Command(option:cmdstr:returnCode);

    return;
end-proc;

dcl-proc for_othsys;
    dcl-pi *n;
        cur_sysnm char(8);
    end-pi;
    dcl-ds cfgsrc qualified;
        srcseq zoned(6);
        srcdta char(120);
    end-ds;
    dcl-s tgt_ctld char(10);
    dcl-s tgt_rmtintneta char(15);
    dcl-s tgt_lclintneta char(15);
    dcl-s tgt_rmtcpname char(10);
    dcl-s parsedCommand char(1000);
    dcl-s pendingCommand char(1000);
    dcl-s startPos int(10);
    dcl-s endPos int(10);
    dcl-s length int(10);

    dcl-pr syscmd int(10) ExtProc('system');
        *n Pointer Value Options(*String);
    end-pr;
    dcl-s option char(3); // lcl: for local   rmt: for remote 
    dcl-s cmdstr char(500);
    dcl-s returnCode int(5);
    dcl-s logsts char(1); // T: Log Title  C: Log Continue  E: Log Ending
    dcl-s logtxt char(600);
    dcl-s stmt char(500);
    //
    option = 'lcl';
    cmdstr = 'DLTOBJ OBJ(QTEMP/CFGSRC) OBJTYPE(*FILE)';
    process_Command(option:cmdstr:returnCode);
    returnCode = syscmd(cmdstr);

    option = 'lcl';
    cmdstr = 'CRTSRCPF FILE(QTEMP/CFGSRC) IGCDTA(*YES)';
    process_Command(option:cmdstr:returnCode);
    returnCode = syscmd(cmdstr);

    option = 'lcl';
    cmdstr = 'RTVCFGSRC CFGD(*ALL) CFGTYPE(*CTLD) SRCFILE(QTEMP/CFGSRC)';
    process_Command(option:cmdstr:returnCode);
    returnCode = syscmd(cmdstr);


    clear logtxt;
    logsts = 'C';
    logtxt = '-  Configure local EE ctld';
    writelog(logsts : logtxt);

    exec sql declare cfgsrc cursor for select srcseq, srcdta from qtemp.cfgsrc order by srcseq;
    exec sql open cfgsrc;
    exec sql fetch next from cfgsrc into :cfgsrc.srcseq, :cfgsrc.srcdta;
    dow sqlcod = 0;
        if sqlcod = 0;
            if %scan('/*': %trimr(cfgsrc.srcdta)) = 0;
                parsedCommand = %trimr(cfgsrc.srcdta);
                if %scan('+' : parsedCommand) > 0;
                    parsedCommand = %scanrpl('+':'':parsedCommand);
                    pendingCommand = %trimr(pendingCommand) + %trim(parsedCommand);
                else;
                    pendingCommand = %trimr(pendingCommand) + %trim(parsedCommand);
                    if %scan('LINKTYPE(*HPRIP)' : %trim(pendingCommand)) > 1;
                        // Extract CTLD value
                        StartPos = %scan('CTLD(' : pendingCommand);
                        if StartPos > 0;
                            StartPos = StartPos + %len('CTLD(');
                            endPos = %scan(')' : pendingCommand : StartPos);
                            if endPos > StartPos;
                                length = endPos - StartPos;
                                tgt_ctld = %subst(pendingCommand : StartPos : length);
                            endif;
                        endif;
                        // Extract RMTINTNETA value
                        startPos = %scan('RMTINTNETA(' : pendingCommand);
                        if startPos > 0;
                            startPos = startPos + %len('RMTINTNETA(');
                            endPos = %scan(')' : pendingCommand : startPos);
                            if endPos > startPos;
                                length = endPos - startPos;
                                tgt_rmtintneta = %subst(pendingCommand : startPos : length);
                            endif;
                        endif;
                        // Extract LCLINTNETA value
                        startPos = %scan('LCLINTNETA(' : pendingCommand);
                        if startPos > 0;
                            startPos = startPos + %len('LCLINTNETA(');
                            endPos = %scan(')' : pendingCommand : startPos);
                            if endPos > startPos;
                                length = endPos - startPos;
                                tgt_lclintneta = %subst(pendingCommand : startPos : length);
                            endif;
                        endif;
                        // Extract RMTCPNAME value
                        startPos = %scan('RMTCPNAME(' : pendingCommand);
                        if startPos > 0;
                            startPos = startPos + %len('RMTCPNAME(');
                            endPos = %scan(')' : pendingCommand : startPos);
                            if endPos > startPos;
                                length = endPos - startPos;
                                tgt_rmtcpname = %subst(pendingCommand : startPos : length);
                            endif;
                        endif;
                        // do something from here
                        // clear logtxt;
                        // logsts = 'C';
                        // logtxt = %trim(tgt_ctld) + ' ' + %trim(tgt_rmtintneta) + ' ' + %trim(tgt_lclintneta) + ' ' + %trim(tgt_rmtcpname);
                        // writelog(logsts : logtxt);

                        // Vary off local ctld
                        option = 'lcl';
                        cmdstr = 'VRYCFG CFGOBJ(' + %trim(tgt_ctld) + ') CFGTYPE(*CTL) STATUS(*OFF) FRCVRYOFF(*YES)';
                        process_Command(option:cmdstr:returnCode);
                        // Change ctld local internet address
                        cur_sysnm = %scanrpl('N' : '' : %trim(cur_sysnm)); 
                        stmt = 'select trim(internet) from qusrsys.qatochost ' +
                                'where trim(hostnme1) = ''' + %trim(cur_sysnm) + ''' ' + 
                                'or trim(hostnme2) = ''' + %trim(cur_sysnm) + ''' ' +
                                'fetch first 1 rows only';
                        exec sql prepare prelclint from :stmt;
                        exec sql declare lclint cursor for prelclint;
                        exec sql open lclint;
                        exec sql fetch from lclint into :tgt_lclintneta;
                        if sqlcod = 0;
                        endif;
                        exec sql close lclint;

                        option = 'lcl';
                        cmdstr = 'CHGCTLAPPC CTLD(' + %trim(tgt_ctld) + ') LCLINTNETA(''' + %trim(tgt_lclintneta) + ''')';
                        process_Command(option:cmdstr:returnCode);
                        // Vary on local ctld
                        option = 'lcl';
                        cmdstr = 'VRYCFG CFGOBJ(' + %trim(tgt_ctld) + ') CFGTYPE(*CTL) STATUS(*ON)';
                        process_Command(option:cmdstr:returnCode);
                        // to here
                    endif;
                    clear pendingCommand;
                endif;
            endif;
            exec sql fetch next from cfgsrc into :cfgsrc.srcseq, :cfgsrc.srcdta;
        endif;
    enddo;
    exec sql close cfgsrc;
    return;
end-proc;

dcl-proc process_Command;
    dcl-pi *n;
        option char(3); // lcl: for local   rmt: for remote 
        cmdstr char(500);
        returnCode int(5);
    end-pi;
    dcl-pr syscmd int(10) ExtProc('system');
        *n Pointer Value Options(*String);
    end-pr;
    select;
        when option = 'lcl';
            // returnCode = syscmd(cmdstr);
            clear logtxt;
            logsts = 'C';
            logtxt = 'Local system command: ' + %trim(cmdstr);
            writelog(logsts : logtxt);
        when option = 'rmt';
            // returnCode = syscmd(cmdstr);
            clear logtxt;
            logsts = 'C';
            logtxt = 'Remote system command: ' + %trim(cmdstr);
            writelog(logsts : logtxt);
        other;    
    endsl;
    return;
end-proc;

dcl-proc writelog;
    dcl-pi *n;
        logsts char(1); // T: Log Title  C: Log Continue  E: Log Ending
        logtxt char(600);
    end-pi;
    dcl-s cur_date date;
    dcl-s cur_time time;
    dcl-s cur_sysnm char(8) static;
    dcl-s logLocation char(200) static;
    //
    exec sql values(current_date) into :cur_date;
    exec sql values(current_time) into :cur_time;
    if %len(%trim(cur_sysnm)) = 0;
        exec sql values current server into :cur_sysnm;
    endif;
    if %len(%trim(logLocation)) = 0;
        logLocation = '/home/chgnwcfg_' + %trim(cur_sysnm) +
                        '_' + %trim(%scanrpl('-' : '' : %char(cur_date))) + 
                        '_' + %trim(%scanrpl('.' : '' : %char(cur_time))) + '.log';
    endif;
    select;
        when logsts = 'T';
            exec sql call QSYS2.IFS_WRITE_UTF8(trim(:logLocation),
                            '',
                            OVERWRITE => 'REPLACE',
                            END_OF_LINE => 'NONE');
            if %len(%trim(logtxt)) = 0;
                logtxt = '--- Process start ---';
            endif;
            exec sql call QSYS2.IFS_WRITE_UTF8(trim(:logLocation), 
                            ' ' || trim(char(:cur_date)) ||
                            ' ' || trim(char(:cur_time)) ||
                            ' ' || trim(:cur_sysnm) ||
                            ' ' || trim(:logtxt), 
                            END_OF_LINE => 'CRLF');
        when logsts = 'C';
            if %len(%trim(logtxt)) = 0;
                logtxt = '--- Process continue ---';
            endif;
            exec sql call QSYS2.IFS_WRITE_UTF8(trim(:logLocation), 
                            ' ' || trim(char(:cur_date)) ||
                            ' ' || trim(char(:cur_time)) ||
                            ' ' || trim(:cur_sysnm) ||
                            ' ' || trim(:logtxt), 
                            OVERWRITE => 'APPEND',
                            END_OF_LINE => 'CRLF');
        when logsts = 'E';
            if %len(%trim(logtxt)) = 0;
                logtxt = '--- Process finished ---';
            endif;
            exec sql call QSYS2.IFS_WRITE_UTF8(trim(:logLocation), 
                            ' ' || trim(char(:cur_date)) ||
                            ' ' || trim(char(:cur_time)) ||
                            ' ' || trim(:cur_sysnm) ||
                            ' ' || trim(:logtxt), 
                            OVERWRITE => 'APPEND',
                            END_OF_LINE => 'CRLF');
        other;
            snd-msg 'Write Log failed.';
    endsl;
    return;
end-proc;
