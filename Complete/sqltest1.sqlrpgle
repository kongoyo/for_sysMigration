**free
ctl-opt option(*srcstmt) dftactgrp(*no);
dcl-s objlongschema char(10);
dcl-s objname char(10);
dcl-s stmt char(1500);
dcl-s cur_sysnm char(10);
dcl-ds curroute qualified;
    route_type char(8);
    route_destination char(45);
    subnet_mask char(15);
    next_hop char(45);
end-ds;
//
// objlongschema = 'DDSCINFO';
// objname = 'OBJAUT';
// objtype = '*FILE';
// Test 3


// Test 2
objlongschema = 'QTEMP';
objname = 'CURSYSIP';
cur_sysnm = 'KSG01N';

exec sql set option commit = *none ;

stmt = 'drop table qtemp.currout' + %subst(%trim(cur_sysnm) : 3 : 3) + ' if exists';
exec sql prepare precursys from :stmt;
exec sql execute precursys;

stmt = 'create table qtemp.currout' + %subst(%trim(cur_sysnm) : 3 : 3) + ' as (' +
        'select * from qsys2.netstat_route_info' +
        ') with data';
exec sql prepare precursys from :stmt;
exec sql execute precursys;

stmt = 'select route_type, route_destination, subnet_mask, next_hop ' + 
                'from qtemp.currout' + %subst(%trim(cur_sysnm) : 3 : 3) + ' ' +
                'where route_type <> ''DIRECT''';
exec sql prepare precursys from :stmt;
exec sql declare cursys cursor for precursys;
exec sql open cursys;
exec sql fetch from cursys into :curroute;
dow sqlcod = 0;
    if sqlcod = 0;
         snd-msg curroute.route_destination;
         exec sql fetch from cursys into :curroute;
    endif;
enddo;
exec sql close cursys;


// stmt = 'drop table ' + %trim(objlongschema)+ '.' + %trim(objname) + ' if exists';
// exec sql prepare predrop from :stmt;
// exec sql execute predrop;
// exec sql commit;

// test 3
// stmt = 'select oausr from ' + %trim(objlongschema)+ '.' + %trim(objname) + ' ' +
//             'where oalib = ? ' +
//             'and oaname = ? ' +
//             'and oatype = ?';
// exec sql prepare pretest2 from :stmt;
// exec sql declare test2 cursor for pretest2;
// exec sql open test2 using :objlongschema, :objname, :objtype;
// exec sql fetch from test2 into :oausr;
// if sqlcod = 0;
//     snd-msg oausr;
//     exec sql fetch from test2 into :oausr;
// endif;      

// Test 1
// stmt = 'select oausr from ' + %trim(objlongschema)+ '.' + %trim(objname) + ' ' +
//             'where oalib = ? ' +
//             'and oaname = ? ' +
//             'and oatype = ?';
// exec sql prepare preautcur from :stmt;
// exec sql declare autcur cursor for preautcur;
// exec sql open autcur using :objlongschema, :objname, :objtype;
// exec sql fetch next from autcur into :oausr;
// dow sqlcod = 0;
//     if sqlcod = 0;
//         snd-msg oausr;
//         exec sql fetch next from autcur into :oausr;
//     endif;      
// enddo;
// exec sql close autcur;
//
*inlr = *on;
return;
