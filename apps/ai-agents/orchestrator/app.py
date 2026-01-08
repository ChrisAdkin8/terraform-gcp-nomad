from flask import Flask, request, jsonify
import requests
import os
import logging
from datetime import datetime

app = Flask(__name__)
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Configuration
AGENT_TYPE = os.getenv('AGENT_TYPE', 'orchestrator')
WORKER_SERVICES = os.getenv('WORKER_SERVICES', 'research-agent,code-agent,data-agent,analysis-agent').split(',')
CONSUL_DOMAIN = os.getenv('CONSUL_DOMAIN', 'service.consul')

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint for Kubernetes and load balancers"""
    return jsonify({
        'status': 'healthy',
        'agent': AGENT_TYPE,
        'workers': WORKER_SERVICES,
        'timestamp': datetime.utcnow().isoformat()
    }), 200

@app.route('/analyze', methods=['POST'])
def analyze():
    """
    Main orchestration endpoint that delegates tasks to worker agents.

    This endpoint demonstrates the hierarchical agent pattern where the
    orchestrator distributes work to specialized workers and aggregates results.

    Expected JSON payload:
    {
        "task": "Description of the task to perform",
        "timeout": 5  # Optional timeout in seconds
    }
    """
    data = request.json or {}
    task = data.get('task', 'No task specified')
    timeout = data.get('timeout', 5)

    logger.info(f"Received task: {task}")

    results = {}
    errors = {}

    # Delegate work to each worker agent via Consul DNS
    for worker in WORKER_SERVICES:
        worker_name = worker.strip()
        worker_url = f"http://{worker_name}.{CONSUL_DOMAIN}:8080/process"

        logger.info(f"Calling worker: {worker_name} at {worker_url}")

        try:
            response = requests.post(
                worker_url,
                json={
                    'task': task,
                    'from': AGENT_TYPE,
                    'timestamp': datetime.utcnow().isoformat()
                },
                timeout=timeout
            )

            if response.status_code == 200:
                results[worker_name] = response.json()
                logger.info(f"✓ {worker_name} completed successfully")
            else:
                errors[worker_name] = {
                    'status_code': response.status_code,
                    'error': response.text
                }
                logger.error(f"✗ {worker_name} returned status {response.status_code}")

        except requests.exceptions.Timeout:
            errors[worker_name] = {'error': 'Request timeout'}
            logger.error(f"✗ {worker_name} timed out")
        except requests.exceptions.ConnectionError as e:
            errors[worker_name] = {'error': f'Connection error: {str(e)}'}
            logger.error(f"✗ {worker_name} connection failed: {e}")
        except Exception as e:
            errors[worker_name] = {'error': str(e)}
            logger.error(f"✗ {worker_name} unexpected error: {e}")

    # Aggregate response
    response_data = {
        'orchestrator': AGENT_TYPE,
        'status': 'completed',
        'task': task,
        'workers_succeeded': len(results),
        'workers_failed': len(errors),
        'results': results,
        'timestamp': datetime.utcnow().isoformat()
    }

    # Include errors if any occurred
    if errors:
        response_data['errors'] = errors

    status_code = 200 if not errors else 207  # 207 = Multi-Status
    return jsonify(response_data), status_code

@app.route('/test-worker', methods=['POST'])
def test_worker():
    """
    Test endpoint to verify connectivity to a specific worker agent.

    Useful for debugging and demonstrating allowed Consul intentions.

    Expected JSON payload:
    {
        "worker": "research-agent"  # Name of worker to test
    }
    """
    data = request.json or {}
    worker = data.get('worker', 'research-agent')

    worker_url = f"http://{worker}.{CONSUL_DOMAIN}:8080/health"

    logger.info(f"Testing connectivity to worker: {worker}")

    try:
        response = requests.get(worker_url, timeout=5)

        return jsonify({
            'status': 'success',
            'worker': worker,
            'url': worker_url,
            'response': response.json(),
            'message': f'Successfully connected to {worker}'
        }), 200

    except Exception as e:
        logger.error(f"Failed to connect to {worker}: {e}")
        return jsonify({
            'status': 'failed',
            'worker': worker,
            'url': worker_url,
            'error': str(e),
            'message': f'Failed to connect to {worker}. Check Consul intentions.'
        }), 500

@app.route('/', methods=['GET'])
def index():
    """Root endpoint with API information"""
    return jsonify({
        'service': 'AI Agent Orchestrator',
        'version': '1.0',
        'agent_type': AGENT_TYPE,
        'workers': WORKER_SERVICES,
        'endpoints': {
            '/health': 'GET - Health check',
            '/analyze': 'POST - Delegate task to all workers',
            '/test-worker': 'POST - Test connectivity to specific worker'
        },
        'documentation': 'https://github.com/anthropics/terraform-gcp-nomad/tree/main/tf/scenarios/gke-ai-agents'
    }), 200

if __name__ == '__main__':
    logger.info(f"Starting {AGENT_TYPE} agent on port 8080")
    logger.info(f"Configured workers: {WORKER_SERVICES}")
    app.run(host='0.0.0.0', port=8080, debug=False)
