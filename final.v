// Useful constants
`define EOF 32'h FFFF_FFFF
`define NULL 0
module split_L1_cache ();

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
  // Bits indicate the LRU algorithm
  reg [1:0] I_LRUBits[0:SETS-1][0:I_WAYS-1];
  reg [2:0] D_LRUBits[0:SETS-1][0:D_WAYS-1];
  // Stored MESI value
  reg [1:0] I_storedMESI[0:SETS-1][0:I_WAYS-1];
  reg [1:0] D_storedMESI[0:SETS-1][0:D_WAYS-1];
  // Bit indicate the cache hit
  reg I_storedHit[0:SETS-1][0:I_WAYS-1];
  reg D_storedHit[0:SETS-1][0:D_WAYS-1];
  // Haven't known yet
  reg [1:0] StoredC_DC[0:SETS-1][0:D_WAYS-1];
  reg [1:0] StoredC_IC[0:SETS-1][0:I_WAYS-1];

  // Temporary address
  reg [ADDRESS_WIDTH-1:0] TempAddress;

  reg DONE;

  // Intergers for the "for" loops
  integer i, j;

  // Hit count
  real hitCount;


  integer file;  // File descriptor

  initial begin : file_block
    file = $fopen("./trace.txt", "r");
    $fclose(file);
  end
endmodule
