"""agent-kit: DAG integrity test — copy to tests/ (Airflow projects). Fails CI when a DAG cannot be imported."""
import pytest
from airflow.models import DagBag


@pytest.fixture(scope="session")
def dagbag() -> DagBag:
    return DagBag(dag_folder="dags", include_examples=False)


def test_no_import_errors(dagbag: DagBag) -> None:
    assert dagbag.import_errors == {}, f"DAG import errors: {dagbag.import_errors}"


def test_dags_have_owner_and_retries(dagbag: DagBag) -> None:
    for dag_id, dag in dagbag.dags.items():
        assert dag.default_args.get("owner"), f"{dag_id}: default_args.owner missing"
        assert dag.default_args.get("retries", 0) >= 1, f"{dag_id}: retries must be >= 1"
