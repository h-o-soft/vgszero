
#include VGS0.SL

CONST SPRITE_NUM = 256;

//// グローバル変数
//typedef struct {
//    uint16_t seed;
//    uint16_t x;
//    uint16_t y;
//    int8_t vx;
//    int8_t vy;
//} GlobalVariables;
//#define GV ((GlobalVariables*)0xC000)
VAR GV_x, GV_y;
VAR GV_vx, GV_vy;   // 元は int8_t だが、SLANGでは(符号あり)負値のキャストがされないのでWORDにしてしまう
VAR GV_seed;

render()
VAR x, y;
{
    for y = 0 to 32-1 {
        for x = 0 to 32-1 {
            VGS0_ADDR_BG[y*32 + x] = vgs0_noise_oct(10, GV_x + x, GV_y + y);
        }
    }
}

update()
{
    GV_seed += 255;
    vgs0_noise_seed(GV_seed);
    render();
}

main()
VAR i;
VAR BYTE prev;
VAR BYTE now;
{
    // パレットを初期化
    for i = 0 to 16-1 {
        vgs0_palette_set(0, i, 0, i << 1, 0);
    }

    // Bank 2 を Character Pattern Table (0xA000) に転送 (DMA)
    vgs0_dma(2);

    // グローバル変数を初期化
    // WORKは0で初期化されているのでしなくて良い
    // vgs0_memset((uint16_t)GV, 0, sizeof(GV));

    // 縮尺を設定（デフォルトの 64 から 32 にすることで縮尺が倍になる）
    vgs0_noise_limitX(32);
    vgs0_noise_limitY(32);

    // 初期設定
    update();
    prev = 0;
    now = 0;
    loop {
        now = vgs0_joypad_get();
        if (0 == (prev AND VGS0_JOYPAD_ST) && 0 != (now AND VGS0_JOYPAD_ST)) {
            // 乱数の種をズラしてマップを再生成
            update();
        } else {
            // 入力チェック
            if (now AND VGS0_JOYPAD_LE) {
                GV_vx = -1;
            } else if (now AND VGS0_JOYPAD_RI) {
                GV_vx = 1;
            } else {
                GV_vx = 0;
            }
            if (now AND VGS0_JOYPAD_UP) {
                GV_vy = -1;
            } else if (now AND VGS0_JOYPAD_DW) {
                GV_vy = 1;
            } else {
                GV_vy = 0;
            }
            // 入力がある場合はスクロール
            if (GV_vx OR GV_vy) {
                GV_x += GV_vx;
                GV_y += GV_vy;
                render();
            }
        }
        prev = now;

        // 垂直動機待ち
        vgs0_wait_vsync();
    }
}
