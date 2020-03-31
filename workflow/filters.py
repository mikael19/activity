#!/usr/bin/python3
# -*- coding: utf-8 -*-

import django_filters
from .models import ProjectAgreement


class ProjectAgreementFilter(django_filters.FilterSet):

    class Meta:
        model = ProjectAgreement
        fields = ['activity_code', 'project_name',
                  'individual_type', 'program', 'sector']

    def __init__(self, *args, **kwargs):
        super(ProjectAgreementFilter, self).__init__(*args, **kwargs)
