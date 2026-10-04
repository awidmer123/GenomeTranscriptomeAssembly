# This script will create the necessary directory setup. Run this first.
# Afterwards submit manually scripts 01-04.
# When script 01-04 succesfully ran, execute "run_pipeline.sh".

PROJECT_DIR="$(pwd)"
mkdir -p "${PROJECT_DIR}"/{data,logs,results,scripts}
echo "Project structure created in ${PROJECT_DIR}"
