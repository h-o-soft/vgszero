#include VGS0.SL
#include global.sl

countUp()
{
    if (not g_stop) {
        c1++;
        if (9 < c1) {
            c1 = 0;
            c10++;
            if (9 < c10) {
                c10 = 0;
                c100++;
                if (9 < c100) {
                    c100 = 0;
                    c1000++;
                    if (9 < c1000) {
                        g_stop = 1;
                        c1 = 9;
                        c10 = 9;
                        c100 = 9;
                        c1000 = 9;
                    }
                }
            }
        }
    }
}

main()
{
    // パレットを初期化
    vgs0_palette_set(0, 0, 0, 0, 0);    // black
    vgs0_palette_set(0, 1, 7, 7, 7);    // dark gray
    vgs0_palette_set(0, 2, 24, 24, 24); // light gray
    vgs0_palette_set(0, 3, 31, 31, 31); // white

    // Bank 2 を Character Pattern Table ($A000) に転送 (DMA)
    vgs0_dma(2);

    // グローバル変数を初期化
    g_stop = 0;
    c1 = 4;
    c10 = 3;
    c100 = 2;
    c1000 = 1;
    vgs0_bg_putstr(4, 4, 0x80, "COUNT:");

    // メインループ
    loop {
        vgs0_wait_vsync();
        countUp();
        VGS0_ADDR_BG[4*32 + 10] = '0' + c1000;
        VGS0_ADDR_BG[4*32 + 11] = '0' + c100;
        VGS0_ADDR_BG[4*32 + 12] = '0' + c10;
        VGS0_ADDR_BG[4*32 + 13] = '0' + c1;
    }
}
