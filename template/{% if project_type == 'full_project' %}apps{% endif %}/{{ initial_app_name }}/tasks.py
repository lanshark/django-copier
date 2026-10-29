import logging

import structlog
from django_tasks import task

logger = logging.getLogger(__name__)


@task()
def example_background_task(user_id: int, request_id: str = "") -> None:
    """Trivial example task run via the RQ backend (or immediately in tests).

    `request_id` is optional and, when passed by the caller (typically
    `request.request_id`, set by `config.logging.RequestContextMiddleware`),
    ties this task's logs back to the request that enqueued it. django-tasks
    workers run in a separate process, so structlog's request-scoped context
    doesn't cross over on its own - it has to be passed in explicitly.
    """
    if request_id:
        structlog.contextvars.bind_contextvars(request_id=request_id)
    logger.info("Running example_background_task for user_id=%s", user_id)
