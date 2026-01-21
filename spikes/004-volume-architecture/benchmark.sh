#!/bin/bash
# Volume Performance Benchmark Script
# Tests I/O performance for different mount strategies

set -e

RESULTS_DIR="/tmp/benchmark-results"
TEST_SIZE="${TEST_SIZE:-100}"  # MB for file operations

mkdir -p "$RESULTS_DIR"

echo "=== Volume Performance Benchmark ==="
echo "Test size: ${TEST_SIZE}MB"
echo "Results: $RESULTS_DIR"
echo ""

# Function to benchmark file operations
benchmark_io() {
    local test_dir="$1"
    local label="$2"

    echo "--- Testing: $label ---"
    echo "Directory: $test_dir"

    # Ensure test directory exists and is writable
    if ! mkdir -p "$test_dir" 2>/dev/null; then
        echo "SKIP: Cannot create $test_dir"
        return
    fi

    cd "$test_dir"

    # Test 1: Sequential write (dd)
    echo -n "  Sequential write: "
    write_result=$(dd if=/dev/zero of=testfile bs=1M count=$TEST_SIZE 2>&1 | tail -1)
    write_speed=$(echo "$write_result" | grep -oE '[0-9.]+ [MG]B/s' || echo "N/A")
    echo "$write_speed"

    # Test 2: Sequential read
    echo -n "  Sequential read:  "
    # Clear cache if possible (requires root)
    sync 2>/dev/null || true
    read_result=$(dd if=testfile of=/dev/null bs=1M 2>&1 | tail -1)
    read_speed=$(echo "$read_result" | grep -oE '[0-9.]+ [MG]B/s' || echo "N/A")
    echo "$read_speed"

    # Test 3: Many small files (simulates node_modules)
    echo -n "  Create 1000 files: "
    start_time=$(date +%s)
    for i in $(seq 1 1000); do
        echo "content $i" > "small_$i.txt"
    done
    end_time=$(date +%s)
    create_time=$((end_time - start_time))
    echo "${create_time}s"

    # Test 4: Read many small files
    echo -n "  Read 1000 files:   "
    start_time=$(date +%s)
    for i in $(seq 1 1000); do
        cat "small_$i.txt" > /dev/null
    done
    end_time=$(date +%s)
    read_time=$((end_time - start_time))
    echo "${read_time}s"

    # Test 5: Delete many files
    echo -n "  Delete 1000 files: "
    start_time=$(date +%s)
    rm -f small_*.txt
    end_time=$(date +%s)
    delete_time=$((end_time - start_time))
    echo "${delete_time}s"

    # Cleanup
    rm -f testfile

    # Write results to CSV
    echo "$label,$write_speed,$read_speed,$create_time,$read_time,$delete_time" >> "$RESULTS_DIR/benchmark.csv"

    echo ""
}

# Initialize CSV
echo "mount_type,write_speed,read_speed,create_1000_files,read_1000_files,delete_1000_files" > "$RESULTS_DIR/benchmark.csv"

# Test each configured directory
# These will be set via environment or mount points
if [ -d "/workspace" ]; then
    benchmark_io "/workspace/benchmark-test" "workspace-bind"
fi

if [ -d "/named-vol" ]; then
    benchmark_io "/named-vol/benchmark-test" "named-volume"
fi

if [ -d "/home/dev/local-test" ] || mkdir -p /home/dev/local-test 2>/dev/null; then
    benchmark_io "/home/dev/local-test" "container-local"
fi

# Summary
echo "=== Benchmark Complete ==="
echo "Results saved to: $RESULTS_DIR/benchmark.csv"
cat "$RESULTS_DIR/benchmark.csv"
