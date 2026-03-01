#!/bin/bash
# Usa wttr.in o similar (ejemplo simple)
curl -s 'wttr.in/Tijuana?format=%c+%t' | sed 's/+//'
