#include VGS0.SL
#include palette.sl

main()
VAR BYTE x, BYTE y;
VAR BYTE x2;
VAR BYTE n;
VAR BYTE n1;
VAR BYTE n2;
{
    // パレットを初期化
    init_palette();

    // DPM で BG, FG, Sprite それぞれに異なるキャラクタパターンを設定
    VGS0_ADDR_BG_DPM = 2;
    VGS0_ADDR_FG_DPM = 3;
    VGS0_ADDR_SPRITE_DPM = 4;

    // 上半分にBG/FGを並べる
    for y = 0 to 16 - 1 {
        for x = 0 to 16 - 1 {
            VGS0_ADDR_BG[y*32 + x] = n;
            VGS0_ADDR_FG[y*32 + x + 16] = n;
            VGS0_ADDR_FG_ATTR[y*32 + x + 16] = 0x80;
            n += 1;
        }
    }
    VGS0_ADDR_BG_SCROLL_Y -= 8;
    VGS0_ADDR_FG_SCROLL_Y -= 8;

    // 下半分にスプライトの前半と後半を並べる
    n1 = 0;
    n2 = 0x80;
    for y = 128 + 8 to 200 - 1 {
        x2 = 0x80;
        for x = 0 to 128 - 1 {
            vgs0_oam_set(n1, x, y, 0x80, n1, 0, 0);
            vgs0_oam_set(n2, x2, y, 0x80, n2, 0, 0);
            n1 += 1;
            n2 += 1;
            x2 += 8;
	    x += 7;
        }
	y += 7;
    }
}
