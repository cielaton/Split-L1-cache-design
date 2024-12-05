module split_L1_cache ();

  parameter SETS = 16384;  // 2 to the power of 14
  parameter I_WAYS = 2;  // 2 way set associative Instruction cache 
  parameter D_WAYS = 4;  // 4 way set associative Data cache
  parameter TAG_WIDTH = 12;  // The Tag field
  parameter INDEX_WIDTH = 14;  // The Set field
  parameter BYTE_SELECT_WIDTH = 6;  // The byte selection for each block
  parameter ADDRESS_WIDTH = 32;  // The memory address lenght
  integer MODE;

  // File I/O parameters

  real hitRate;
  real hitCount = 0;
  integer missCount = 0;
  integer matchedNums;  // Store the number of matches from fscanf
  integer cacheReferences = 0;  // Number of times the cache is refered
  integer N;  // Sepcify the operation
  integer totalOperations = 0;
  integer cacheReads = 0;
  integer cacheWrites = 0;
  reg [ADDRESS_WIDTH-1:0] address;
  reg [TAG_WIDTH-1:0] tag;
  reg [INDEX_WIDTH-1:0] index;
  reg [BYTE_SELECT_WIDTH-1:0] byteSelect;

  // Three dimensional arrays for storing data in cache

  // Valid bit for both caches
  reg I_Valid[0:SETS-1][0:I_WAYS-1];
  reg D_Valid[0:SETS-1][0:D_WAYS-1];
  // Dirty bit for both caches
  reg I_Dirty[0:SETS-1][0:I_WAYS-1];
  reg D_Dirty[0:SETS-1][0:D_WAYS-1];
  // Tag bits for both caches
  reg [11:0] I_Tag[0:SETS-1][0:D_WAYS-1];
  reg [11:0] D_Tag[0:SETS-1][0:I_WAYS-1];
  // Index (Set) bits for both caches
  reg [13:0] I_Index[0:SETS-1][0:D_WAYS-1];
  reg [13:0] D_Index[0:SETS-1][0:I_WAYS-1];
  // Bits indicate the LRU algorithm
  reg I_LRUBits[0:SETS-1][0:I_WAYS-1];
  reg [1:0] D_LRUBits[0:SETS-1][0:D_WAYS-1];

  reg DONE;

  // Intergers for the "for" loops
  integer i, j;

  integer file;  // File descriptor
  integer temp;  // Variable to ignore returned value

  input_arguments inputHandler (
      file,
      MODE
  );

  initial begin : main_block
    // If file open error, stop the block
    if (file == 0) disable main_block;
    // Init values
    initialize();
    // Read until the end of the file
    while (!$feof(
        file
    )) begin
      // Read the first character of each line
      temp = $fscanf(file, "%s ", N);
      N = N - 48;  // The actual number value

      case (N)
        // Read data from L1 data cache
        0: begin
          request_setup();
          cacheReads = cacheReads + 1;
          set(N, tag, index, byteSelect, address);
        end
        // Write data to L1 data cache
        1: begin
          request_setup();
          cacheWrites = cacheWrites + 1;
          set(N, tag, index, byteSelect, address);
        end
        // Instruction fetch 
        // (read request to L1 instruction cache)
        2: begin
          request_setup();
          cacheReads = cacheReads + 1;
          set(N, tag, index, byteSelect, address);
        end
        // Evict command from L2 
        3: begin
          request_setup();
          set(N, tag, index, byteSelect, address);
        end
        // Clear & reset all states and statistics 
        8: begin
          // Init task to reset stored cache values
          initialize();
          totalOperations = totalOperations + 1;
          cacheReferences = 0;
          cacheReads = 0;
          cacheWrites = 0;
          hitCount = 0;
          missCount = 0;
        end
        // Print contents and states of the cache 
        9: begin
          write_out();
          totalOperations = totalOperations + 1;
        end
        default: $display("");
      endcase
    end

    // Display information when reached end of file
    if (cacheReferences != 0) hitRate = hitCount / (hitCount + missCount);
    else hitRate = 0.0;

    $display("Total operations: %14d", totalOperations);
    $display("Number of cache reads: %9d", cacheReads);
    $display("Number of cache writes: %8d", cacheWrites);
    $display("Number of cache hits: %10d", hitCount);
    $display("Number of cache miss: %10d", missCount);
    $display("Hit rate: %22f \n", hitRate);

    $fclose(file);
  end

  // ------------------------------------------------------
  // Task to initilize all the register values
  task initialize;
    begin
      // Fill up the instruction cache
      for (i = 0; i < SETS; i = i + 1) begin
        for (j = 0; j < I_WAYS; j = j + 1) begin
          I_Valid[i][j] = 0;
          I_Tag[i][j] = {12{1'b0}};
          I_LRUBits[i][j] = 0;
          I_Dirty[i][j] = 0;
        end
        // Fill up the data cache
        for (j = 0; j < D_WAYS; j = j + 1) begin
          D_Valid[i][j] = 0;
          D_Tag[i][j] = {12{1'b0}};
          D_LRUBits[i][j] = 0;
          D_Dirty[i][j] = 0;
        end
        DONE = 0;
      end
    end
  endtask

  // ------------------------------------------------------
  // Decode the address and update some state variables
  task request_setup;
    begin
      // Read the address from trace.txt file
      matchedNums = $fscanf(file, " %h:\n", address);

      tag = address[31:20];  // 12-bit tag
      index = address[19:6];  // 14-bit index
      byteSelect = address[5:0];  // 6-bit byte selection
      // Increse the counter
      totalOperations = totalOperations + 1;
      cacheReferences = cacheReferences + 1.0;
    end
  endtask

  // ------------------------------------------------------
  task set;
    input integer N;
    input [TAG_WIDTH-1:0] tag;
    input [INDEX_WIDTH-1:0] index;
    input [BYTE_SELECT_WIDTH-1:0] byteSelect;
    input [ADDRESS_WIDTH-1:0] address;

    begin
      case (N)
        // Read data from L1 data cache
        0: begin
          // Examine each block in set
          for (i = 0; i < D_WAYS; i = i + 1) begin
            if (DONE == 0) begin
              // If there is data inside the block
              if (D_Valid[index][i] == 1) begin
                // If the tag is matched
                if (D_Tag[index][i] == tag) begin
                  // Report to monitor
                  hitCount = hitCount + 1.0;
                  // Adjust LRU bits
                  D_LRU_replacement();
                  DONE = 1;
                end  // Else, proceed to next block
              end  // Compulsory miss 
              else begin
                // Report MISS to monitor
                missCount = missCount + 1;
                // Update the tag field
                D_Tag[index][i] = tag;
                // Send data request to L2 cache
                if (MODE == 1) $display("[Data] Read from L2 by Address: %h", address);
                //Adjust LRU bits
                D_LRU_replacement();
                D_Valid[index][i] = 1;
                DONE = 1;
              end
            end
          end

          // End of for loop indicate Capacity miss
          if (DONE == 0) begin
            // Report MISS to monitor
            missCount = missCount + 1;

            for (i = 0; i < D_WAYS; i = i + 1) begin
              if (DONE == 0) begin
                // Check for the least recently used block
                if (D_LRUBits[index][i] == 3) begin
                  // Send data request to L2 cache
                  if (MODE == 1) begin
                    // Write-back 
                    if (D_Dirty[index][i] == 1) $display("[Data] Write back to L2");
                    $display("[Data] Read from L2 by Address: %h", address);
                  end
                  // Update stored tag
                  D_Tag[index][i] = tag;

                  D_LRU_replacement();
                  D_Valid[index][i] = 1;
                  DONE = 1;
                end
              end
            end
          end
          // Reset DONE to 0
          DONE = 0;
        end
        // ------------------------------------------------------
        1: begin
          // Examine each block in set
          for (i = 0; i < D_WAYS; i = i + 1) begin
            if (DONE == 0) begin
              // If there is data inside the block
              if (D_Valid[index][i] == 1) begin
                // If the tag is matched
                if (D_Tag[index][i] == tag) begin
                  // Report HIT to monitor
                  hitCount = hitCount + 1.0;
                  if (MODE == 1) begin
                    // Write-back
                    if (D_Dirty[index][i] == 1) begin
                      $display("[Data] Write back to L2");
                    end else $display("[Data] Write through to L2 by Address: %h", address);
                  end
                  D_LRU_replacement();
                  DONE = 1;
                  // Update dirty bit
                  D_Dirty[index][i] = 1;
                end
              end  // Compulsory miss
              else begin
                // Report MISS to monitor 
                missCount = missCount + 1;
                if (MODE == 1) begin
                  $display("[Data] Read from L2 by Address: %h", address);
                  $display("[Data] Write through to L2 by Address: %h", address);
                end
                // Update stored tag
                D_Tag[index][i] = tag;
                //Adjust LRU bits
                D_LRU_replacement();
                D_Valid[index][i] = 1;
                DONE = 1;
                // Update dirty bit
                D_Dirty[index][i] = 1;
              end
            end
          end

          // End of for loop indicate Capacity miss
          if (DONE == 0) begin
            // Report MISS to monitor
            missCount = missCount + 1;

            for (i = 0; i < D_WAYS; i = i + 1) begin
              if (DONE == 0) begin
                // Check for the least recently used block
                if (D_LRUBits[index][i] == 3) begin
                  // Pull from memory and overwrite the evicted line
                  if (MODE == 1) begin
                    // Write-back
                    if (D_Dirty[index][i] == 1) $display("[Data] Write back to L2");
                    $display("[Data] Read from L2 by Address: %h", address);
                    if (D_Dirty[index][i] == 0)
                      $display("[Data] Write through to L2 by Address: %h", address);
                  end

                  // Update stored tag
                  D_Tag[index][i] = tag;
                  // Adjust LRU bits
                  D_LRU_replacement();
                  D_Valid[index][i] = 1;
                  DONE = 1;
                  // Update dirty bit
                  D_Dirty[index][i] = 1;
                end
              end
            end
          end
          // Reset DONE to 0
          DONE = 0;
        end
        // ------------------------------------------------------
        2: begin
          // Examine each block in set
          for (i = 0; i < I_WAYS; i = i + 1) begin
            if (DONE == 0) begin
              // If there is data inside the block
              if (I_Valid[index][i] == 1) begin
                // If the tag is matched
                if (I_Tag[index][i] == tag) begin
                  // Report hit to monitor
                  hitCount = hitCount + 1;
                  // Adjust LRU bits
                  I_LRU_replacement();
                  DONE = 1;
                end
              end  // compulsory miss 
              else begin
                // Read from L2 cache
                if (MODE == 1) $display("[Instruction] Read from L2 by Address: %h", address);
                //Report MISS to monitor
                missCount = missCount + 1;
                // Update stored tag
                I_Tag[index][i] = tag;
                // Adjust LRU bits
                I_LRU_replacement();
                I_Valid[index][i] = 1;
                DONE = 1;
              end
            end
          end
          // End of for loop indicate Capacity miss
          if (DONE == 0) begin
            // Report MISS to monitor
            missCount = missCount + 1;

            for (i = 0; i < I_WAYS; i = i + 1) begin
              if (DONE == 0) begin
                // Check for the least recently used block
                if (I_LRUBits[index][i] == 1) begin

                  // Send data request to L2 cache
                  if (MODE == 1) begin
                    $display("[Instruction] Read from L2 by Address: %h", address);
                  end

                  // Update stored tag
                  I_Tag[index][i] = tag;

                  I_LRU_replacement();
                  I_Valid[index][i] = 1;
                  DONE = 1;
                end
              end
            end
          end
          // Reset DONE to 0
          DONE = 0;
        end
        // ------------------------------------------------------
        3: begin
          // Examine each block in set
          for (i = 0; i < D_WAYS; i = i + 1) begin
            if (DONE == 0) begin
              // If there is data inside the block
              if (D_Valid[index][i] == 1) begin
                // If the tag is matched
                if (D_Tag[index][i] == tag) begin
                  $display("Block in L1 cache is evicted");

                  // Update status
                  D_Valid[index][i] = 0;
                  D_Dirty[index][i] = 0;
                  D_Tag[index][i]   = {12{1'b0}};
                end
              end
            end
          end
        end
      endcase
    end

  endtask

  // ------------------------------------------------------
  // LRU replacement strategy
  task D_LRU_replacement;
    begin
      for (j = 0; j < D_WAYS; j = j + 1) begin
        if (D_LRUBits[index][j] <= D_LRUBits[index][i] || i != j)
          D_LRUBits[index][j] = D_LRUBits[index][j] + 1;
      end
      D_LRUBits[index][i] = 2'b00;
    end
  endtask

  task I_LRU_replacement;
    begin
      for (j = 0; j < I_WAYS; j = j + 1) begin
        if (I_LRUBits[index][j] <= I_LRUBits[index][i] || i != j)
          I_LRUBits[index][j] = I_LRUBits[index][j] + 1;
      end
      I_LRUBits[index][i] = 1'b0;
    end
  endtask

  // ------------------------------------------------------
  // Write the contents and states of the cache to stdout
  task write_out();
    begin
      // For data cache
      $display("\n------------- Data cache -------------");
      $display("WAYS   D_Dirty   D_Tag    D_LRU");
      for (i = 0; i < SETS; i = i + 1) begin
        for (j = 0; j < D_WAYS; j = j + 1) begin
          if (D_Valid[i][j] == 1) begin
            $display("%-6d %-9b %-8h %b ", D_WAYS, D_Dirty[i][j], D_Tag[i][j], D_LRUBits[i][j]);
          end
        end
      end
      $display("(End)");

      // For instruction cache
      $display("\n------------- Instruction cache -------------");
      $display("WAYS   I_Dirty   I_Tag    I_LRU");
      for (i = 0; i < SETS; i = i + 1) begin
        for (j = 0; j < I_WAYS; j = j + 1) begin
          if (I_Valid[i][j] == 1) begin
            $display("%-6d %-9b %-8h %b ", I_WAYS, I_Dirty[i][j], I_Tag[i][j], I_LRUBits[i][j]);
          end
        end
      end
      $display("(End)\n");
    end
  endtask
endmodule


