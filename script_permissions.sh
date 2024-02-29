#!/bin/bash

chown www-data:www-data -R ./www
find ./www -type d -exec chmod 755 {} \;
find ./www -type f -exec chmod 644 {} \;