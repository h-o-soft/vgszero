#include VGS0.SL

CONST SPRITE_NUM = 256;

// グローバル変数

// 構造体を使えないのでアドレス直接指定

CONST GV = $D000;   // グローバル変数の先頭($C000〜はSLANGがシステムで使うので$D000から始める)
VAR BYTE X:GV;      // グローバル変数は位置を直接指定する
VAR BYTE Y:GV+1;    // 位置の単純演算は一応可能

// typedef struct {
//     uint8_t x;
//     uint8_t y;
// } GlobalVariables;
// #define GV ((GlobalVariables*)0xC000)

main()
VAR BYTE msg[];
VAR BYTE msgcnt;
VAR BYTE pad;
VAR I;
{
    msgcnt = 0;
    msg = 0;
    // パレットを初期化
    vgs0_palette_set_rgb555(0, 0, 0000000000000000b);
    vgs0_palette_set_rgb555(0, 1, 0001110011100111b);
    vgs0_palette_set_rgb555(0, 2, 0110001100011000b);
    vgs0_palette_set_rgb555(0, 3, 0111111111111111b);
    vgs0_palette_set_rgb555(0, 4, 0000001110000000b);
    vgs0_palette_set_rgb555(0, 5, 0000000000011100b);
    vgs0_palette_set(0, 13, 0xD0 >> 3, 0xD0 >> 3, 0x68 >> 3);

    // Bank 2 を Character Pattern Table (0xA000) に転送 (DMA)
    vgs0_dma(2); // FGの左上に使い方を表示
    vgs0_fg_putstr(1, 1, 0x80, "B=LOAD A=SAVE");

    // 座標をsave.datからロード
    if (vgs0_load(GV, 2)) {
        // 読み込めなかったので初期座標を中央に設定
        X = (256 - 16) / 2;
        Y = (200 - 16) / 2;
    }

    // スプライト表示
    vgs0_oam_set(0, X, Y, 0x80, 9, 0, 0);
    vgs0_oam_set(1, X + 8, Y, 0x80 OR 0x40, 9, 0, 0);
    vgs0_oam_set(2, X, Y + 8, 0x80, 10, 0, 0); // NOTE: sdcc 4.3.0 for macOS has a bug that prevents the process of setting the value to the sprite 2 attribute address (0x900A) from being written, so the use of sprite 2 is avoided.
    vgs0_oam_set(3, X + 8, Y + 8, 0x80 OR 0x40, 10, 0, 0);

    // BGM を再生
    vgs0_bgm_play(0);

    // メインループ
    loop {
        // V-BLANK を待機
        vgs0_wait_vsync();
        pad = vgs0_joypad_get();

        // メッセージ表示
        if (msgcnt) {
            if (60 == msgcnt) {
                vgs0_fg_putstr(1, 24, 0x80, msg);
            }
            msgcnt--;
            if (0 == msgcnt) {
                for i = 0 to 32-1 {
                    VGS0_ADDR_FG_ATTR[24*16+i] = 0;
                }
            }
        }

        // スプライトの移動
        if (pad AND VGS0_JOYPAD_LE) {
            X -= 2;
        } else if (pad AND VGS0_JOYPAD_RI) {
            X += 2;
        }
        if (pad AND VGS0_JOYPAD_UP) {
            Y -= 2;
        } else if (pad AND VGS0_JOYPAD_DW) {
            Y += 2;
        }

        if (0 == msgcnt) {
            if (pad AND VGS0_JOYPAD_T1) {
                if (0 == vgs0_save(GV, 2)) {
                    msg = "SAVE SUCCESS.";
                    msgcnt = 60;
                } else {
                    msg = "SAVE FAILED!";
                    msgcnt = 60;
                }
            }
            if (pad AND VGS0_JOYPAD_T2) {
                if (0 == vgs0_load(GV, 2)) {
                    msg = "LOAD SUCCESS.";
                    msgcnt = 60;
                } else {
                    msg = "LOAD FAILED!";
                    msgcnt = 60;
                }
            }
        }

        // スプライトの座標更新
        VGS0_ADDR_OAM[0*8+1] = X;
        VGS0_ADDR_OAM[0*8+0] = Y;
        VGS0_ADDR_OAM[1*8+1] = X + 8;
        VGS0_ADDR_OAM[1*8+0] = Y;
        VGS0_ADDR_OAM[2*8+1] = X;
        VGS0_ADDR_OAM[2*8+0] = Y + 8;
        VGS0_ADDR_OAM[3*8+1] = X + 8;
        VGS0_ADDR_OAM[3*8+0] = Y + 8;
    }
}
