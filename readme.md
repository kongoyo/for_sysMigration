# Some sqlrpgle Tests

## colhpripct.sqlrpgle :    
1. 刪除 QTEMP/CFGSRC
2. 建立 QTEMP/CFGSRC
3. 執行 RTVCFGSRC 存入 QTEMP/CFGSRC 
4. 拆解 CFGSRC
5. 刪除 QTEMP/CFGTBL
6. 建立 QTEMP/CFGTBL
7. 寫入 QTEMP/CFGTBL

## rstnpusr.sqlrpgle
1. 查詢現行主機上 no_password_indicator 為 true 的使用者並產生表格 QTEMP/NPUSR
2. 查詢 QTEMP/NPUSR 並執行 rstusrprf


                         