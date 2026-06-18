from django.conf import settings
from django.core.cache import cache
from django.db.models.signals import post_delete, post_save
from django.dispatch import receiver

from music.models import Profile, Song


@receiver(post_save, sender=settings.AUTH_USER_MODEL)
def create_user_profile(sender, instance, created, **kwargs):
    if created:
        Profile.objects.get_or_create(user=instance)


def _invalidate_feed_cache(**kwargs):
    cache.delete("feed:default")


post_save.connect(_invalidate_feed_cache, sender=Song)
post_delete.connect(_invalidate_feed_cache, sender=Song)
