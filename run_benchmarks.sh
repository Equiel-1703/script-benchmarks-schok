#!/bin/bash

RUNS_PER_BENCHMARK=1 # CHANGE TO 30 LATER ----------------------------------------------------<<<

# Define directories for benchmarks
BENCHMARKS_CUDA_DIR="benchmarks/cuda"
BENCHMARKS_SCHOK_DIR="benchmarks/cola"
BENCHMARKS_NX_DIR="benchmarks/nx"

BENCHMARKS_ACCELERATE_DIR="benchmarks/accelerate"
EXIT_ACCELERATE_DIR="../.."

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
        "./$BENCHMARKS_CUDA_DIR/$output_name" $benchmark_input 2>&1
    done
}

run_elixir_benchmark() {
    local benchmark_folder="$1"
    local benchmark_name="$2"
    local benchmark_input="$3"
    
    local i # Loop variable
    
    for ((i=1; i<=RUNS_PER_BENCHMARK; i++)); do
        mix run $benchmark_folder/$benchmark_name $benchmark_input 2>&1
    done
}

run_haskell_benchmark() {
    local benchmark_folder="$1"
    local benchmark_name="$2"
    local benchmark_input="$3"

    # Enter benchmark folder
    cd $BENCHMARKS_ACCELERATE_DIR
    cd $benchmark_folder

    # Build the project first
    cabal build

    local i # Loop variable
    
    # Run the benchmark
    for ((i=1; i<=RUNS_PER_BENCHMARK; i++)); do
        cabal run $benchmark_name $benchmark_input 2>&1
    done

    # Exit benchmark folder
    cd ..
    cd $EXIT_ACCELERATE_DIR
}

# ------------------ Script Start ------------------
echo -e "- $(basename "$PWD") Benchmarks Results -"
date
echo -e "Tests conducted by: Andre R. Du Bois & Henrique G. Rodrigues\n"
echo -e "Runs per benchmark: $RUNS_PER_BENCHMARK\n"
echo ""  # Add a blank line for readability

# ------------------ Dot Product Benchmark ------------------
INPUTS="1024 2048 4096" # Test values
# INPUTS="400000000 500000000 600000000" # CHANGE TO THIS LATER ----------------------------------------------------<<<

echo -e "Dot Product (DP) benchmark\n"

# CUDA
for INPUT in $INPUTS; do
    run_cuda_benchmark "dotprod_twopass_double.cu" "$INPUT" > "dp_cuda.txt"
done

# SCHok
for INPUT in $INPUTS; do
    run_elixir_benchmark $BENCHMARKS_SCHOK_DIR "dot_product_double.ex" "$INPUT" > "dp_schok.txt"
done

# Nx
for INPUT in $INPUTS; do
    run_elixir_benchmark $BENCHMARKS_NX_DIR "dot_product.ex" "$INPUT" > "dp_nx.txt"
done

# Accelerate
for INPUT in $INPUTS; do
    run_haskell_benchmark "dp-double" "dotprod-double" "$INPUT" > "dp_accelerate.txt"
done

# Accelerate Warmup
for INPUT in $INPUTS; do
    run_haskell_benchmark "dp-double" "dotprod-double-warmup" "$INPUT" > "dp_accelerate_warm.txt"
done

echo ""

# ------------------ Julia Benchmark ------------------
INPUTS="512 1024 2048" # Test values
# INPUTS="7168 9216 11264" # CHANGE TO THIS LATER ----------------------------------------------------<<<

echo -e "Julia (JL) benchmark\n"

# CUDA
for INPUT in $INPUTS; do
    run_cuda_benchmark "julia_int.cu" "$INPUT" > "julia_cuda.txt"
done

# SCHok
for INPUT in $INPUTS; do
    run_elixir_benchmark $BENCHMARKS_SCHOK_DIR "julia.ex" "$INPUT" > "julia_schok.txt"
done

# Nx
for INPUT in $INPUTS; do
    run_elixir_benchmark $BENCHMARKS_NX_DIR "julia.ex" "$INPUT" > "julia_nx.txt"
done

# Accelerate
for INPUT in $INPUTS; do
    run_haskell_benchmark "julia" "accelerate-julia" "$INPUT" > "julia_accelerate.txt"
done

# Accelerate Warmup
for INPUT in $INPUTS; do
    run_haskell_benchmark "julia-warmup" "accelerate-julia-warm" "$INPUT" > "julia_accelerate_warm.txt"
done

echo ""

# ------------------ Nearest Neighbor Benchmarks ------------------
INPUTS="1024 2048 4096" # Test values
# INPUTS="100000000 200000000 300000000" # CHANGE TO THIS LATER ----------------------------------------------------<<<

echo -e "Nearest Neighbor (NN) benchmark\n"

# CUDA
for INPUT in $INPUTS; do
    run_cuda_benchmark "nearest_neighbor_twophasereduce.cu" "$INPUT" > "nn_cuda.txt"
done

# SCHok
for INPUT in $INPUTS; do
    run_elixir_benchmark $BENCHMARKS_SCHOK_DIR "nearest_neighbor_twopassreduce.ex" "$INPUT" > "nn_schok.txt"
done

# Nx
for INPUT in $INPUTS; do
    run_elixir_benchmark $BENCHMARKS_NX_DIR "nearest_neighbor.ex" "$INPUT" > "nn_nx.txt"
done

# Accelerate
for INPUT in $INPUTS; do
    run_haskell_benchmark "nn" "nn-accelerate" "$INPUT" > "nn_accelerate.txt"
done

# Accelerate Warmup
for INPUT in $INPUTS; do
    run_haskell_benchmark "nn-warmup" "nn-warm" "$INPUT" > "nn_accelerate_warm.txt"
done

echo ""

# ------------------ Script End ------------------