"""
DAG: test_cloud_run_connection
Purpose: Test public connectivity from Cloud Composer to Cloud Run endpoints.
Endpoints:
- https://dapo-test-connector-e5qzspb2aq-nw.a.run.app
- https://dapo-test-connector-995315591721.europe-west2.run.app

Validation: each endpoint must return HTTP 2xx and contain "hello world"
in the response body (case-insensitive).
"""

import logging
from datetime import timedelta

import pendulum
import requests

from airflow import DAG
from airflow.decorators import task
from airflow.exceptions import AirflowException
from airflow.models.param import Param

log = logging.getLogger(__name__)

CLOUD_RUN_URLS = [
    "https://dapo-test-connector-e5qzspb2aq-nw.a.run.app",
    "https://dapo-test-connector-995315591721.europe-west2.run.app",
]
EXPECTED_TEXT = "hello world"

DEFAULT_ARGS = {
    "owner": "dapo",
    "depends_on_past": False,
    "retries": 3,
    "retry_delay": timedelta(minutes=1),
    "retry_exponential_backoff": True,
    "max_retry_delay": timedelta(minutes=5),
}


with DAG(
    dag_id="test_cloud_run_connection",
    description="Test public endpoint response from Composer to Cloud Run",
    default_args=DEFAULT_ARGS,
    start_date=pendulum.yesterday("UTC").at(0, 1),
    schedule=None,  # Manual trigger only
    dagrun_timeout=timedelta(minutes=15),
    catchup=False,
    max_active_runs=1,
    is_paused_upon_creation=True,
    params={
        "urls": Param(
            default=CLOUD_RUN_URLS,
            type="array",
            description="Public Cloud Run endpoints to test.",
        ),
        "expected_text": Param(
            default=EXPECTED_TEXT,
            type="string",
            description="Expected phrase in endpoint response body.",
        ),
        "timeout_seconds": Param(
            default=30,
            type="integer",
            minimum=1,
            maximum=120,
            description="Per-request timeout in seconds.",
        ),
    },
    tags=["connectivity", "cloud-run", "gcp", "test"],
) as dag:
    @task(task_id="validate_parameters")
    def validate_parameters(params: dict) -> dict:
        urls = params.get("urls", [])
        expected_text = params.get("expected_text", "")
        timeout_seconds = params.get("timeout_seconds", 30)

        if not isinstance(urls, list) or not urls:
            raise AirflowException("Parameter 'urls' must be a non-empty list.")
        if not isinstance(expected_text, str) or not expected_text.strip():
            raise AirflowException("Parameter 'expected_text' must be a non-empty string.")
        if not isinstance(timeout_seconds, int) or timeout_seconds <= 0:
            raise AirflowException("Parameter 'timeout_seconds' must be a positive integer.")

        for url in urls:
            if not isinstance(url, str) or not url.startswith("https://"):
                raise AirflowException(
                    f"Invalid URL '{url}'. Only HTTPS URLs are allowed."
                )

        sanitized = {
            "urls": urls,
            "expected_text": expected_text.strip(),
            "timeout_seconds": timeout_seconds,
        }
        log.info("PARAMETERS_VALIDATED: %s", sanitized)
        return sanitized

    @task(task_id="test_cloud_run_endpoints")
    def test_cloud_run_endpoints(validated: dict) -> dict:
        """
        Make unauthenticated GET requests to each public endpoint and verify
        that the response is HTTP 2xx and contains expected_text.
        """
        urls = validated["urls"]
        expected_text = validated["expected_text"]
        timeout_seconds = validated["timeout_seconds"]

        summary = {
            "expected_text": expected_text,
            "timeout_seconds": timeout_seconds,
            "results": [],
        }
        failures = []

        for url in urls:
            log.info("Sending public GET request to %s", url)
            try:
                response = requests.get(url, timeout=timeout_seconds)
                body = response.text or ""
                contains_expected = expected_text.lower() in body.lower()

                result = {
                    "url": url,
                    "status_code": response.status_code,
                    "ok": response.ok,
                    "contains_expected_text": contains_expected,
                    "response_body": body[:2000],
                }
                summary["results"].append(result)

                # Structured logs make it easier to filter in Cloud Logging.
                log.info("CLOUD_RUN_TEST_RESULT: %s", result)

                if not response.ok:
                    failures.append(f"{url} returned HTTP {response.status_code}")
                elif not contains_expected:
                    failures.append(
                        f"{url} did not contain expected text '{expected_text}' in body"
                    )
            except requests.RequestException as exc:
                failure_result = {
                    "url": url,
                    "ok": False,
                    "error": str(exc),
                }
                summary["results"].append(failure_result)
                log.exception("CLOUD_RUN_TEST_EXCEPTION for %s", url)
                failures.append(f"{url} request failed: {exc}")

        if failures:
            summary["failures"] = failures
            raise AirflowException(f"Cloud Run public endpoint test failed: {summary}")

        log.info("Cloud Run public endpoint tests passed.")
        return summary

    validated_config = validate_parameters(dag.params)
    test_cloud_run_endpoints(validated_config)
