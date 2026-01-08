from flask import Flask, request, jsonify
import requests
import os
import logging
from datetime import datetime
import time

app = Flask(__name__)
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Configuration
AGENT_TYPE = os.getenv('AGENT_TYPE', 'unknown-worker')
CONSUL_DOMAIN = os.getenv('CONSUL_DOMAIN', 'service.consul')

# Simulated processing capabilities per agent type
AGENT_CAPABILITIES = {
    'research': 'Performs research and information gathering tasks',
    'code': 'Handles code generation, analysis, and refactoring',
    'data': 'Processes data operations, transformations, and analytics',
    'analysis': 'Conducts analytical tasks and generates insights'
}

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint for Kubernetes and load balancers"""
    return jsonify({
        'status': 'healthy',
        'agent': AGENT_TYPE,
        'capability': AGENT_CAPABILITIES.get(AGENT_TYPE, 'General purpose worker'),
        'timestamp': datetime.utcnow().isoformat()
    }), 200

@app.route('/process', methods=['POST'])
def process():
    """
    Main processing endpoint that accepts tasks from the orchestrator.

    This endpoint simulates the worker performing its specialized task.
    In a real implementation, this would integrate with LLM APIs, databases,
    or other AI services.

    Expected JSON payload:
    {
        "task": "Task description",
        "from": "orchestrator",
        "timestamp": "ISO timestamp"
    }
    """
    data = request.json or {}
    task = data.get('task', 'No task provided')
    from_agent = data.get('from', 'unknown')
    request_timestamp = data.get('timestamp', 'unknown')

    logger.info(f"[{AGENT_TYPE}] Received task from {from_agent}: {task}")

    # Simulate processing time (0.1-0.5 seconds)
    processing_time = 0.1 + (hash(task) % 5) / 10.0
    time.sleep(processing_time)

    # Generate agent-specific response
    result = generate_agent_response(task)

    response_data = {
        'agent': AGENT_TYPE,
        'agent_type': AGENT_TYPE,
        'capability': AGENT_CAPABILITIES.get(AGENT_TYPE, 'General purpose worker'),
        'task': task,
        'from': from_agent,
        'result': result,
        'processing_time_seconds': round(processing_time, 3),
        'request_timestamp': request_timestamp,
        'response_timestamp': datetime.utcnow().isoformat(),
        'status': 'completed'
    }

    logger.info(f"[{AGENT_TYPE}] Completed task in {processing_time:.3f}s")

    return jsonify(response_data), 200

def generate_agent_response(task):
    """Generate a simulated response based on agent type"""

    responses = {
        'research': f"Research findings for '{task}': Gathered information from 5 sources, identified 3 key insights, compiled comprehensive report.",
        'code': f"Code analysis for '{task}': Generated 50 lines of code, applied best practices, added documentation and tests.",
        'data': f"Data processing for '{task}': Processed 1000 records, applied transformations, generated visualizations and summary statistics.",
        'analysis': f"Analysis results for '{task}': Identified patterns, performed statistical analysis, generated 5 actionable recommendations."
    }

    return responses.get(AGENT_TYPE, f"Worker {AGENT_TYPE} processed: {task}")

@app.route('/test-peer-call', methods=['POST'])
def test_peer_call():
    """
    Test endpoint to demonstrate blocked worker-to-worker communication.

    This endpoint attempts to call another worker agent, which should FAIL
    due to Consul service mesh intentions blocking lateral movement.

    Expected JSON payload:
    {
        "target": "code-agent"  # Target worker to call
    }
    """
    data = request.json or {}
    target_worker = data.get('target', 'research-agent')

    # Ensure we're not calling ourselves
    if target_worker == f"{AGENT_TYPE}-agent":
        return jsonify({
            'status': 'invalid',
            'message': 'Cannot call self',
            'agent': AGENT_TYPE,
            'target': target_worker
        }), 400

    target_url = f"http://{target_worker}.{CONSUL_DOMAIN}:8080/health"

    logger.info(f"[{AGENT_TYPE}] Attempting to call peer worker: {target_worker}")

    try:
        response = requests.get(target_url, timeout=5)

        # This should NOT succeed if intentions are properly configured
        logger.warning(f"[{AGENT_TYPE}] ⚠️ Successfully called {target_worker} - Intentions may not be working!")

        return jsonify({
            'status': 'unexpected_success',
            'agent': AGENT_TYPE,
            'target': target_worker,
            'url': target_url,
            'message': '⚠️ Worker-to-worker call succeeded! This should be blocked by Consul intentions.',
            'response': response.json() if response.status_code == 200 else response.text,
            'security_note': 'This indicates lateral movement is possible. Check Consul intentions configuration.'
        }), 200

    except requests.exceptions.ConnectionError as e:
        # This is EXPECTED - connection should be blocked by Consul
        logger.info(f"[{AGENT_TYPE}] ✓ Connection to {target_worker} blocked as expected")

        return jsonify({
            'status': 'blocked_as_expected',
            'agent': AGENT_TYPE,
            'target': target_worker,
            'url': target_url,
            'message': '✓ Worker-to-worker communication blocked by Consul service mesh intentions',
            'error': str(e),
            'security_note': 'This is correct behavior. Workers should only be callable by the orchestrator.'
        }), 403

    except requests.exceptions.Timeout:
        logger.info(f"[{AGENT_TYPE}] ✓ Request to {target_worker} timed out (likely blocked)")

        return jsonify({
            'status': 'timeout',
            'agent': AGENT_TYPE,
            'target': target_worker,
            'url': target_url,
            'message': 'Request timed out - likely blocked by Consul intentions',
            'security_note': 'Timeout suggests connection was prevented by service mesh.'
        }), 403

    except Exception as e:
        logger.error(f"[{AGENT_TYPE}] Error calling {target_worker}: {e}")

        return jsonify({
            'status': 'error',
            'agent': AGENT_TYPE,
            'target': target_worker,
            'url': target_url,
            'error': str(e),
            'error_type': type(e).__name__
        }), 500

@app.route('/', methods=['GET'])
def index():
    """Root endpoint with worker information"""
    return jsonify({
        'service': f'AI Worker Agent - {AGENT_TYPE}',
        'version': '1.0',
        'agent_type': AGENT_TYPE,
        'capability': AGENT_CAPABILITIES.get(AGENT_TYPE, 'General purpose worker'),
        'endpoints': {
            '/health': 'GET - Health check',
            '/process': 'POST - Process task from orchestrator',
            '/test-peer-call': 'POST - Test worker-to-worker call (should be blocked)'
        },
        'security': {
            'allowed_callers': ['orchestrator-agent'],
            'blocked_callers': ['*-agent (other workers)']
        }
    }), 200

if __name__ == '__main__':
    logger.info(f"Starting {AGENT_TYPE} worker agent on port 8080")
    logger.info(f"Capability: {AGENT_CAPABILITIES.get(AGENT_TYPE, 'General purpose worker')}")
    app.run(host='0.0.0.0', port=8080, debug=False)
