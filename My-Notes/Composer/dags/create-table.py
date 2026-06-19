import datetime

from airflow import DAG
from airflow.operators.python_operator import PythonOperator
from airflow.providers.google.cloud.sensors.gcs  import GCSObjectExistenceSensor
from airflow.providers.google.cloud.operators.bigquery import BigQueryCreateTableOperator
from airflow.providers.google.cloud.operators.bigquery import BigQueryGetDataOperator

try:
    from airflow.providers.google.cloud.transfers.gcs_to_gcs import GCSToGCSOperator
except ImportError:
    from airflow.providers.google.cloud.operators.gcs_to_gcs import GCSToGCSOperator

try:
    from airflow.providers.google.cloud.operators.gcs_to_bigquery import GCSToBigQueryOperator
except ImportError:
    from airflow.providers.google.cloud.transfers.gcs_to_bigquery import GCSToBigQueryOperator

try:
  from airflow.providers.standard.operators.bash import BashOperator
except ImportError:
  from airflow.operators.bash_operator import BashOperator


source_data = 'employee_data.csv'
BUCKET_NAME = 'ola-composer-test-bucket'
PROJECT_ID = 'abl-data-engineering-dev'
DATASET_ID = 'olas_airflow_test'
TABLE_ID = 'employee_data'
FULL_TABLE_NAME = f"{PROJECT_ID}.{DATASET_ID}.{TABLE_ID}"
  
default_args = {
    'start_date': datetime.datetime(2000, 1, 1),
    'retries': 1,
    'retry_delay': datetime.timedelta(minutes=5),
}


def print_data(**kwargs):
    ti = kwargs['ti']
    data = ti.xcom_pull(task_ids='get_data')
    if data:
        for row in data:
            print(row)
    else:
        print("No data returned.")



dag = DAG(
    'gcstobq_table_test',
    default_args=default_args,
    description='Basic Dag',
    schedule=None,
    max_active_runs=2,
    catchup=False,
    dagrun_timeout=datetime.timedelta(minutes=10),
)


check_file = GCSObjectExistenceSensor(
    task_id='check_file',
    bucket=BUCKET_NAME,
    object=source_data,
    timeout=200,
    poke_interval=10,
    dag=dag,
    )

create_table = BigQueryCreateTableOperator(
    task_id="create_table",
    dataset_id=DATASET_ID,
    table_id=TABLE_ID,
    project_id=PROJECT_ID,
    table_resource={
        "schema": {
            "fields": [
                {"name": "EmployeeID", "type": "INTEGER", "mode": "NULLABLE"},
                {"name": "FirstName", "type": "STRING", "mode": "NULLABLE"},
                {"name": "LastName", "type": "STRING", "mode": "NULLABLE"},
                {"name": "Department", "type": "STRING", "mode": "NULLABLE"},
                {"name": "Position", "type": "STRING", "mode": "NULLABLE"},
                {"name": "Salary", "type": "INTEGER", "mode": "NULLABLE"},
                {"name": "JoiningDate", "type": "DATE", "mode": "NULLABLE"},
                {"name": "Country", "type": "STRING", "mode": "NULLABLE"},
            ]
        }
    },
    dag=dag,
)

load_csv = GCSToBigQueryOperator(
    task_id='load_csv',
    bucket=BUCKET_NAME,
    source_objects=[source_data],
    destination_project_dataset_table=FULL_TABLE_NAME,
    source_format='CSV',
    skip_leading_rows=1,
    write_disposition='WRITE_TRUNCATE',
    autodetect=True,
    dag=dag,
    
    )

move_file = GCSToGCSOperator(
    task_id='move_file',
    source_bucket=BUCKET_NAME,
    source_objects=[source_data],
    destination_bucket=BUCKET_NAME,
    destination_object=f'processed/{source_data}',
    move_object=True,
    dag=dag,
    )

get_data = BigQueryGetDataOperator(
    project_id=PROJECT_ID,
    task_id="get_data",
    dataset_id=DATASET_ID,
    table_id=TABLE_ID,
    max_results=10,
    selected_fields="EmployeeID,FirstName,Department,Salary,Country",
)


show_data = PythonOperator(
    task_id="show_data",
    python_callable=print_data,
    provide_context=True,
)
    


check_file >> create_table >> load_csv >> move_file >> get_data >> show_data
