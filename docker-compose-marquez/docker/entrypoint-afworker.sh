#!/bin/bash

echo "Installing Java on airflow-worker"

# Install Java
apt-get update
apt-get install -y openjdk-11-jdk
apt-get clean

# Set JAVA_HOME
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64/

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purposes

# Load Airflow environment variables
. /opt/bitnami/scripts/airflow-worker-env.sh

# Load libraries
. /opt/bitnami/scripts/libbitnami.sh
. /opt/bitnami/scripts/libairflowworker.sh

print_welcome_page

if ! am_i_root && [[ -e "$LIBNSS_WRAPPER_PATH" ]]; then
    info "Enabling non-root system user with nss_wrapper"
    echo "airflow:x:$(id -u):$(id -g):Airflow:$AIRFLOW_HOME:/bin/false" > "$NSS_WRAPPER_PASSWD"
    echo "airflow:x:$(id -g):" > "$NSS_WRAPPER_GROUP"

    export LD_PRELOAD="$LIBNSS_WRAPPER_PATH"
    export HOME="$AIRFLOW_HOME"
fi

# Install custom python package if requirements.txt is present
if [[ -f "/bitnami/python/requirements.txt" ]]; then
    . /opt/bitnami/airflow/venv/bin/activate
    pip install -r /bitnami/python/requirements.txt
    deactivate
fi

if [[ "$*" = *"/opt/bitnami/scripts/airflow-worker/run.sh"* || "$*" = *"/run.sh"* ]]; then
    info "** Starting Airflow setup **"
    /opt/bitnami/scripts/airflow-worker/setup.sh
    info "** Airflow setup finished! **"
fi

echo ""
exec "$@"
