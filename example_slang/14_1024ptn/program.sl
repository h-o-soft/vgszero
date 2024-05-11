#include VGS0.SL

main()
VAR BYTE n;
VAR BYTE x;
VAR BYTE y;
VAR BYTE pad;
{
    // Bank 2 を Character Pattern Table (0xA000) に転送 (DMA) してパレットに設定
    vgs0_dma(2);
    vgs0_memcpy(&VGS0_ADDR_PALETTE, &VGS0_ADDR_CHARACTER, 512);

    // BG の DPM を Bank 3 に設定して BG を 1024 パターンモードに設定
    VGS0_ADDR_BG_DPM = 3;
    VGS0_ADDR_PTN1024 = $01;

    // ネームテーブルを設定
    n = 0;
    for y = 0 to 32-1
    {
        for x = 0 to 32-1
        {
            // VGS0_ADDR_BG->ptn[y][x] = n;
            VGS0_ADDR_BG[y*32 + x] = n++;
        }
    }
    
    // ループ
    loop {
        // 垂直動機待ち
        vgs0_wait_vsync();

        // カーソル入力でスクロール
        pad = vgs0_joypad_get();
        if (pad AND VGS0_JOYPAD_LE) {
            VGS0_ADDR_BG_SCROLL_X -= 1;
        } else if (pad AND VGS0_JOYPAD_RI) {
            VGS0_ADDR_BG_SCROLL_X += 1;
        }
        if (pad AND VGS0_JOYPAD_UP) {
            VGS0_ADDR_BG_SCROLL_Y -= 1;
        } else if (pad AND VGS0_JOYPAD_DW) {
            VGS0_ADDR_BG_SCROLL_Y += 1;
        }
    }
}
