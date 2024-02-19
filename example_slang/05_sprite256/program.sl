
#include VGS0.SL

CONST SPRITE_NUM = 256;
CONST OBJ_X  = 0;
CONST OBJ_Y  = 1;
CONST OBJ_VX = 2;
CONST OBJ_VY = 3;
CONST OBJ_AN = 4;

ARRAY WORD obj[SPRITE_NUM*5-1];

//// グローバル変数
//typedef struct {
//    // スプライトの表示情報
//    struct Obj {
//        union {
//            uint8_t raw[2];
//            uint16_t val;
//        } x;
//        union {
//            uint8_t raw[2];
//            uint16_t val;
//        } y;
//        int8_t vx;
//        int8_t vy;
//        uint8_t an;
//    } obj[SPRITE_NUM];
//} GlobalVariables;
//#define GV ((GlobalVariables*)0xC000)

MAIN()
VAR i, idx, oidx, x, y, sval;
VAR BYTE rptr;
VAR pobj[];
{
//    random = crandom;

    // パレットを初期化
    vgs0_palette_set_rgb555(0, 0, 0000000000000000b );
    vgs0_palette_set_rgb555(0, 1, 0001110011100111b );
    vgs0_palette_set_rgb555(0, 2, 0110001100011000b );
    vgs0_palette_set_rgb555(0, 3, 0111111111111111b );
    vgs0_palette_set_rgb555(0, 4, 0000001110000000b );
    vgs0_palette_set_rgb555(0, 5, 0000000000011100b );

    // Bank 2 を Character Pattern Table (0xA000) に転送 (DMA)
    vgs0_dma(2);

    // FGの左上に "SPRITE TEST" を描画
    vgs0_fg_putstr(2, 2, 0x80, "SPRITE TEST");

    // BG全画面にひし形を描画
    for y = 0 to 32-1 {
        for x = 0 to 32-1 {
            VGS0_ADDR_BG[y*32 + x] = $10;
            VGS0_ADDR_BG[y*32 + x + $400] = $80 or ((x and 1) << 5) or ((y and 1) << 6);
        }
    }

    // スプライト & グローバル変数を初期化
    rptr = 0;
    for i = 0 to SPRITE_NUM-1
    {
        idx = i * 8;
        pobj = &obj[i*5];
        VGS0_ADDR_OAM[idx+1] = vgs0_rand8(); // x
        VGS0_ADDR_OAM[idx+0] = vgs0_rand8() MOD 192;	// y
        VGS0_ADDR_OAM[idx+2] = 1 + (i AND $07);	// ptn
        VGS0_ADDR_OAM[idx+3] = $80;	// attr
        pobj[OBJ_X] = VGS0_ADDR_OAM[idx+1] << 8;
        pobj[OBJ_Y] = VGS0_ADDR_OAM[idx+0] << 8;
        pobj[OBJ_VX] = vgs0_rand16() MOD 512 - 256;
        pobj[OBJ_VY] = vgs0_rand16() MOD 512 - 256;
        pobj[OBJ_AN] = vgs0_rand8();
    }

    // メインループ
    loop {
        // V-BLANK を待機
        vgs0_wait_vsync();

        // スプライトを動かす
        for i = 0 to  SPRITE_NUM-1 {
            oidx = i * 5;
            pobj = &obj[i*5];
            pobj[OBJ_X] += pobj[OBJ_VX];
            pobj[OBJ_Y] += pobj[OBJ_VY];
            idx = i * 8;
            VGS0_ADDR_OAM[idx+1] = HIGH pobj[OBJ_X];
            VGS0_ADDR_OAM[idx+0] = HIGH pobj[OBJ_Y];
            pobj[OBJ_AN] = (pobj[OBJ_AN]+1) AND $03;
            if (0 == pobj[OBJ_AN]) {
                VGS0_ADDR_OAM[idx+2]++;
                if (9 == VGS0_ADDR_OAM[idx+2]) {
                    VGS0_ADDR_OAM[idx+2] = 1;
                }
            }
        }

        // BGをスクロール
        VGS0_ADDR_BG_SCROLL_Y--;
    }
}