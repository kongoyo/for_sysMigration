**free
// ----------------------------------------------------------------------
// NoMain: This is a service program, no main procedure
// ----------------------------------------------------------------------
Ctl-Opt NoMain;

// ----------------------------------------------------------------------
// 宣告 QMHSNDPM API 的原型
// ----------------------------------------------------------------------
Dcl-Pr QMHSNDPM ExtPgm('QMHSNDPM');
  MsgId      Char(7)      Const;
  QualMsgF   Char(20)     Const;
  MsgData    Char(32767)  Const Options(*Varsize);
  MsgDtaLen  Int(10)      Const;
  MsgType    Char(10)     Const;
  CallStkEnt Char(10)     Const;
  CallStkCnt Int(10)      Const;
  MsgKey     Char(4);
  ErrorCode  LikeDS(ErrorDs); // Corrected: Use a Data Structure for ErrorCode
End-Pr;

// ----------------------------------------------------------------------
// 宣告 ErrorCode 的資料結構
// ----------------------------------------------------------------------
dcl-ds ErrorDs qualified;
  BytesProvided Int(10) Inz(0);
  BytesAvailable Int(10) Inz(0);
  MsgId Char(7);
  MsgData Char(100);
End-Ds;

// ----------------------------------------------------------------------
// 公開程序：SendMsg
// 目的：使用 QMHSNDPM API 發送訊息
// ----------------------------------------------------------------------
Dcl-Proc SendMsg Export;
  Dcl-Pi SendMsg;
    pMsgText Char(256) Const;
  End-Pi;

  Dcl-S MsgKey Char(4);

  // 呼叫 QMHSNDPM API 發送訊息
  QMHSNDPM(
    'CPF9897'      : // 訊息 ID
    'QCPFMSG   *LIBL' : // 訊息檔
    %TrimR(pMsgText) :
    %Len(%TrimR(pMsgText)) :
    '*INFO'        : // 訊息類型
    '*PGMBDY'            : // 呼叫堆疊項目
    1              : // 呼叫堆疊項目計數
    MsgKey         :
    ErrorDs        // Corrected: Pass the data structure
  );

End-Proc;