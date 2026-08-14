from django.db import models


class TimeStampedModel(models.Model):
    """Abstract base model providing created/updated timestamps.

    Reusable base for concrete models defined by this app or by host projects.
    """

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        abstract = True
