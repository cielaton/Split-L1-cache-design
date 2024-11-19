// Useful constants
`define EOF 32'h FFFF_FFFF
`define NULL 0

parameter SETS = 16384;  // 2 to the power of 14
parameter I_WAYS = 2;  // 2 way set associative Instruction cache 
parameter D_WAYS = 4;  // 4 way set associative Data cache
parameter TAG_WIDTH = 12;
parameter INDEX_WIDTH = 14;  // The Set field
parameter BYTE_SELECT_WIDTH = 6;  // The byte selection for each block
parameter ADDRESS_WIDTH = 32;  // The memory address lenght
parameter MODE = 0;

// MESI parameter
parameter MESI_INVALID = 2'b00, MESI_MODIFIED = 2'b01, MESI_EXCLUSIVE = 2'b10, MESI_SHARED = 2'b11;

// File I/O parameters

integer file;  // File descriptor
real hitRate;
integer r;
integer N;
integer totalOperations = 0;
real cacheReferences = 0.0;
integer cacheReads = 0;
integer cacheMiss = 0;
integer cacheWrites = 0;
reg [ADDRESS_WIDTH-1:0] address;
reg [TAG_WIDTH-1:0] tag;
reg [INDEX_WIDTH-1:0] index;
reg [BYTE_SELECT_WIDTH-1:0] byteSelect;

// Three dimensional arrays for storing data 

// Valid bit for both caches
reg I_Valid[0:SETS-1][0:I_WAYS-1];
reg D_Valid[0:SETS-1][0:D_WAYS-1];
// Tag bits for both caches
reg [11:0] I_Tag[0:SETS-1][0:D_WAYS-1];
reg [11:0] D_Tag[0:SETS-1][0:I_WAYS-1];
// Index (Set) bits for both caches
reg [13:0] I_Index[0:SETS-1][0:D_WAYS-1];
reg [13:0] D_Index[0:SETS-1][0:I_WAYS-1];

reg [1:0] LRUbits_IC[0:SETS-1][0:I_WAYS-1];
reg [2:0] LRUbits_DC[0:SETS-1][0:D_WAYS-1];

reg [1:0] StoredMESI_IC[0:SETS-1][0:I_WAYS-1];
reg [1:0] StoredMESI_DC[0:SETS-1][0:D_WAYS-1];

reg StoredHit_IC[0:SETS-1][0:I_WAYS-1];
reg StoredHit_DC[0:SETS-1][0:D_WAYS-1];

reg [1:0] StoredC_DC[0:SETS-1][0:D_WAYS-1];
reg [1:0] StoredC_IC[0:SETS-1][0:I_WAYS-1];

reg [ADDRESS_WIDTH-1:0] TempAddress;
reg DONE;

