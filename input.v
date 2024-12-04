module input_arguments(
    output integer file,
    output integer mode
);
  initial begin
    string fileName;
    // Read command line arguments
    if ($value$plusargs("FILE=%s", fileName)) $display("File name is: %s", fileName);
    // Assign the value directly to output
    if ($value$plusargs("MODE=%0d", mode)) $display("Mode: %9d\n", mode);
    // Read the file
    file = $fopen(fileName, "r");
  end
endmodule
