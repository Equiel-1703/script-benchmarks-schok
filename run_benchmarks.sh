#!/bin/bash

RUNS_PER_BENCHMARK=30 # CHANGE TO 30 LATER ----------------------------------------------------<<<

# Define directories for benchmarks
BENCHMARKS_CUDA_DIR="benchmarks/cuda"
BENCHMARKS_SCHOK_DIR="benchmarks/cola"
BENCHMARKS_NX_DIR="benchmarks/nx"

BENCHMARKS_ACCELERATE_DIR="benchmarks/accelerate"
EXIT_ACCELERATE_DIR="../.."

# Output directory
OUTPUT_DIR="benchmark-script-output"

# --- Functions for running benchmarks ---
run_cuda_benchmark() {
    local benchmark_name="$1"
    local benchmark_input="$2"
    
    local output_name="${benchmark_name%.cu}.out"
    
    # Compile the CUDA benchmark
    nvcc "$BENCHMARKS_CUDA_DIR/$benchmark_name" -o "$BENCHMARKS_CUDA_DIR/$output_name"
    
    local i # Loop variable
    
    # Run the compiled CUDA benchmark
    for ((i=1; i<=RUNS_PER_BENCHMARK; i++)); do
        "./$BENCHMARKS_CUDA_DIR/$output_name" "$benchmark_input" 2>&1
    done
}

run_elixir_benchmark() {
    local benchmark_file="$1"
    local benchmark_input="$2"
    
    local i # Loop variable
    
    for ((i=1; i<=RUNS_PER_BENCHMARK; i++)); do
        mix run "$benchmark_file" "$benchmark_input" 2>&1
    done
}

run_haskell_benchmark() {
    local benchmark_folder="$1"
    local benchmark_name="$2"
    local benchmark_input="$3"

    # Enter benchmark folder
    cd "$BENCHMARKS_ACCELERATE_DIR" || exit 1
    cd "$benchmark_folder" || exit 1

    # Build the project first
    cabal build

    local i # Loop variable
    
    # Run the benchmark
    for ((i=1; i<=RUNS_PER_BENCHMARK; i++)); do
        cabal run "$benchmark_name" -- "$benchmark_input" 2>&1
    done

    # Exit benchmark folder
    cd .. || exit 1
    cd "$EXIT_ACCELERATE_DIR" || exit 1
}

# --- Functions for running the benchmark in loop ---
run_all_cuda_benchmarks() {
    local inputs="$1"
    local bench_file_name="$2"
    local output_file="$OUTPUT_DIR/$3"
    local title="$4"

    echo -e "$title\n\n" > "$output_file"
    for input in $inputs; do
        run_cuda_benchmark "$bench_file_name" "$input" >> "$output_file"
        echo "" >> "$output_file"
    done
}

run_all_elixir_benchmarks() {
    local inputs="$1"
    local benchmark_file="$2"
    local output_file="$OUTPUT_DIR/$3"
    local title="$4"

    echo -e "$title\n\n" > "$output_file"
    for input in $inputs; do
        run_elixir_benchmark "$benchmark_file" "$input" >> "$output_file"
        echo "" >> "$output_file"
    done
}

run_all_haskell_benchmarks() {
    local inputs="$1"
    local benchmark_folder="$2"
    local benchmark_exec="$3"
    local output_file="$OUTPUT_DIR/$4"
    local title="$5"

    echo -e "$title\n\n" > "$output_file"
    for input in $inputs; do
        run_haskell_benchmark "$benchmark_folder" "$benchmark_exec" "$input" >> "$output_file"
        echo "" >> "$output_file"
    done
}

# ------------------ Script Start ------------------
mkdir -p "$OUTPUT_DIR"
LOGS_FILE="$OUTPUT_DIR/logs.txt"

echo -e "- $(basename "$PWD") Benchmarks Results -" > "$LOGS_FILE"
date >> "$LOGS_FILE"
echo -e "Tests conducted by: Andre R. Du Bois & Henrique G. Rodrigues\n" >> "$LOGS_FILE"
echo -e "Runs per benchmark: $RUNS_PER_BENCHMARK\n" >> "$LOGS_FILE"
echo "" >> "$LOGS_FILE"

# ------------------ Dot Product Benchmark ------------------
TITLE="Dot Product (DP) benchmark"
# INPUTS="1024 2048 4096" # Test values
INPUTS="300000000 400000000 500000000" # CHANGE TO THIS LATER ----------------------------------------------------<<<

echo "Running Dot Product benchmarks..." >> "$LOGS_FILE"

# CUDA
run_all_cuda_benchmarks "$INPUTS" "dotprod_twopass_double.cu" "dp_cuda.txt" "$TITLE"

# SCHok
run_all_elixir_benchmarks "$INPUTS" "$BENCHMARKS_SCHOK_DIR/dot_product_double.ex" "dp_schok.txt" "$TITLE"

# Nx
run_all_elixir_benchmarks "$INPUTS" "$BENCHMARKS_NX_DIR/dot_product.ex" "dp_nx.txt" "$TITLE"

# Accelerate
run_all_haskell_benchmarks "$INPUTS" "dp-double" "dotprod-double" "dp_accelerate.txt" "$TITLE"

# Accelerate Warmup
run_all_haskell_benchmarks "$INPUTS" "dp-double" "dotprod-double-warmup" "dp_accelerate_warm.txt" "$TITLE"

# ------------------ Julia Benchmark ------------------
TITLE="Julia (JL) benchmark"
# INPUTS="512 1024 2048" # Test values
INPUTS="10000 17000 20000" # CHANGE TO THIS LATER ----------------------------------------------------<<<

echo "Running Julia benchmarks..." >> "$LOGS_FILE"

# CUDA
run_all_cuda_benchmarks "$INPUTS" "julia_int.cu" "julia_cuda.txt" "$TITLE"

# SCHok
run_all_elixir_benchmarks "$INPUTS" "$BENCHMARKS_SCHOK_DIR/julia.ex" "julia_schok.txt" "$TITLE"

# Nx
run_all_elixir_benchmarks "$INPUTS" "$BENCHMARKS_NX_DIR/julia.ex" "julia_nx.txt" "$TITLE"

# Accelerate
run_all_haskell_benchmarks "$INPUTS" "julia" "accelerate-julia" "julia_accelerate.txt" "$TITLE"

# Accelerate Warmup
run_all_haskell_benchmarks "$INPUTS" "julia-warmup" "accelerate-julia-warm" "julia_accelerate_warm.txt" "$TITLE"

# ------------------ Nearest Neighbor Benchmarks ------------------
TITLE="Nearest Neighbor (NN) benchmark"
# INPUTS="1024 2048 4096" # Test values
INPUTS="800000000 900000000 1000000000" # CHANGE TO THIS LATER ----------------------------------------------------<<<

echo "Running NN benchmarks..." >> "$LOGS_FILE"

# CUDA
run_all_cuda_benchmarks "$INPUTS" "nearest_neighbor_twophasereduce.cu" "nn_cuda.txt" "$TITLE"

# SCHok
run_all_elixir_benchmarks "$INPUTS" "$BENCHMARKS_SCHOK_DIR/nearest_neighbor_twopassreduce.ex" "nn_schok.txt" "$TITLE"

# Nx
run_all_elixir_benchmarks "$INPUTS" "$BENCHMARKS_NX_DIR/nearest_neighbor.ex" "nn_nx.txt" "$TITLE"

# Accelerate
run_all_haskell_benchmarks "$INPUTS" "nn" "nn-accelerate" "nn_accelerate.txt" "$TITLE"

# Accelerate Warmup
run_all_haskell_benchmarks "$INPUTS" "nn-warmup" "nn-warm" "nn_accelerate_warm.txt" "$TITLE"

echo "Done!" >> "$LOGS_FILE"

# ------------------ Script End ------------------