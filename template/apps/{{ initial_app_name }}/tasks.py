import logging

from django_tasks import task

logger = logging.getLogger(__name__)


@task()
def example_background_task(user_id: int) -> None:
    """Trivial example task run via the RQ backend (or immediately in tests)."""
    logger.info("Running example_background_task for user_id=%s", user_id)
