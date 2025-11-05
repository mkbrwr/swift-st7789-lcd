@main
struct Main {
    static func main() {
        stdio_init_all()
        let led = UInt32(PICO_DEFAULT_LED_PIN)
        gpio_init(led)
        gpio_set_dir(led, true)
        
        
        let frameBuffer = UnsafeMutableBufferPointer<UInt16>.allocate(capacity: Int(ST7789LCD.SCREEN_WIDTH) * Int(ST7789LCD.SCREEN_HEIGHT))
        frameBuffer.initialize(repeating: 0)
        let lcd = ST7789LCD()
        
        while true {
            prepareImage(frameBuffer)
            lcd.draw(frameBuffer)
        }

        while true {
            gpio_put(led, true)
            sleep_ms(250)
            gpio_put(led, false)
            sleep_ms(250)
        }
    }
}

func prepareImage(_ buffer: UnsafeMutableBufferPointer<UInt16>) {
    let fill = UInt8.random(in: 0...255)
    for y in 0..<Int(ST7789LCD.SCREEN_HEIGHT) {
        for x in 0..<Int(ST7789LCD.SCREEN_WIDTH) {
            let bufferIdx = y * Int(ST7789LCD.SCREEN_WIDTH) + x
            if (y > 80) && (y < 113 + 80) && (x > 60) && (x < 120 + 60) {
                let imageIdx = ((y - 80) * 120 + (x - 60)) * 3
                let r = swift_image_data_at(UInt32(imageIdx))
                let g = swift_image_data_at(UInt32(imageIdx + 1))
                let b = swift_image_data_at(UInt32(imageIdx + 2))
                buffer[bufferIdx] = .init(rgb888: (r, g, b))
            } else {
                buffer[bufferIdx] = .init(rgb888: (fill, fill, fill))
            }
        }
    }
}


extension UInt16 {
    // RGB888 to RGB565
    init(rgb888: (r: UInt8, g: UInt8, b: UInt8)) {
        let r5 = UInt16(rgb888.r >> 3) << 11
        let g6 = UInt16(rgb888.g >> 2) << 5
        let b5 = UInt16(rgb888.b >> 3)
        let packed: UInt16 = r5 | g6 | b5
        self = packed
    }
    
    init(rg: UInt8, ba: UInt8) {
        self = (UInt16(rg) << 8) | UInt16(ba)
    }
    
    var rg: UInt8 {
        UInt8((self >> 8) & 0xff)
    }
    
    var ba: UInt8 {
        UInt8(self & 0xff)
    }
}
