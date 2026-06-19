import datetime

from airflow import DAG
from airflow.operators.python_operator import PythonOperator
from airflow.providers.google.cloud.sensors.gcs  import GCSObjectExistenceSensor

try:
    from airflow.providers.google.cloud.transfers.gcs_to_gcs import GCSToGCSOperator
except ImportError:
    from airflow.providers.google.cloud.operators.gcs_to_gcs import GCSToGCSOperator

try:
    from airflow.providers.google.cloud.operators.gcs_to_bigquery import GCSToBigQueryOperator
except ImportError:
    from airflow.providers.google.cloud.transfers.gcs_to_bigquery import GCSToBigQueryOperator
    


# pylint: disable=g-import-not-at-top
try:
  from airflow.providers.standard.operators.bash import BashOperator
except ImportError:
  from airflow.operators.bash_operator import BashOperator
# pylint: enable=g-import-not-at-top

source_data = 'employee_data.csv'
  
default_args = {
    'start_date': datetime.datetime(2000, 1, 1),
    'retries': 1,
    'retry_delay': datetime.timedelta(minutes=5),
}


dag = DAG(
    'gcstobq_test',
    default_args=default_args,
    description='Basic Dag',
    schedule=None,
    max_active_runs=2,
    catchup=False,
    dagrun_timeout=datetime.timedelta(minutes=10),
)

# priority_weight has type int in Airflow DB, uses the maximum.

check_file = GCSObjectExistenceSensor(
    task_id='check_file',
    bucket='ola-composer-test-bucket',
    object=source_data,
    timeout=200,
    poke_interval=10,
    dag=dag,
    )

load_csv = GCSToBigQueryOperator(
    task_id='load_csv',
    bucket='ola-composer-test-bucket',
    source_objects=[source_data],
    destination_project_dataset_table='abl-data-engineering-dev.olas_airflow_test.employee_data',
    source_format='CSV',
    skip_leading_rows=1,
    write_disposition='WRITE_TRUNCATE',
    autodetect=True,
    dag=dag,
    
    )

move_file = GCSToGCSOperator(
    task_id='move_file',
    source_bucket='ola-composer-test-bucket',
    source_objects=[source_data],
    destination_bucket='ola-composer-test-bucket',
    destination_object=f'processed/{source_data}',
    move_object=True,
    dag=dag,
    )




# Set task dependencies
check_file >> load_csv >> move_file
