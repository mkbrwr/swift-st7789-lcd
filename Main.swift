@main
struct Main {
    static func main() {
        stdio_init_all()
        let led = UInt32(PICO_DEFAULT_LED_PIN)
        gpio_init(led)
        gpio_set_dir(led, true)
        
        let chip8 = CHIP8()
        
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
            let diagonalX = (y * Int(ST7789LCD.SCREEN_WIDTH)) / Int(ST7789LCD.SCREEN_HEIGHT)
            let lineThickness = 5 // pixels
            if abs(x - diagonalX) < lineThickness {
                buffer[y * Int(ST7789LCD.SCREEN_WIDTH) + x] = UInt16(rg: 0xff, ba: 0xff)
            } else {
                buffer[y * Int(ST7789LCD.SCREEN_WIDTH) + x] = UInt16(rg: fill, ba: 0xff)
            }
        }
    }
}


extension UInt16 {
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
