
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

// 乱数テーブル
CONST crandom = [ 
    $2A, $46, $5E, $7D, $45, $DA, $1E, $72, $38, $43, $D4, $D1, $3E, $69, $AC, $7E,
    $08, $79, $8F, $F5, $0F, $E8, $E4, $41, $6D, $71, $2F, $04, $E3, $5D, $D0, $C3,
    $19, $7B, $DF, $1A, $6E, $CD, $C8, $84, $27, $CA, $BA, $53, $A8, $62, $16, $FF,
    $3C, $22, $51, $95, $0E, $63, $26, $B3, $42, $ED, $A0, $78, $73, $C5, $34, $DE,
    $9F, $E6, $A1, $B9, $61, $59, $24, $9D, $F4, $68, $00, $5A, $7C, $91, $85, $C4,
    $D5, $3D, $C2, $31, $99, $30, $17, $8E, $3A, $96, $B7, $C1, $B1, $B5, $3B, $93,
    $EB, $4F, $4A, $9A, $70, $37, $60, $09, $D2, $AA, $D8, $B2, $D3, $29, $F7, $67,
    $1D, $0D, $F9, $4D, $F6, $77, $EC, $82, $06, $2B, $14, $F3, $6F, $F1, $4E, $BD,
    $83, $AF, $55, $81, $49, $6A, $50, $35, $A3, $E1, $8D, $75, $BC, $A9, $07, $65,
    $01, $57, $97, $E5, $C9, $3F, $10, $C0, $89, $EE, $74, $9E, $66, $8B, $0C, $1F,
    $25, $39, $64, $E2, $5C, $47, $40, $32, $FE, $6C, $F8, $B4, $A5, $B0, $44, $36,
    $CE, $5F, $6B, $05, $D7, $AE, $33, $52, $1B, $11, $1C, $DC, $48, $02, $CF, $F0,
    $80, $7F, $28, $E7, $92, $E0, $9B, $86, $20, $CB, $7A, $54, $0B, $C6, $94, $BF,
    $76, $DD, $CC, $B8, $13, $4B, $0A, $5B, $88, $FD, $18, $FA, $9C, $98, $A4, $2C,
    $DB, $12, $AD, $03, $58, $EF, $FB, $A6, $D6, $8C, $D9, $C7, $2D, $F2, $15, $A2,
    $2E, $A7, $4C, $87, $B6, $90, $56, $E9, $EA, $23, $BE, $FC, $AB, $8A, $21, $BB
];
ARRAY BYTE random[]:crandom;

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
        VGS0_ADDR_OAM[idx+1] = random[rptr++]; // x
        VGS0_ADDR_OAM[idx+0] = random[rptr++] MOD 192;	// y
        VGS0_ADDR_OAM[idx+2] = 1 + (i AND $07);	// ptn
        VGS0_ADDR_OAM[idx+3] = $80;	// attr
        pobj[OBJ_X] = VGS0_ADDR_OAM[idx+1] << 8;
        pobj[OBJ_Y] = VGS0_ADDR_OAM[idx+0] << 8;
        sval = random[rptr++];
        if sval and $80 {
            sval = sval OR $ff00;
        }
        pobj[OBJ_VX] = sval;
        sval = random[rptr++];
        if sval and $80 {
            sval = sval OR $ff00;
        }
        pobj[OBJ_VY] = sval;
        pobj[OBJ_AN] = random[rptr++];
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