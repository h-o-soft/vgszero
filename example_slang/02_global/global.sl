
// セーブしたい時やマルチバンクのプログラムで使う時など、アドレスを固定したい場合はこうする
CONST GV = $D000;
VAR BYTE c1:   GV;
VAR BYTE c10:  GV+1;
VAR BYTE c100: GV+2;
VAR BYTE c1000:GV+3;
VAR BYTE g_stop: GV+4;

// // 通常は普通に宣言すればグローバルになる(用途によって使い分ける事)
// VAR BYTE c1;
// VAR BYTE c10;
// VAR BYTE c100;
// VAR BYTE c1000;
// VAR BYTE g_stop;

// struct GlobalVariables {
//     uint8_t c1;
//     uint8_t c10;
//     uint8_t c100;
//     uint8_t c1000;
//     uint8_t stop;
// };
// 
// #define GV ((struct GlobalVariables*)0xC000)
// 