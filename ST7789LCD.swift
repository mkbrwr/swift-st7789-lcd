struct ST7789LCD {
    static let SCREEN_WIDTH: UInt16 = 240
    static let SCREEN_HEIGHT: UInt16 = 300
    
    let PIN_DIN: UInt32 = 19
    let PIN_CLK: UInt32 = 18
    let PIN_CS: UInt32 = 17
    let PIN_DC: UInt32 = 21
    let PIN_RESET: UInt32 = 20
    let PIN_BL: UInt32 = 16
    
    init() {
        setupSPI()
        setupLCD()
    }
    
    func setupSPI() {
        spi_init(spi0, 80 * 1000 * 1000)
        
        spi_set_format(spi0, 8, SPI_CPOL_0, SPI_CPHA_0, SPI_MSB_FIRST)
        
        gpio_set_function(PIN_CLK, GPIO_FUNC_SPI)
        gpio_set_function(PIN_DIN, GPIO_FUNC_SPI)
        
        gpio_init(PIN_CS)
        gpio_set_dir(PIN_CS, true)
        gpio_put(PIN_CS, true)
        
        gpio_init(PIN_DC)
        gpio_set_dir(PIN_DC, true)
        gpio_put(PIN_DC, true)
        
        gpio_init(PIN_RESET)
        gpio_set_dir(PIN_RESET, true)
        gpio_put(PIN_RESET, true)
        
        gpio_init(PIN_CS)
        gpio_init(PIN_DC)
        gpio_init(PIN_RESET)
        gpio_init(PIN_BL)
        gpio_set_dir(PIN_CS, true)
        gpio_set_dir(PIN_DC, true)
        gpio_set_dir(PIN_RESET, true)
        gpio_set_dir(PIN_BL, true)
        
        gpio_put(PIN_CS, true)
        gpio_put(PIN_RESET, true)
    }
    
    
    func setupLCD() {
        let st7789_init_seq: [UInt8] = [
            1, 20, 0x01,  // Software reset
            1, 10, 0x11,  // Exit sleep mode
            2, 2, 0x3a, 0x55,  // Set colour mode to 16 bit
            2, 0, 0x36, 0x00,  // Set MADCTL: row then column, refresh is bottom to top ????
            5, 0, 0x2a, 0x00, 0x00, UInt8(ST7789LCD.SCREEN_WIDTH >> 8), UInt8(ST7789LCD.SCREEN_WIDTH & 0xff),  // CASET: column addresses
            5, 0, 0x2b, 0x00, 0x00, UInt8(ST7789LCD.SCREEN_HEIGHT >> 8), UInt8(ST7789LCD.SCREEN_HEIGHT & 0xff),  // RASET: row addresses
            1, 2, 0x21,  // Inversion on, then 10 ms delay (supposedly a hack?)
            1, 2, 0x13,  // Normal display on, then 10 ms delay
            1, 2, 0x29,  // Main screen turn on, then wait 500 ms
            0,  // Terminate list
        ]
        
        var idx = 0
        let initSeq = st7789_init_seq
        while initSeq[idx] != 0 {
            let cmdStartIdx = Int(idx + 2)
            let cmdEndIdx = Int(idx + 2) + Int(initSeq[idx])
            let cmd: [UInt8]
            if cmdStartIdx == cmdEndIdx {
                cmd = [initSeq[cmdStartIdx]]
            } else {
                cmd = Array(initSeq[cmdStartIdx..<cmdEndIdx])
            }
            lcd_write_cmd(cmd, initSeq[idx])
            let sleepDuration = UInt32(initSeq[idx + 1]) * 5
            sleep_ms(sleepDuration)
            idx += Int(initSeq[idx]) + 2
        }
        gpio_put(PIN_BL, true)
    }
    
    func lcd_set_dc_cs(_ dc: Bool, _ cs: Bool) {
        gpio_put(PIN_DC, dc)
        gpio_put(PIN_CS, cs)
    }
    
    func lcd_write_cmd(_ cmd: [UInt8], _ count: UInt8) {
        st7789_lcd_wait_idle()
        
        lcd_set_dc_cs(false, false)
        st7789_lcd_put(cmd[0])
        
        if count >= 2 {
            st7789_lcd_wait_idle()
            lcd_set_dc_cs(true, false)
            for i in 1..<count {
                st7789_lcd_put(cmd[Int(i)])
            }
        }
        
        st7789_lcd_wait_idle()
        lcd_set_dc_cs(true, true)
    }
    
    func st7789_lcd_put(_ x: UInt8) {
        gpio_put(PIN_CS, false)
        var x = x
        spi_write_blocking(spi0, &x, 1)
        gpio_put(PIN_CS, true)
    }
    
    func st7789_lcd_wait_idle() {
        while spi_is_busy(spi0) {}
    }
    
    typealias SPI = OpaquePointer
    var spi0: SPI { .init(bitPattern: 0x4008_0000)! }
    var spi1: SPI { .init(bitPattern: 0x4008_8000)! }
    
    // PIXELS
    func st7789_start_pixels() {
        let cmd: UInt8 = 0x2c
        lcd_write_cmd([cmd], 1)
        lcd_set_dc_cs(true, false)
    }
    
    func draw(_ buffer: UnsafeMutableBufferPointer<UInt16>) {
        st7789_start_pixels()
        for pixel in buffer {
            st7789_lcd_put(pixel.rg)
            st7789_lcd_put(pixel.ba)
        }
    }
}
