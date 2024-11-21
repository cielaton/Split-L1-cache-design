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
  // stored MESI value
  reg [1:0] I_StoredMESI[0:SETS-1][0:I_WAYS-1];
  reg [1:0] D_StoredMESI[0:SETS-1][0:D_WAYS-1];
  // Bit indicate the cache hit
  reg I_StoredHit[0:SETS-1][0:I_WAYS-1];
  reg D_StoredHit[0:SETS-1][0:D_WAYS-1];
  // Haven't known yet
  reg [1:0] I_StoredC[0:SETS-1][0:I_WAYS-1];
  reg [1:0] D_StoredC[0:SETS-1][0:D_WAYS-1];

  // Temporary address
  reg [ADDRESS_WIDTH-1:0] TempAddress;

  reg DONE;

  // Intergers for the "for" loops
  integer i, j;

  // Hit count
  real hitCount;

  // Task to initilize all the register values
  task initialize;
    begin
      // Fill up the data cache
      for (i = 0; i < SETS; i = i + 1) begin
        for (j = 0; j < I_WAYS; j = j + 1) begin
          I_Valid[i][j] = 0;
          I_Tag[i][j] = {12{1'b0}};
          I_LRUBits[i][j] = 0;
          I_StoredHit[i][j] = 0;
          I_StoredC[i][j] = 2'bxx;
          I_StoredMESI[i][j] = 0;
        end
        for (j = 0; j < D_WAYS; j = j + 1) begin
          D_Valid[i][j] = 0;
          D_Tag[i][j] = {12{1'b0}};
          D_LRUBits[i][j] = 0;
          D_StoredHit[i][j] = 0;
          D_StoredC[i][j] = 2'bxx;
          D_StoredMESI[i][j] = 0;
        end
        DONE = 1'b0;
      end
    end
  endtask

  integer file;  // File descriptor

  initial begin : file_block
    file = $fopen("./trace.txt", "r");
    $fclose(file);
  end


endmodule


