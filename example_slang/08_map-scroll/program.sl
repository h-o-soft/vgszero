#include VGS0.SL
#include palette.sl

main()
VAR BYTE scrollCounter;
VAR WORD nextRead;
VAR BYTE nextWrite;
{
    // パレットを初期化
    init_palette();

    // Bank 2 を Character Pattern Table ($A000) に転送 (DMA)
    vgs0_dma(2);

    // マップの初期状態を描画
    scrollCounter = 0;
    nextRead = 0x8000 - 32 * 25;
    nextWrite = 0;
    vgs0_memcpy(VGS0_ADDR_BG, nextRead, 32 * 25);

    // メインループ
    loop {
        // VBLANKを待機
        vgs0_wait_vsync();

        // BGを下スクロール
        VGS0_ADDR_BG_SCROLL_Y -= 1;

        // スクロールカウンタをインクリメント
        scrollCounter++;
        scrollCounter = scrollCounter AND 0x07;
        if (0 != scrollCounter) {
            continue;
        }

        // 次のマップを描画
        nextRead -= 32;
        nextRead = nextRead AND 0x1FFF;
        nextRead = nextRead OR 0x6000;
        nextWrite--;
        nextWrite = nextWrite AND 0x1F;
        vgs0_memcpy(&VGS0_ADDR_BG[nextWrite*32], nextRead, 32);
    }
}