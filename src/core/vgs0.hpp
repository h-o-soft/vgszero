/**
 * VGS-Zero - Core Emulator
 * License under GPLv3: https://github.com/suzukiplan/vgszero/blob/master/LICENSE-VGS0.txt
 * (C)2023, SUZUKI PLAN
 */

#ifndef INCLUDE_VGS0_HPP
#define INCLUDE_VGS0_HPP
#include "perlinnoise.hpp"
#include "vdp.hpp"
#include "vgs0def.h"
#include "vgsdecv.hpp"
#include "z80.hpp"

extern "C" {
extern const signed char vgs0_sin_table[256];
extern const signed char vgs0_cos_table[256];
extern const unsigned char vgs0_atan2_table[256][256];
extern const unsigned char vgs0_rand8[256];
extern const unsigned short vgs0_rand16[65536];
};

class VGS0
{
  private:
    class Binary
    {
      public:
        const unsigned char* data;
        size_t size;

        Binary()
        {
            this->data = nullptr;
            this->size = 0;
            ;
        }
    };

    class SoundEffect
    {
      public:
        short* data;
        size_t count;

        SoundEffect()
        {
            this->data = nullptr;
            this->count = 0;
        }
    };

    Binary rom;
    Binary bgm[256];
    SoundEffect se[256];
    int bgmVolume;
    int seVolume;

  public:
    Z80* cpu;
    VDP* vdp;
    VGSDecoder* vgsdec;
    PerlinNoise* noise;
    bool (*saveCallback)(VGS0* vgs0, const void* data, size_t size);
    bool (*loadCallback)(VGS0* vgs0, void* data, size_t size);
    void (*resetCallback)(VGS0* vgs0);

    struct Context {
        int64_t bobo;
        unsigned char ram[0x4000];
        unsigned char romBank[4];
        unsigned char pad;
        unsigned char ri8;
        unsigned short ri16;
        struct BgmContext {
            bool playing;
            bool fadeout;
            int playingIndex;
            unsigned int seekPosition;
        } bgm;
        struct SoundEffectContext {
            bool playing;
            int playingIndex;
        } se[256];
    } ctx;

    VGS0(VDP::ColorMode colorMode = VDP::ColorMode::RGB555)
    {
        this->cpu = new Z80([](void* arg, unsigned short addr) { return ((VGS0*)arg)->readMemory(addr); }, [](void* arg, unsigned short addr, unsigned char value) { ((VGS0*)arg)->writeMemory(addr, value); }, [](void* arg, unsigned short port) { return ((VGS0*)arg)->inPort(port); }, [](void* arg, unsigned short port, unsigned char value) { ((VGS0*)arg)->outPort(port, value); }, this);
        this->cpu->setConsumeClockCallback([](void* arg, int clocks) { ((VGS0*)arg)->consumeClock(clocks); });
        this->vdp = new VDP(
            colorMode, this, [](void* arg) { ((VGS0*)arg)->cpu->requestBreak(); }, [](void* arg) { ((VGS0*)arg)->cpu->generateIRQ(0x07); });
        this->vgsdec = new VGSDecoder();
        this->noise = new PerlinNoise(vgs0_rand16, 0);
        this->saveCallback = nullptr;
        this->loadCallback = nullptr;
        this->resetCallback = nullptr;
        this->setBgmVolume(100);
        this->setSeVolume(100);
        this->reset();
    }

    ~VGS0()
    {
        delete this->noise;
        delete this->vgsdec;
        delete this->vdp;
        delete this->cpu;
    }

    void* getRAM(size_t* size)
    {
        *size = sizeof(this->ctx.ram);
        return this->ctx.ram;
    }

    void* getVRAM(size_t* size)
    {
        return this->vdp->getRAM(size);
    }

    void setExternalRenderingCallback(void (*externalRedneringCallback)(void* arg))
    {
        this->vdp->externalRedneringCallback = externalRedneringCallback;
    }

    bool executeExternalRendering()
    {
        return this->vdp->externalRendering();
    }

    void reset()
    {
        memset(&this->ctx, 0, sizeof(this->ctx));
        for (int i = 0; i < 4; i++) {
            this->ctx.romBank[i] = i;
        }
        this->vdp->reset();
        memset(&this->cpu->reg, 0, sizeof(this->cpu->reg));
        this->cpu->reg.SP = 0xFFFF;
        this->ctx.bgm.playing = false;
        for (int i = 0; i < 256; i++) {
            this->ctx.se[i].playing = false;
        }
        if (this->resetCallback) {
            this->resetCallback(this);
        }
    }

    void loadRom(const void* data, size_t size)
    {
        this->rom.data = (const unsigned char*)data;
        this->rom.size = size & 0x001FFFFF; // max 2MB
        this->rom.size -= size % 0x2000;    // ignore additional not 8KB data
        this->vdp->setROM(this->rom.data, this->rom.size);
    }

    void loadBgm(const void* buffer, size_t size)
    {
        memset(&this->bgm, 0, sizeof(this->bgm));
        const unsigned char* ptr = (const unsigned char*)buffer;
        if (0 != memcmp(ptr, "VGS0BGM", 8)) {
            return; // invalid eye-catch
        }
        ptr += 8;
        int count;
        memcpy(&count, ptr, 4);
        ptr += 4;
        if (count < 0 || 256 < count) {
            return; // invalid count
        }
        int sizes[256];
        for (int i = 0; i < count; i++) {
            memcpy(&sizes[i], ptr, 4);
            ptr += 4;
        }
        for (int i = 0; i < count; i++) {
            this->bgm[i].data = ptr;
            this->bgm[i].size = sizes[i];
            ptr += sizes[i];
        }
    }

    void loadSoundEffect(const void* buffer, size_t size)
    {
        memset(&this->se, 0, sizeof(this->se));
        const unsigned char* ptr = (const unsigned char*)buffer;
        if (0 != memcmp(ptr, "VGS0EFF", 8)) {
            return; // invalid eye-catch
        }
        ptr += 8;
        int count;
        memcpy(&count, ptr, 4);
        ptr += 4;
        if (count < 0 || 256 < count) {
            return; // invalid count
        }
        int sizes[256];
        for (int i = 0; i < count; i++) {
            memcpy(&sizes[i], ptr, 4);
            ptr += 4;
        }
        for (int i = 0; i < count; i++) {
            this->se[i].data = (short*)ptr;
            this->se[i].count = sizes[i] / 2;
            ptr += sizes[i];
        }
    }

    void tick(unsigned char pad)
    {
        if ((pad & VGS0_RESET_KEY) == VGS0_RESET_KEY) {
            this->reset();
        } else {
            this->ctx.pad = 0xFF ^ pad;
            this->cpu->execute(0x7FFFFFFF);
        }
    }

    unsigned short* getDisplay() { return this->vdp->display; }
    size_t getDisplaySize() { return 240 * 192 * 2; }

    short* tickSound(size_t size)
    {
        static short buf[8192];
        if (sizeof(buf) < size) {
            return nullptr; // invalid size
        }
        if (this->ctx.bgm.playing) {
            this->vgsdec->execute(buf, size);
            this->ctx.bgm.playing = !this->vgsdec->isPlayEnd();
            if (!this->ctx.bgm.playing) {
                this->ctx.bgm.fadeout = false;
            } else {
                this->ctx.bgm.seekPosition = (unsigned int)this->vgsdec->getDurationTime();
            }
            if (this->bgmVolume < 100) {
                for (int i = 0; i < (int)size / 2; i++) {
                    int w = buf[i];
                    w *= this->bgmVolume;
                    w /= 100;
                    buf[i] = (short)w;
                }
            }
        } else {
            memset(buf, 0, size);
        }
        for (int i = 0; i < 256; i++) {
            if (this->ctx.se[i].playing) {
                for (int j = 0; j < (int)size / 2; j++) {
                    int wav = buf[j];
                    wav += ((int)this->se[i].data[this->ctx.se[i].playingIndex++]) * this->seVolume / 100;
                    if (32767 < wav) {
                        wav = 32767;
                    } else if (wav < -32768) {
                        wav = -32768;
                    }
                    buf[j] = (short)wav;
                    if ((int)this->se[i].count <= this->ctx.se[i].playingIndex) {
                        this->ctx.se[i].playingIndex = 0;
                        this->ctx.se[i].playing = false;
                        break;
                    }
                }
            }
        }
        return buf;
    }

    size_t getStateSize()
    {
        size_t result = sizeof(this->ctx);
        result += sizeof(this->cpu->reg);
        result += sizeof(this->vdp->ctx);
        result += sizeof(this->noise->ctx);
        return result;
    }

    void saveState(void* buffer)
    {
        unsigned char* bufferPtr = (unsigned char*)buffer;
        memcpy(bufferPtr, &this->ctx, sizeof(this->ctx));
        bufferPtr += sizeof(this->ctx);
        memcpy(bufferPtr, &this->cpu->reg, sizeof(this->cpu->reg));
        bufferPtr += sizeof(this->cpu->reg);
        memcpy(bufferPtr, &this->vdp->ctx, sizeof(this->vdp->ctx));
        bufferPtr += sizeof(this->vdp->ctx);
        memcpy(bufferPtr, &this->noise->ctx, sizeof(this->noise->ctx));
    }

    void loadState(const void* buffer)
    {
        const unsigned char* bufferPtr = (const unsigned char*)buffer;
        this->reset();
        memcpy(&this->ctx, bufferPtr, sizeof(this->ctx));
        bufferPtr += sizeof(this->ctx);
        memcpy(&this->cpu->reg, bufferPtr, sizeof(this->cpu->reg));
        bufferPtr += sizeof(this->cpu->reg);
        memcpy(&this->vdp->ctx, bufferPtr, sizeof(this->vdp->ctx));
        bufferPtr += sizeof(this->vdp->ctx);
        memcpy(&this->noise->ctx, bufferPtr, sizeof(this->noise->ctx));
        this->vdp->refreshDisplay();
        if (this->bgm[this->ctx.bgm.playingIndex].data) {
            this->vgsdec->load(this->bgm[this->ctx.bgm.playingIndex].data, this->bgm[this->ctx.bgm.playingIndex].size);
            this->vgsdec->seekTo(this->ctx.bgm.seekPosition);
        }
    }

    void setBgmVolume(int volume)
    {
        if (volume < 0) {
            this->bgmVolume = 0;
        } else if (100 < volume) {
            this->bgmVolume = 100;
        } else {
            this->bgmVolume = volume;
        }
    }

    void setSeVolume(int volume)
    {
        if (volume < 0) {
            this->seVolume = 0;
        } else if (100 < volume) {
            this->seVolume = 100;
        } else {
            this->seVolume = volume;
        }
    }

  private:
    inline void consumeClock(int clocks)
    {
        this->vdp->ctx.bobo += clocks * VGS0_VDP_CLOCK_PER_SEC;
        while (0 < this->vdp->ctx.bobo) {
            this->vdp->tick();
            this->vdp->ctx.bobo -= VGS0_CPU_CLOCK_PER_SEC;
        }
    }

    inline unsigned char readMemory(unsigned short addr)
    {
        if (addr < 0x8000) {
            int ptr = this->ctx.romBank[addr / 0x2000] * 0x2000 + (addr & 0x1FFF);
            return ((int)this->rom.size <= ptr) ? 0xFF : this->rom.data[ptr];
        } else if (addr < 0xC000) {
            return this->vdp->read(addr);
        } else {
            return this->ctx.ram[addr & 0x3FFF];
        }
    }

    inline void writeMemory(unsigned short addr, unsigned char value)
    {
        if (addr < 0x8000) {
            this->ctx.romBank[addr / 0x2000] = value;
        } else if (addr < 0xC000) {
            this->vdp->write(addr, value);
        } else {
            this->ctx.ram[addr & 0x3FFF] = value;
        }
    }

    inline unsigned char inPort(unsigned char port)
    {
        switch (port) {
            case 0xA0: return this->ctx.pad;
            case 0xB0: return this->ctx.romBank[0];
            case 0xB1: return this->ctx.romBank[1];
            case 0xB2: return this->ctx.romBank[2];
            case 0xB3: return this->ctx.romBank[3];
            case 0xC4: {
                unsigned short addr = this->cpu->reg.pair.H;
                addr <<= 8;
                addr |= this->cpu->reg.pair.L;
                int x1 = this->readMemory(addr++);
                int y1 = this->readMemory(addr++);
                int w1 = this->readMemory(addr++);
                int h1 = this->readMemory(addr++);
                int x2 = this->readMemory(addr++);
                int y2 = this->readMemory(addr++);
                int w2 = this->readMemory(addr++);
                int h2 = this->readMemory(addr);
                return y1 < y2 + h2 && y2 < y1 + h1 && x1 < x2 + w2 && x2 < x1 + w1 ? 0x01 : 0x00;
            }
            case 0xC8: {
                return vgs0_atan2_table[this->cpu->reg.pair.H][this->cpu->reg.pair.L];
            }
            case 0xC9:
                this->ctx.ri8++;
                this->ctx.ri8 &= 0xFF;
                this->cpu->reg.pair.L = vgs0_rand8[this->ctx.ri8];
                return this->cpu->reg.pair.L;
            case 0xCA:
                this->ctx.ri16++;
                this->ctx.ri16 &= 0xFFFF;
                this->cpu->reg.pair.L = vgs0_rand16[this->ctx.ri16] & 0xFF;
                this->cpu->reg.pair.H = (vgs0_rand16[this->ctx.ri16] & 0xFF00) >> 8;
                return this->cpu->reg.pair.L;
            case 0xCE: {
                unsigned short x = this->cpu->reg.pair.H;
                x <<= 8;
                x |= this->cpu->reg.pair.L;
                unsigned short y = this->cpu->reg.pair.D;
                y <<= 8;
                y |= this->cpu->reg.pair.E;
                return this->noise->noise(x, y);
            }
            case 0xCF: {
                unsigned short x = this->cpu->reg.pair.H;
                x <<= 8;
                x |= this->cpu->reg.pair.L;
                unsigned short y = this->cpu->reg.pair.D;
                y <<= 8;
                y |= this->cpu->reg.pair.E;
                return this->noise->octave(this->cpu->reg.pair.A, x, y);
            }
            case 0xDA: {
                if (!this->loadCallback) return 0xFF;
                unsigned short addr = this->cpu->reg.pair.B;
                addr <<= 8;
                addr |= this->cpu->reg.pair.C;
                addr &= 0x3FFF;
                unsigned short size = this->cpu->reg.pair.H;
                size <<= 8;
                size |= this->cpu->reg.pair.L;
                size = 0x4000 < (int)addr + size ? 0x4000 - addr : size;
                return this->loadCallback(this, &this->ctx.ram[addr], size) ? 0x00 : 0xFF;
            }
            default: return 0xFF;
        }
    }

    inline void outPort(unsigned char port, unsigned char value)
    {
        switch (port) {
            case 0xB0: this->ctx.romBank[0] = value; break;
            case 0xB1: this->ctx.romBank[1] = value; break;
            case 0xB2: this->ctx.romBank[2] = value; break;
            case 0xB3: this->ctx.romBank[3] = value; break;
            case 0xC0: {
                int addr = this->cpu->reg.pair.A;
                addr *= 0x2000;
                if (addr + 0x2000 <= (int)this->rom.size) {
                    // printf("DMA: rom[%06X] bank(%d) -> cptn\n", addr, this->cpu->reg.pair.A);
                    memcpy(&this->vdp->ctx.ram[0x2000], &this->rom.data[addr], 0x2000);
                } else {
                    // printf("DMA-error: rom[%06X] bank(%d) -> cptn\n", addr, this->cpu->reg.pair.A);
                    memset(&this->vdp->ctx.ram[0x2000], 0xFF, 0x2000);
                }
                break;
            }
            case 0xC2: {
                unsigned short addrTo = this->cpu->reg.pair.B;
                addrTo <<= 8;
                addrTo |= this->cpu->reg.pair.C;
                unsigned short count = this->cpu->reg.pair.H;
                count <<= 8;
                count |= this->cpu->reg.pair.L;
                // printf("DMA: memset(%04X,%02X,%d)\n",addrTo,cpu->reg.pair.A,count);
                for (int i = 0; i < count; i++, addrTo++) {
                    this->writeMemory(addrTo, this->cpu->reg.pair.A);
                }
                break;
            }
            case 0xC3: {
                unsigned short addrTo = this->cpu->reg.pair.B;
                addrTo <<= 8;
                addrTo |= this->cpu->reg.pair.C;
                unsigned short addrFrom = this->cpu->reg.pair.D;
                addrFrom <<= 8;
                addrFrom |= this->cpu->reg.pair.E;
                unsigned short count = this->cpu->reg.pair.H;
                count <<= 8;
                count |= this->cpu->reg.pair.L;
                // printf("DMA: memcpy(%04X,%04X,%d)\n",addrTo,addrFrom,count);
                for (int i = 0; i < count; i++, addrTo++, addrFrom++) {
                    this->writeMemory(addrTo, this->readMemory(addrFrom));
                }
                break;
            }
            case 0xC5: {
                unsigned short result = 0;
                switch (value) {
                    case 0x00:
                        result = this->cpu->reg.pair.H;
                        result *= this->cpu->reg.pair.L;
                        break;
                    case 0x01:
                        if (this->cpu->reg.pair.L) {
                            result = this->cpu->reg.pair.H;
                            result /= this->cpu->reg.pair.L;
                        } else {
                            result = 0xFFFF;
                        }
                        break;
                    case 0x02:
                        if (this->cpu->reg.pair.L) {
                            result = this->cpu->reg.pair.H;
                            result %= this->cpu->reg.pair.L;
                        } else {
                            result = 0xFFFF;
                        }
                        break;
                    case 0x40: {
                        signed char sh = (signed char)this->cpu->reg.pair.H;
                        signed char sl = (signed char)this->cpu->reg.pair.L;
                        signed short tmp = sh * sl;
                        result = (short)tmp;
                        break;
                    }
                    case 0x41:
                        if (this->cpu->reg.pair.L) {
                            signed char sh = (signed char)this->cpu->reg.pair.H;
                            signed char sl = (signed char)this->cpu->reg.pair.L;
                            signed short tmp = sh / sl;
                            result = (short)tmp;
                        } else {
                            result = 0xFFFF;
                        }
                        break;
                    case 0x80:
                    case 0x81:
                    case 0x82: {
                        unsigned short hl = this->cpu->reg.pair.H;
                        hl <<= 8;
                        hl |= this->cpu->reg.pair.L;
                        if (0x80 == value) {
                            unsigned int tmp = hl;
                            tmp *= this->cpu->reg.pair.C;
                            result = tmp & 0xFFFF;
                        } else if (0 == this->cpu->reg.pair.C) {
                            result = 0xFFFF;
                        } else if (0x81 == value) {
                            result = hl;
                            result /= this->cpu->reg.pair.C;
                        } else {
                            result = hl;
                            result %= this->cpu->reg.pair.C;
                        }
                        break;
                    }
                    case 0xC0:
                    case 0xC1: {
                        unsigned short hl = this->cpu->reg.pair.H;
                        hl <<= 8;
                        hl |= this->cpu->reg.pair.L;
                        int tmp = (signed short)hl;
                        if (0x80 == value) {
                            tmp *= (signed char)this->cpu->reg.pair.C;
                            result = (unsigned short)tmp;
                        } else if (0 == this->cpu->reg.pair.C) {
                            result = 0xFFFF;
                        } else {
                            tmp /= (signed char)this->cpu->reg.pair.C;
                            result = (unsigned short)tmp;
                        }
                        break;
                    }
                }
                this->cpu->reg.pair.H = (result & 0xFF00) >> 8;
                this->cpu->reg.pair.L = result & 0xFF;
                break;
            }
            case 0xC6: this->cpu->reg.pair.A = (unsigned char)vgs0_sin_table[value]; break;
            case 0xC7: this->cpu->reg.pair.A = (unsigned char)vgs0_cos_table[value]; break;
            case 0xC9: this->ctx.ri8 = value; break;
            case 0xCA:
                this->ctx.ri16 = this->cpu->reg.pair.H;
                this->ctx.ri16 <<= 8;
                this->ctx.ri16 |= this->cpu->reg.pair.L;
                break;
            case 0xCB: {
                unsigned short hl = this->cpu->reg.pair.H;
                hl <<= 8;
                hl |= this->cpu->reg.pair.L;
                this->noise->seed(vgs0_rand16, hl);
                break;
            }
            case 0xCC: {
                unsigned short hl = this->cpu->reg.pair.H;
                hl <<= 8;
                hl |= this->cpu->reg.pair.L;
                this->noise->limitX(hl | 1);
                break;
            }
            case 0xCD: {
                unsigned short hl = this->cpu->reg.pair.H;
                hl <<= 8;
                hl |= this->cpu->reg.pair.L;
                this->noise->limitY(hl | 1);
                break;
            }
            case 0xDA: {
                if (this->saveCallback) {
                    unsigned short addr = this->cpu->reg.pair.B;
                    addr <<= 8;
                    addr |= this->cpu->reg.pair.C;
                    addr &= 0x3FFF;
                    unsigned short size = this->cpu->reg.pair.H;
                    size <<= 8;
                    size |= this->cpu->reg.pair.L;
                    size = 0x4000 < (int)addr + size ? 0x4000 - addr : size;
                    this->cpu->reg.pair.A = this->saveCallback(this, &this->ctx.ram[addr], size) ? 0x00 : 0xFF;
                } else {
                    this->cpu->reg.pair.A = 0xFF;
                }
                break;
            }
            case 0xE0:
                if (this->bgm[value].data) {
                    this->ctx.bgm.playing = true;
                    this->ctx.bgm.fadeout = false;
                    this->ctx.bgm.seekPosition = 0;
                    this->ctx.bgm.playingIndex = value;
                    this->vgsdec->load(this->bgm[value].data, this->bgm[value].size);
                }
                break;
            case 0xE1:
                switch (value) {
                    case 0: // pause
                        this->ctx.bgm.playing = false;
                        break;
                    case 1: // resume
                        this->ctx.bgm.playing = true;
                        break;
                    case 2: // fadeout
                        this->ctx.bgm.fadeout = true;
                        this->vgsdec->fadeout();
                        break;
                }
                break;
            case 0xF0:
                if (this->se[value].data) {
                    this->ctx.se[value].playing = true;
                    this->ctx.se[value].playingIndex = 0;
                }
                break;
            case 0xF1:
                this->ctx.se[value].playing = false;
                this->ctx.se[value].playingIndex = 0;
                break;
            case 0xF2:
                this->cpu->reg.pair.A = this->ctx.se[value].playing ? 1 : 0;
                break;
        }
    }
};

#endif
