# 5351 Initialization using SystemVerilog

## 5351初始化——SystemVerilog实现

This project demonstrates how to initialize the 5351 (Si5351, MS5351) using SystemVerilog. Please note that the calculations are performed in the preprocessor of the Verilog synthesizer, and therefore do not support dynamic modifications. While there is a possibility to modify it for dynamic changes, the resource consumption may be significant. The configuration error is smaller than max(2Hz, 1ppm). 

本工程展示了如何使用SystemVerilog完成5351 (Si5351, MS5351) 的初始化。请注意，计算是在Verilog综合器的预处理器中完成的，因此不支持动态修改。虽然有可能将其修改为支持动态更改，但资源消耗可能会非常惊人。配置误差小于max(2Hz, 1ppm)。

## Development Board

## 开发板

The development board used is the Tang Mega 138K Pro Dock. PLL2 is configured for a single-ended output of 10MHz. The single-ended output is also duplicated to the L22 header for observation. During the configuration process, the SCL and SDA signals are also duplicated to the U22 and V22 headers for observation.

使用的开发板是Tang Mega 138K Pro Dock。PLL2被配置为10MHz的单端输出。单端输出也被复制到L22排针以便观察。在配置过程中，SCL和SDA信号也被复制到U22和V22排针以便观察。

## Modification

## 修改

To modify the configuration, change the parameters of the `v5351_inst` instance. The configurable range is from 2400Hz to 225MHz.

要修改配置，请修改v5351_inst实例的参数。可配置范围为2400Hz到225MHz。

