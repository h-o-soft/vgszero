#include VGS0.SL

main()
VAR x, y;
VAR BYTE n;
VAR BYTE cnt;
VAR BYTE TMP;
{
    n = 0;
    cnt = 0;
    // パレットを初期化
    vgs0_palette_set(0, 0, 0, 0, 0);    // black
    vgs0_palette_set(0, 1, 7, 7, 7);    // dark gray
    vgs0_palette_set(0, 2, 24, 24, 24); // light gray
    vgs0_palette_set(0, 3, 31, 31, 31); // white

    // Bank 2 を Character Pattern Table ($A000) に転送 (DMA)
    vgs0_dma(2);

    // NameTableを初期化
    for y = 0 to 32-1  {
        for x = 0 to 32-1 {
            VGS0_ADDR_BG[y*32+x] = '#';
            VGS0_ADDR_BG_ATTR[y*32+x] = 11100000b;
            VGS0_ADDR_FG[y*32+x] = '.';
            VGS0_ADDR_FG_ATTR[y*32+x] = $80;
        }
    }

    // OAM を初期化
    for y = 0 to  16-1 {
        for x = 0 to 16-1 {
            vgs0_oam_set(n, 8 + x * 4, 8 + y * 4, $80, 'X', 0, 0);
            n++;
        }
    }

    // BGM を再生
    vgs0_bgm_play(0);

    while (1) {
        vgs0_wait_vsync();
        VGS0_ADDR_BG_SCROLL_X += 8;
        VGS0_ADDR_BG_SCROLL_Y += 8;
        VGS0_ADDR_FG_SCROLL_X -= 1;
        VGS0_ADDR_FG_SCROLL_Y -= 1;
	
        TMP = VGS0_ADDR_BG_ATTR[(cnt AND 0x1F)*32 + (cnt AND 0x1F)];
        VGS0_ADDR_BG_ATTR[(cnt AND 0x1F)*32 + (cnt AND 0x1F)] = TMP XOR 01100000b;
        vgs0_se_play(cnt);
        VGS0_ADDR_OAM[cnt*8+1] += 4;
        VGS0_ADDR_OAM[cnt*8]++;
        cnt++;
    }
}
