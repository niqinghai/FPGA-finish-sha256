# SHA-256-HDL

A simple and straigthforward implementation of SHA-256 algorith written in VHDL *(tested and simulated on ModelSim v11.2)* for computing the diggest of any input String. 

*( You can also take a look at the corresponding implementation for [matlab](https://github.com/lostpfg/SHA-256-Matlab)
)*

## Main Features
1. 2^9-1 bits max message length.
2. Automatted message padding.
3. 132 processing cycles/message block.
4. FIPS 180-2 compliant.
5. Suitable for data authentication applications.

## Top level module - sha256_core

                 _ _ _ _ _ _ _ _                                           
     (Inputs)   |               |  (Outputs)                   
      clock  -> |               |       
      reset  -> |               | -> digest
     enable  -> |               |
     message -> |               |
                |  sha256_core  |                  
                 _ _ _ _ _ _ _ _                      
                                                                     
    -- Parameters
      -- messageLength

| Signal        | Direction     | Description  |
| ------------- |:-------------:| ------------:|
| clock         | input         | Input Clock  |
| reset         | input         | Asynchronous reset  |
| enable | input      |    Module Enable        |
| message | input      |    Input Message        |
| messageLength | parameter      |   Length of Input Message        |
| digest | output      |    Output diggest        |
