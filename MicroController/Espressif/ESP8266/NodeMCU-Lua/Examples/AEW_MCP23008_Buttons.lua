---
-- @description Shows how to read 8 GPIO pins/buttons via I2C with the MCP23008 I/O expander.
-- Tested on NodeMCU 0.9.5 build 20150213. 
-- @circuit
--  Connect GPIO0 of the ESP8266-01 module to the SCL pin of the MCP23008. 
--  Connect GPIO2 of the ESP8266-01 module to the SDA pin of the MCP23008.
--  Use 3.3V for VCC.
--  Connect switches or buttons to the GPIOs of the MCP23008 and GND.
--  Connect two 4.7k pull-up resistors on SDA and SCL
--  We will enable the internal pull up resistors for the GPIOS of the MCP23008.
-- @author Miguel (AllAboutEE)
--      GitHub: https://github.com/AllAboutEE 
--      YouTube: https://www.youtube.com/user/AllAboutEE
--      Website: http://AllAboutEE.com
---------------------------------------------------------------------------------------------

-- Constant device address.
local MCP23008_ADDRESS = 0x20

-- Registers' address as defined in the MCP23008's datashseet
local MCP23008_IODIR = 0x00
local MCP23008_IPOL = 0x01
local MCP23008_GPINTEN = 0x02
local MCP23008_DEFVAL = 0x03
local MCP23008_INTCON = 0x04
local MCP23008_IOCON = 0x05
local MCP23008_GPPU = 0x06
local MCP23008_INTF = 0x07
local MCP23008_INTCAP = 0x08
local MCP23008_GPIO = 0x09
local MCP23008_OLAT = 0x0A

-- Default value for i2c communication
local id = 0

-- pin modes for I/O direction
M.INPUT = 1
M.OUTPUT = 0

-- pin states for I/O i.e. on/off
M.HIGH = 1
M.LOW = 0

-- Weak pull-up resistor state
M.ENABLE = 1
M.DISABLE = 0


---
-- @name write
-- @description Writes one byte to a register
-- @param registerAddress The register where we'll write data
-- @param data The data to write to the register
-- @return void
----------------------------------------------------------
local function write(registerAddress, data)
    i2c.start(id)
    i2c.address(id,MCP23008_ADDRESS,i2c.TRANSMITTER) -- send MCP's address and write bit
    i2c.write(id,registerAddress)
    i2c.write(id,data)
    i2c.stop(id)
end

---
-- @name read
-- @description Reads the value of a regsiter
-- @param registerAddress The reigster address from which to read
-- @return The byte stored in the register
----------------------------------------------------------
local function read(registerAddress)
    -- Tell the MCP which register you want to read from
    i2c.start(id)
    i2c.address(id,MCP23008_ADDRESS,i2c.TRANSMITTER) -- send MCP's address and write bit
    i2c.write(id,registerAddress)
    i2c.stop(id)
    i2c.start(id)
    -- Read the data form the register
    i2c.address(id,MCP23008_ADDRESS,i2c.RECEIVER) -- send the MCP's address and read bit
    local data = 0x00
    data = i2c.read(id,1) -- we expect only one byte of data
    i2c.stop(id)

    return string.byte(data) -- i2c.read returns a string so we convert to it's int value
end

---
--! @name begin
--! @description Sets the MCP23008 device address's last three bits. 
--  Note: The address is defined as binary 0100[A2][A1][A0] where 
--  A2, A1, and A0 are defined by the connection of the pins, 
--  e.g. if the pins are connected all to GND then the paramter address 
--  will need to be 0x0.
-- @param address The 3 least significant bits (LSB) of the address
-- @param pinSDA The pin to use for SDA
-- @param pinSCL The pin to use for SCL
-- @param speed The speed of the I2C signal
-- @return void
---------------------------------------------------------------------------
function M.begin(address,pinSDA,pinSCL,speed)
 MCP23008_ADDRESS = bit.bor(MCP23008_ADDRESS,address)
 i2c.setup(id,pinSDA,pinSCL,speed)
end

---
-- @name writeGPIO
-- @description Writes a byte of data to the GPIO register
-- @param dataByte The byte of data to write
-- @return void
----------------------------------------------------------
function M.writeGPIO(dataByte)
    write(MCP23008_GPIO,dataByte)
end

---
-- @name readGPIO
-- @description reads a byte of data from the GPIO register
-- @return One byte of data
----------------------------------------------------------
function M.readGPIO()
    return read(MCP23008_GPIO)
end

---
-- @name writeIODIR
-- @description Writes one byte of data to the IODIR register
-- @param dataByte The byte of data to write
-- @return void
----------------------------------------------------------
function M.writeIODIR(dataByte)
    write(MCP23008_IODIR,dataByte)
end

---
-- @name readIODIR
-- @description Reads a byte from the IODIR register
-- @return The byte of data in IODIR
----------------------------------------------------------
function M.readIODIR()
    return read(MCP23008_IODIR)
end

---
-- @name writeGPPU The byte to write to the GPPU
-- @description Writes a byte of data to the 
-- PULL-UP RESISTOR CONFIGURATION (GPPU)REGISTER 
-- @param databyte the value to write to the GPPU register.
-- each bit in this byte is assigned to an individual GPIO pin
-- @return void
----------------------------------------------------------------
function M.writeGPPU(dataByte)
    write(MCP23008_GPPU,dataByte)
end

---
-- @name readGPPU
-- @description Reads the GPPU (Pull-UP resistors register) byte
-- @return The GPPU byte i.e. state of all internal pull-up resistors
-------------------------------------------------------------------
function M.readGPPU()
    return read(MCP23008_GPPU)
end

-- ESP-01 GPIO Mapping as per GPIO Table in https://github.com/nodemcu/nodemcu-firmware
gpio0, gpio2 = 3, 4

-- Setup the MCP23008
M.begin(0x0,gpio2,gpio0,i2c.SLOW)

M.writeIODIR(0xff)
M.writeGPPU(0xff)

---
-- @name showButtons
-- @description Shows the state of each GPIO pin
-- @return void
---------------------------------------------------------
function showButtons()

    local gpio = mcp23008.readGPIO() -- read the GPIO/buttons states

    -- get/extract the state of one pin at a time
    for pin=0,7 do

        local pinState = bit.band(bit.rshift(gpio,pin),0x1) -- extract one pin state

        -- change to string state (HIGH, LOW) instead of 1 or 0 respectively
        if(pinState == mcp23008.HIGH) then
            pinState = "HIGH"
        else
            pinState = "LOW"
        end

        print("Pin ".. pin .. ": ".. pinState)
    end
    print("\r\n")
end

tmr.alarm(0,2000,1,showButtons) -- run showButtons() every 2 seconds



