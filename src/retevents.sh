#! /bin/bash

likwid-perfctr -e | grep ", PMC" | awk -F ',' '{print $1}' >> eventlist
