#  CoreBluetooth BLE Demo

## Synopsis

Basic iOS application to interact with a Bluetooth Low Energy (BLE) Heart Rate Monitor.

Connects with BLE peripherals provding the GATT Heart Rate Service (0x180D).

The application processes / understands two characteristics of the service:

Heart Rate Measurement Characteristic - 0x2A37
Body Sensor Location Characteristic - 0x2A38

## Heart Rate Sensor

Code was developed and tested using the Adafruit Bluefruit LE UART Friend - a SoC Bluetooth LE solution based on the Nordic nRF51822.  The Adafruit Bluefruit LE UART Friend was driven by an Arduino Mega2560. using the code supplied by Adafruit.  A picture of the configuratuion is in the Support folder.

## Installation and Building Framework

There are no external dependencies.

Note : Build against device target.

