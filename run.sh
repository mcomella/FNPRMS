#!/usr/bin/env bash

iamhere=${BASH_SOURCE%/*}
iwashere=`pwd`
cd ${iamhere}

. common.sh

function run {
  apk=$1
  shift
  start_command=$1

  $ADB uninstall org.mozilla.fenix.nightly > /dev/null 2>&1
  $ADB install -t ${apk}

  if [ $? -ne 0 ]; then
    echo 'Error occurred installing the APK!' > ${log_file}
  else
    echo "Starting by using ${start_command}"
    $ADB shell "${start_command}"
  fi
}

homeactivity_start_command='am start-activity org.mozilla.fenix.nightly/org.mozilla.fenix.HomeActivity'
applink_start_command='am start-activity -t "text/html" -d "about:blank" -a android.intent.action.VIEW org.mozilla.fenix.nightly/org.mozilla.fenix.IntentReceiverActivity'
apk_url_template="https://index.taskcluster.net/v1/task/project.mobile.fenix.v2.nightly.DATE.latest/artifacts/public/build/armeabi-v7a/geckoNightly/target.apk"
log_dir=/home/hawkinsw/run_logs/
test_date=`date +"%Y.%m.%-d"`
log_base=${test_date}
downloaded_apk_path=`printf "%s/%s/" \`pwd\` \`date +"%Y/%m/%-d"\``;
downloaded_apk_file=`printf "%s/%s" ${downloaded_apk_path} nightly.apk`;
apk_downloaded=0
apk_download_attempts=5

{
  for i in `seq 1 ${apk_download_attempts}`; do
    download_apk ${apk_url_template} ${test_date} ${downloaded_apk_file}
    result=$?
    if [ ${result} -eq 0 ]; then
      apk_downloaded=1
      break
    fi
    echo "Trying again to download the nightly apk (error ${result})."
  done

  if [ ${apk_downloaded} -eq 0 ]; then
    echo "Error: Failed to download an APK."
  else
    echo "Running Fenix"
    run ${downloaded_apk_file} "${homeactivity_start_command}"
  fi
}

cd ${iwashere}