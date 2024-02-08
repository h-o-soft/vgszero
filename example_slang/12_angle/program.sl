#include VGS0.SL

CONST SPRITE_NUM = 256;

// グローバル変数
//typedef struct {
//    uint8_t x;
//    uint8_t y;
//
//    struct Bullet {
//        uint8_t flag;
//        var16_t x;
//        var16_t y;
//        var16_t vx;
//        var16_t vy;
//    } bullets[128];
//    uint8_t bulletIndex;
//} GlobalVariables;
//#define GV ((GlobalVariables*)0xC000)

VAR BYTE GV_x;
VAR BYTE GV_y;
ARRAY BYTE bullets_flag[128];
ARRAY WORD bullets[128 * 4];
CONST BULLET_x = 0;
CONST BULLET_y = 1;
CONST BULLET_vx = 2;
CONST BULLET_vy = 3;
CONST BULLET_MAX = 4;
VAR BYTE bulletIndex;

main()
VAR BYTE a;
VAR BYTE pad;
VAR BYTE i;
VAR idx;
VAR BYTE r;
{
    // パレットを初期化
    vgs0_palette_set_rgb555(0, 0, 0000000000000000b );
    vgs0_palette_set_rgb555(0, 1, 0001110011100111b );
    vgs0_palette_set_rgb555(0, 2, 0110001100011000b );
    vgs0_palette_set_rgb555(0, 3, 0111111111111111b );
    vgs0_palette_set_rgb555(0, 4, 0000001110000000b );
    vgs0_palette_set_rgb555(0, 5, 0000000000011100b );
    vgs0_palette_set(0, 13, 0xD0 >> 3, 0xD0 >> 3, 0x68 >> 3);

    // Bank 2 を Character Pattern Table (0xA000) に転送 (DMA)
    vgs0_dma(2);

    // 座標初期化
    // 基本的にSLANGにおいてワークは全て0になっているので何もしなくても大丈夫……
    //vgs0_memset(0xC000, 0x00, sizeof(GlobalVariables));
    vgs0_memset(bullets_flag, 0x00, 128);
    vgs0_memset(bullets, 0x00, 128 * 4);
    GV_x = 120;
    GV_y = 156;

    // スプライト表示
    vgs0_oam_set(0, GV_x, GV_y, 0x80, 9, 0, 0);
    vgs0_oam_set(1, GV_x + 8, GV_y, 0x80 OR 0x40, 9, 0, 0);
    vgs0_oam_set(2, GV_x, GV_y + 8, 0x80, 10, 0, 0);
    vgs0_oam_set(3, GV_x + 8, GV_y + 8, 0x80 OR 0x40, 10, 0, 0);

    vgs0_fg_putstr(2, 2, 0x80, "ANGLE:000");

    // メインループ
    a = 0;
    loop {
        // V-BLANK を待機
        vgs0_wait_vsync();
        pad = vgs0_joypad_get();

        // スプライトの移動
        if (pad AND VGS0_JOYPAD_LE) {
            GV_x -= 2;
        } else if (pad AND VGS0_JOYPAD_RI) {
            GV_x += 2;
        }
        if (pad AND VGS0_JOYPAD_UP) {
            GV_y -= 2;
        } else if (pad AND VGS0_JOYPAD_DW) {
            GV_y += 2;
        }

        // スプライトの座標更新
        VGS0_ADDR_OAM[0 * 8 + OAM_X] = GV_x;
        VGS0_ADDR_OAM[0 * 8 + OAM_Y] = GV_y;
        VGS0_ADDR_OAM[1 * 8 + OAM_X] = GV_x + 8;
        VGS0_ADDR_OAM[1 * 8 + OAM_y] = GV_y;
        VGS0_ADDR_OAM[2 * 8 + OAM_X] = GV_x;
        VGS0_ADDR_OAM[2 * 8 + OAM_Y] = GV_y + 8;
        VGS0_ADDR_OAM[3 * 8 + OAM_X] = GV_x + 8;
        VGS0_ADDR_OAM[3 * 8 + OAM_Y] = GV_y + 8;

        // 弾の移動
        for i = 0 to 128-1 {
            if (bullets_flag[i]) {
                idx = i * BULLET_MAX;
                bullets[idx + BULLET_x] += bullets[idx + BULLET_vx];
                bullets[idx + BULLET_y] += bullets[idx + BULLET_vy];
                if ((200 < (HIGH bullets[idx + BULLET_y])) OR (248 < (HIGH bullets[idx + BULLET_x]))) {
                    bullets_flag[i]= 0;
                    VGS0_ADDR_OAM[(128 + i) * 8 + OAM_ATTR] = 0x00;
                } else {
                    vgs0_oam_set(128 + i, HIGH bullets[idx + BULLET_x], HIGH bullets[idx + BULLET_y], 0x80, 0x08, 0, 0);
                }
            }
        }

        // 4フレームに1回、画面中央から自機狙いを発射
        a++;
        a = a AND 3;
        if ((0 == a) AND (0 == bullets_flag[bulletIndex])) {
            bullets_flag[bulletIndex] = 1;
	    idx = bulletIndex*BULLET_MAX;
            bullets[idx + BULLET_x] = (124 << 8);
            bullets[idx + BULLET_y] = (100 << 8);
            r = vgs0_angle(127, 104, GV_x + 8, GV_y + 8);
	    bullets[idx + BULLET_vx] = vgs0_sin(r) * 3;
            bullets[idx + BULLET_vy] = vgs0_cos(r) * 3;
            bulletIndex++;
            bulletIndex = bulletIndex AND 0x7F;
            VGS0_ADDR_FG[2*32 +  8] = '0' + vgs0_div(r, 100);
            VGS0_ADDR_FG[2*32 +  9] = '0' + vgs0_div(vgs0_mod(r, 100), 10);
            VGS0_ADDR_FG[2*32 + 10] = '0' + vgs0_mod(r, 10);
        }
    }
}
