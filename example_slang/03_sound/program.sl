#include VGS0.SL

main()
VAR BYTE pushing;
VAR BYTE push;
VAR BYTE moving;
VAR BYTE move;
VAR BYTE cursor;
VAR BYTE pad;
{
    // パレットを初期化
    vgs0_palette_set(0, 0, 0, 0, 0);    // black
    vgs0_palette_set(0, 1, 7, 7, 7);    // dark gray
    vgs0_palette_set(0, 2, 24, 24, 24); // light gray
    vgs0_palette_set(0, 3, 31, 31, 31); // white

    // Bank 2 を Character Pattern Table ($A000) に転送 (DMA)
    vgs0_dma(2);

    // メニューを表示
    vgs0_bg_putstr(8, 7, 0x80, "PLAY: #1 PRELUDE");
    vgs0_bg_putstr(8, 9, 0x80, "PLAY: #2 GOLDBERG");
    vgs0_bg_putstr(8, 11, 0x80, "PLAY: #3 WTC1");
    vgs0_bg_putstr(8, 13, 0x80, "PAUSE");
    vgs0_bg_putstr(8, 15, 0x80, "RESUME");
    vgs0_bg_putstr(8, 17, 0x80, "FADEOUT");
    vgs0_oam_set(0, 6 * 8, 7 * 8, 0x80, '>', 0, 0);

    // ボタン入力制御変数を準備
    pushing = 0;
    push = 0;

    // カーソル移動制御変数を準備
    moving = 0;
    move = 0;
    cursor = 7;

    loop {
        vgs0_wait_vsync();
        pad = vgs0_joypad_get();

        // カーソル入力チェック
        if (pad and VGS0_JOYPAD_UP) {
            if (not moving) {
                move = -2;
                moving = 1;
            }
        } else if (pad and VGS0_JOYPAD_DW) {
            if (not moving) {
                move = 2;
                moving = 1;
            }
        } else {
            moving = 0;
        }

        // カーソル移動
        if (move) {
            vgs0_se_play(0);
            cursor += move;
            if (cursor < 7) {
                cursor = 17;
            } else if (17 < cursor) {
                cursor = 7;
            }
            VGS0_ADDR_OAM[0] = cursor * 8;
            move = 0;
        }

        // ボタン入力チェック
        if ((pad and VGS0_JOYPAD_T1) or (pad and VGS0_JOYPAD_T2)) {
            if (not pushing) {
                push = 1;
                pushing = 1;
            }
        } else {
            if (pushing) {
                pushing = 0;
            } else {
                push = 0;
            }
        }

        // Aボタンを押して離した瞬間にカーソル位置のコマンドを実行
        if (not pushing and push) {
            vgs0_se_play(1);
            case cursor of {
                7: vgs0_bgm_play(0);
                9: vgs0_bgm_play(1);
                11: vgs0_bgm_play(2);
                13: vgs0_bgm_pause();
                15: vgs0_bgm_resume();
                17: vgs0_bgm_fadeout();
            }
        }
    }
}
