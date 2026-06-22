import datetime
import logging
import socket
import time
import urllib.error
import urllib.request

from airflow import DAG
from airflow.operators.python_operator import PythonOperator


LOGGER = logging.getLogger(__name__)


default_args = {
	'start_date': datetime.datetime(2000, 1, 1),
	'retries': 1,
	'retry_delay': datetime.timedelta(minutes=5),
}


def check_cloud_run_endpoint(endpoint_url, timeout_seconds=30, **kwargs):
	"""Validate that the endpoint is reachable from Composer.

	Connectivity is considered successful if a response is received,
	even when the HTTP status code is 4xx/5xx.
	"""
	task_instance = kwargs.get('task_instance')
	request = urllib.request.Request(endpoint_url, method='GET')
	start_time = time.time()

	LOGGER.info("Starting connectivity check for endpoint: %s", endpoint_url)

	try:
		with urllib.request.urlopen(request, timeout=timeout_seconds) as response:
			status_code = response.getcode()
			response_headers = dict(response.getheaders())
			response_body = response.read(1024).decode('utf-8', errors='replace')
			duration_seconds = round(time.time() - start_time, 3)

			result = {
				'endpoint': endpoint_url,
				'reachable': True,
				'status_code': status_code,
				'duration_seconds': duration_seconds,
				'response_headers': response_headers,
				'response_body_preview': response_body,
			}

			LOGGER.info(
				"✓ SUCCESS: Endpoint %s responded with HTTP %s in %ss",
				endpoint_url,
				status_code,
				duration_seconds,
			)
			LOGGER.info("Response headers: %s", response_headers)
			LOGGER.info("Response body: %s", response_body)

			# Push to XCom for visibility in Airflow UI event log
			if task_instance:
				task_instance.xcom_push(key='endpoint_response', value=result)
				task_instance.xcom_push(key='response_summary',
					value=f"✓ SUCCESS: HTTP {status_code} | Duration: {duration_seconds}s | Body: {response_body[:100]}")

			return result
	except urllib.error.HTTPError as http_error:
		# HTTPError still confirms DNS/TLS/network path and service reachability.
		response_body = http_error.read(1024).decode('utf-8', errors='replace')
		duration_seconds = round(time.time() - start_time, 3)

		result = {
			'endpoint': endpoint_url,
			'reachable': True,
			'status_code': http_error.code,
			'duration_seconds': duration_seconds,
			'response_headers': dict(http_error.headers.items()) if http_error.headers else {},
			'response_body_preview': response_body,
		}

		LOGGER.warning(
			"⚠ HTTP ERROR: Endpoint %s returned HTTP %s in %ss (still reachable)",
			endpoint_url,
			http_error.code,
			duration_seconds,
		)
		LOGGER.warning(
			"Error response headers: %s",
			dict(http_error.headers.items()) if http_error.headers else {},
		)
		LOGGER.warning("Error response body: %s", response_body)

		# Push to XCom for visibility in Airflow UI event log
		if task_instance:
			task_instance.xcom_push(key='endpoint_response', value=result)
			task_instance.xcom_push(key='response_summary',
				value=f"⚠ HTTP {http_error.code}: {response_body[:100]}")

		return result
	except (urllib.error.URLError, socket.timeout, TimeoutError) as network_error:
		duration_seconds = round(time.time() - start_time, 3)
		error_msg = str(network_error)

		result = {
			'endpoint': endpoint_url,
			'reachable': False,
			'error': error_msg,
			'duration_seconds': duration_seconds,
		}

		LOGGER.error(
			"✗ FAILED: Connectivity check failed for %s after %ss: %s",
			endpoint_url,
			duration_seconds,
			network_error,
		)

		# Push to XCom for visibility in Airflow UI event log
		if task_instance:
			task_instance.xcom_push(key='endpoint_response', value=result)
			task_instance.xcom_push(key='response_summary',
				value=f"✗ FAILED: {error_msg}")

		raise RuntimeError(
			f"Connectivity check failed for {endpoint_url}: {network_error}"
		) from network_error


dag = DAG(
	'test_cloud_run_connectivity',
	default_args=default_args,
	description='Test Composer connectivity to Cloud Run endpoints',
	schedule=None,
	max_active_runs=2,
	catchup=False,
	dagrun_timeout=datetime.timedelta(minutes=10),
)


test_connector_short_url = PythonOperator(
	task_id='test_connector_short_url',
	python_callable=check_cloud_run_endpoint,
	op_kwargs={
		'endpoint_url': 'https://dapo-test-connector-e5qzspb2aq-nw.a.run.app',
		'timeout_seconds': 30,
	},
	dag=dag,
)


test_connector_regional_url = PythonOperator(
	task_id='test_connector_regional_url',
	python_callable=check_cloud_run_endpoint,
	op_kwargs={
		'endpoint_url': 'https://dapo-test-connector-995315591721.europe-west2.run.app',
		'timeout_seconds': 30,
	},
	dag=dag,
)


test_connector_short_url >> test_connector_regional_url
