# Computer-aided VLSI System Design

2023 Fall Computer-aided VLSI System Design

Note: $A$ is area, $T$ is time, $P$ is power, and $G$ is gain.

## Final: 5G MIMO Demodulation - QR Decomposition

- Ranking: 1/52
- Performance: $A \times T \times P / G$ = 3.22e11
- $G$ is calculated according to the Soft LLR (Log-Likelihood Ratio) Error Rate.
- Member per group: 2

The hardware supports the QR decompsition (QRD) component of an MIMO reciever.
From [1], the received signal y can be expressed as:
$y = H\tilde{s} + n$, where $H$ is the channel matrix, $s$ is the transmitted signal, and $n$ is the noise.
In [1], MIMO reciever is composed of QRD and Maximum Maximum Likelihood (ML) demodulation.
The ML demodulation is written as:
$\hat{s} = argmin_s ||y - Hs||^2$

QRD aims to reduce the complexity of ML demodulation.
With QRD, a signal model can be rewritten as:

$y = Hs + n$

$y = (QR)s + n$, where $Q$ is an orthogonal matrix and $R$ is an upper triangular matrix.

$Q^Hy = Rs + Q^Hn$

$\hat{y} = Rs + v$

ML demodulation can be rewritten as:
$\hat{s} = argmin_s ||\hat{y} - Rs||^2$

We implement the QRD component using Modified Gram-Schmidt Procedure.

## HW4: IoT Data Filtering

- Ranking: 11/106
- Performance ($\sum_{patterns}$ $A \times T \times P$) = 6.55e8

The engine supports DES encryption/decryption, CRC checksum, and binary-to-gray-code/gray-code-to-binary conversion.

## HW3: Simple Convolution and Image Processing Engine

- Ranking: 16/112
- Peformance ($A \times T$): 6.47e9

The engine supports convolution, median pooling, and Sobel gradient + non-maximum suppression.

## HW2: Simple MIPS CPU

The simple MIPS CPU contains program counter, ALU, and register files. The instruction set includes arithmetic operations, memory access, and control flow.

## HW1: Arithmetic Logic Unit (ALU)

The ALU supports FX addition/subtraction/Multiplication, FP addition/subtraction, MAC, LFSR, etc.


## Reference
[1] Q. Qi and C. Chakrabarti, "Parallel high throughput soft-output sphere decoder," 2010 IEEE Workshop On Signal Processing Systems, San Francisco, CA, USA, 2010, pp. 174-179, doi: 10.1109/SIPS.2010.5624783

[2] National Taiwan University, Graduate Institute of Electronics Engineering, Computer-aided VLSI Design, Fall 2023
