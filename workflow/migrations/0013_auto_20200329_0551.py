# Generated by Django 2.2.10 on 2020-03-29 12:51

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('workflow', '0012_auto_20200329_0539'),
    ]

    operations = [
        migrations.RenameField(
            model_name='historicalprojectagreement',
            old_name='status',
            new_name='project_status',
        ),
        migrations.RenameField(
            model_name='projectagreement',
            old_name='status',
            new_name='project_status',
        ),
    ]
