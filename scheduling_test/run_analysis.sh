#!/bin/bash


run_nomad_job() {
    local JOB_FILE="$1"
    local JOB_NAME="$2"
    local RUNS="${3:-1}"  # Default to 1 run if not provided

    echo "🚀 Submitting base parameterized job: $JOB_NAME"
    nomad job run -detach "$JOB_FILE" > /dev/null

    # --- Loop and Dispatch ---
    for i in $(seq 1 $RUNS); do
        DISPATCH_ID="run-$(date +%s)-$i"
        echo -e "\n--- Dispatch $i of $COUNT (ID: $DISPATCH_ID) ---"
    
        EVAL_ID=$(nomad job dispatch -detach -meta "DISPATCH_ID=$DISPATCH_ID" "$JOB_NAME" | awk '/Evaluation ID/ { print $4 }')

        if [ -z "$EVAL_ID" ] || [ "$EVAL_ID" == "null" ]; then
	    echo "❌ Dispatch failed. Output: $EVAL_OUTPUT"
	    continue
        fi

        INSTANCE_JOB_ID=$(nomad job status -json "$JOB_NAME" | jq -r '.[].Evaluations[0].JobID')
        echo "  Waiting for job $INSTANCE_JOB_ID to complete..."
        INSTANCE_JOB_ID_ESC=$(echo "$INSTANCE_JOB_ID" | sed 's/\//\\\//')

        while true; do
	    STATUS=$(nomad job status "$JOB_NAME" | grep "$INSTANCE_JOB_ID_ESC" | awk '{ print $2 }')
    
	    if [ "$STATUS" = "dead" ]; then
	        break
	    fi
	
	    echo "Waiting for job to complete . . . sleeping"
	    sleep 2
        done

        echo " "
        echo "  Job completed. Extracting timings..."
        ALLOC_ID=$(nomad job status -json "$INSTANCE_JOB_ID" | jq -r '.[].Allocations[0].ID')
        RUN_TIME_NS=$(nomad alloc status -json $ALLOC_ID | jq -r '(.TaskStates.latency.Events[-1].Time - .TaskStates.latency.Events[0].Time)')
        TOTAL_RUN_TIME_NS=$((TOTAL_RUN_TIME_NS + RUN_TIME_NS))
        SUCCESSFUL_RUNS=$((SUCCESSFUL_RUNS + 1))
        nomad job stop -purge "$INSTANCE_JOB_ID" > /dev/null 2>&1
    done

    nomad job stop -purge "$JOB_NAME" > /dev/null 2>&1

    if [ "$SUCCESSFUL_RUNS" -gt 0 ]; then
        local AVG_RUN_TIME_NS=$(echo "scale=0; $TOTAL_RUN_TIME_NS / $SUCCESSFUL_RUNS" | bc)
        local AVG_RUN_TIME_MS=$(echo "scale=3; $AVG_RUN_TIME_NS / 1000000" | bc)
        PAD1="      "
        PAD2="    "
        echo "$JOB_NAME,$SUCCESSFUL_RUNS,$PAD1,$AVG_RUN_TIME_MS,$PAD2,$AVG_RUN_TIME_NS" >> $$
    else
        echo "$JOB_ID,0,0,0" >> $$ 
    fi
}

run_nomad_job "test_job.nomad.hcl" "duration-test" 10

echo -e "\n\n=========================================="
echo "📊 Nomad Job Performance Analysis"
echo "=========================================="
echo ""

echo "Job            Runs        Avg Time(ms)    Avg Time(ns)"
column -t -s ',' "$$"
rm $$ 
