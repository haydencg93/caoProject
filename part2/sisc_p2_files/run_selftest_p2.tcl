# ============================================================================
# ECE:3350 SISC Part 2 Self-Test - ModelSim TCL Script
# ============================================================================
#
# Usage:
#   1. Place all self-test files in your project directory.
#   2. In ModelSim transcript:  source run_selftest_p2.tcl
#   3. Run:  run_checkpoint_test   (recommended)
#        or: run_main_test
#
# IMPORTANT: This script temporarily replaces your imem.data with the Part 2
# test program, then restores it when done. Your original imem.data is safe.
#
# ============================================================================

proc compile_all {} {
    vlog alu.v br.v ctrl.v im.v ir.v mux32.v pc.v rf.v statreg.v sisc.v
}

proc setup_p2_data {} {
    if {[file exists imem.data]} {
        file copy -force imem.data imem.data.bak
    }
    if {[file exists imem_p2_test.data]} {
        file copy -force imem_p2_test.data imem.data
    } else {
        puts "ERROR: imem_p2_test.data not found!"
        puts "  Make sure it is in your project directory."
        return 0
    }
    return 1
}

proc restore_data {} {
    if {[file exists imem.data.bak]} {
        file copy -force imem.data.bak imem.data
        file delete imem.data.bak
    }
}

proc run_main_test {} {
    puts "============================================================"
    puts "  Part 2 Self-Test: Main (final values only)"
    puts "============================================================"
    
    if {![setup_p2_data]} { return }
    
    compile_all
    vlog autograder_p2_tb.v
    
    vsim -t 100ps sisc_p2_autograder_tb
    
    puts "  Running simulation..."
    run -all
    
    restore_data
    
    puts "  Test complete. Review output above."
    puts "============================================================"
}

proc run_checkpoint_test {} {
    puts "============================================================"
    puts "  Part 2 Self-Test: Checkpoints (per-section feedback)"
    puts "============================================================"
    
    if {![setup_p2_data]} { return }
    
    compile_all
    vlog autograder_p2_checkpoint_tb.v
    
    vsim -t 100ps sisc_p2_checkpoint_tb
    
    puts "  Running simulation with per-section checkpoints..."
    run -all
    
    restore_data
    
    puts "  Checkpoint test complete. Review output above."
    puts "============================================================"
}

puts ""
puts "ECE:3350 SISC Part 2 Self-Test loaded."
puts "Available commands:"
puts "  run_checkpoint_test  - Check values at each section boundary (recommended)"
puts "  run_main_test        - Check final register values only"
puts ""
