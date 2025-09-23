**free
ctl-opt dftactgrp(*no) main(Main);

dcl-proc Main;

  // 宣告要呼叫的服務程式中的程序原型
  // extproc 是關鍵，它告訴編譯器這是一個外部程序
  dcl-pr SendMsg extproc('STEVE/SENDMSG');
    pMsgText Char(256) Const;
  end-pr;

  // 宣告要傳送的訊息變數
  dcl-s myMsg char(50);

  // 設定你想要發送的訊息
  myMsg = 'Hello from RPGLE';

  // 直接呼叫 SendMsg 服務程式中的程序，並傳入訊息
  SendMsg(myMsg);

  // 程式結束
  *inlr = *on;
  return;

end-proc;