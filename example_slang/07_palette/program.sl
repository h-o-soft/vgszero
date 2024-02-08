#include VGS0.SL
#include palette.sl

main()
VAR BYTE attr;
VAR WORD x, WORD y;
{
    // パレットを初期化
    init_palette();

    // Bank 2 を Character Pattern Table (0xA000) に転送 (DMA)
    vgs0_dma(2);

    // BG Name Table を設定
    attr = 0;
    for y = 0 to 32 - 1 {
        for x = 0 to 32 - 1 {
            VGS0_ADDR_BG[y*32+x] = 0x00;
            VGS0_ADDR_BG_ATTR[y*32+x] = 0x80 OR ((attr + y) AND 0x0F);
            attr++;
        }
    }

    // 縦スクロール
    loop {
        vgs0_wait_vsync();
        VGS0_ADDR_BG_SCROLL_Y += 1;
    }
}
