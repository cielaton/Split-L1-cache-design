module input_arguments(
    output integer file,
    output integer mode
);
  initial begin
    string fileName;
    // Read command line arguments
    if ($value$plusargs("FILE=%s", fileName)) $display("STANDBY argument is found ...");
    // Assign the value directly to output
    if ($value$plusargs("MODE=%0d", mode)) $display("STANDBY argument is found ...");
    // Read the file
    file = $fopen(fileName, "r");
  end
endmodule
