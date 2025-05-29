#!/bin/bash
# LockWhenGone v0.0.1
# Author: Paul Biswell
# Repository: https://github.com/pbiswell/lockwhengone
# Website: https://paulbiswell.co.uk

# Fixes looped file checks
shopt -s lastpipe

# Initialisation variables
config="./config.conf"
version="0.0.1"
verbose=false
req=()
some=()
never=()
cRed='\033[1;41m';
cPurp='\033[0;95m';
cGreen='\033[0;92m';
cYellow='\033[0;93m';
cCyan='\033[0;96m';
nColor='\033[0m';
thanksMsg=$(cat << EndOfThanks
  Found this useful? Consider starring the repo or donating.
  More info in the links above. Thank you.
EndOfThanks
)
versionInfo=$(cat << EndOfVersion
  LockWhenGone v$version
  
  Author: Paul Biswell
  Repository: https://github.com/pbiswell/lockwhengone
  Website: https://paulbiswell.co.uk
EndOfVersion
)
help=$(cat << EndOfHelp
  Information
  ----------
$versionInfo

  Usage
  ----------
  lockwhengone.sh [OPTIONS]

  Options
  ----------
  -v --verbose       : Verbose/detailed output for debugging.
  
  --version          : Version information.
  
  -h --help          : Display this help information.
  
  -c [FILE]          : Use specific config file.
  
  -d -disable-colors : Disable colored output.
  ----------
  
$thanksMsg
EndOfHelp
)

function disableColors(){
  "$verbose" && echo "Disabling colors";
  cRed=""
  cPurp=""
  cCyan=""
  cGreen=""
  cYellow=""
  nColor=""
}

# GET COMMAND LINE ARGUMENTS
while [ $# -gt 0 ] ; do
  case $1 in
    -d | -disable-colors | --disable-colors) disableColors; shift ;;
    -v | -verbose | --verbose) verbose=true; echo "Verbose mode enabled"; shift ;;
    -h | -help | --help) printf "$help\n"; exit 0; ;;
    -version | --version) printf "$versionInfo\n\n$thanksMsg\n"; exit 0; ;;
    -c) if [ $# -ge 2 ]; then 
          config=$2; echo "Loading config: $2"; 
        else 
          echo -e "${cRed}Must specify config file, exiting...${nColor}";
          exit 1;
        fi
        shift 2;
        ;;
    *)  echo -e "${cRed}Error parsing command line arguments: $1${nColor}"; 
        exit 1;
        ;;
  esac
done

# LOAD CONFIG
if [ ! -f $config ]; then
  echo "Config file '$config' not found, exiting...";
  exit 1;
else
  . $config
  if [ $COLOR_OUTPUT -eq 0 ]; then
    disableColors;
  fi
fi

# CONFIG CHECK REQUIRED VARIABLES
"$verbose" && echo -e "${cCyan}Validating config: '$config'${nColor}";
if [[ ! -v LOOP ]]; then
  echo "LOOP must exist in config.conf, exiting...";
  exit 1;
fi
if [[ ! -v EXIT_ACTION ]]; then
  echo "EXIT_ACTION must exist in config.conf, exiting...";
  exit 1;
fi
if [[ ! -v MIN_DEVICES ]]; then
  echo "MIN_DEVICES must exist in config.conf, exiting...";
  exit 1;
fi
if [[ ! -v USB_SCAN ]]; then
  echo "USB_SCAN must exist in config.conf, exiting...";
  exit 1;
fi
if [[ ! -v NETWORK_SCAN ]]; then
  echo "NETWORK_SCAN must exist in config.conf, exiting...";
  exit 1;
fi
if [[ ! -v BLUETOOTH_SCAN ]]; then
  echo "BLUETOOTH_SCAN must exist in config.conf, exiting...";
  exit 1;
fi
if [[ ! -v SKIP_FILE ]]; then
  echo "SKIP_FILE must exist in config.conf, exiting...";
  exit 1;
fi
if [[ ! -v ENABLE_SKIP_FILE ]]; then
  echo "ENABLE_SKIP_FILE must exist in config.conf, exiting...";
  exit 1;
fi
if [[ ! -v SHUTDOWN_COMMAND ]]; then
  echo "SHUTDOWN_COMMAND must exist in config.conf, exiting...";
  exit 1;
fi
if [[ ! -v REBOOT_COMMAND ]]; then
  echo "REBOOT_COMMAND must exist in config.conf, exiting...";
  exit 1;
fi
if [[ ! -v LOCK_COMMAND ]]; then
  echo "LOCK_COMMAND must exist in config.conf, exiting...";
  exit 1;
fi
"$verbose" && echo -e "${cGreen}Config validation success${nColor}";

# POPULATE ARRAYS FUNCTION
function populate(){
  "$verbose" && echo -e "${cCyan}Processing file: $1${nColor}";
  if [ ! -f $1 ]; then
    echo -e "${cRed}File not found:${nColor} $1";
    if [ $EXIT_ON_ERROR -eq 1 ]; then
      echo -e "${cRed}Running exit action $EXIT_ACTION because EXIT_ON_ERROR=1${nColor}";
      exitAction;
    fi
    return;
  fi
  local arr=();
  declare -gn ArrRef=$2;
  cat $1 | while read line 
  do
    if [[ $line =~ ^#.* ]]; then
      # Line is a comment
      continue;
    else
      arr+=( $line );
    fi
  done
  ArrRef=${arr[*]};
}

# EXIT ACTION FUNCTION - BY DEFAULT LOCKS COMPUTER
function exitAction(){
  case $EXIT_ACTION in
    "lock")
      echo -e ">>> ${cRed}RUNNING EXIT ACTION: LOCK${nColor} <<<";
      eval $LOCK_COMMAND;
      ;;
    "shutdown")
      echo -e ">>> ${cRed}RUNNING EXIT ACTION: SHUTDOWN${nColor} <<<";
      eval $SHUTDOWN_COMMAND;
      ;;
    "reboot")
      echo -e ">>> ${cRed}RUNNING EXIT ACTION: REBOOT${nColor} <<<";
      eval $REBOOT_COMMAND;
      ;;
    "script")
      echo -e ">>> ${cRed}RUNNING EXIT ACTION: SCRIPT${nColor} <<<";
      $EXIT_SCRIPT;
      ;;
    "debug")
      echo -e ">>> ${cRed}DEBUG: EXIT ACTION TRIGGERED${nColor} <<<";
      ;;
    *)
      echo "Unknown exit action: $EXIT_ACTION";
      echo "Check your config.conf";
      ;;
  esac
}

# DEVICE CHECKER FUNCTION
function checkDevice(){
  # $1 : Line from file to check, something like usb:XXXX:XXXX
  # $2 : Run exit action?
  #      0 = No
  #      1 = Exit on found
  #      2 = Exit on not found
  # $3 : Variable to increment when not triggering exit action
  foundType=-1
  if [[ $1 =~ ^usb:.* ]]; then
    if eval $USB_SCAN | grep ${1#*:} -q; then
      "$verbose" && echo "Found: ${1#*:}";
      foundType=1
    else
      "$verbose" && echo "Not found: ${1#*:}";
      foundType=2
    fi
  elif [[ $1 =~ ^bluetooth:.* ]]; then
    if eval $BLUETOOTH_SCAN | grep ${1#*:} -q; then
      "$verbose" && echo "Found: ${1#*:}";
      foundType=1
    else
      "$verbose" && echo "Not found: ${1#*:}";
      foundType=2
    fi
  elif [[ $1 =~ ^network:.* ]]; then
    if eval $NETWORK_SCAN | grep ${1#*:} -q; then
      "$verbose" && echo "Found: ${1#*:}";
      foundType=1
    else
      "$verbose" && echo "Not found: ${1#*:}";
      foundType=2
    fi
  else
    echo "Unknown device type: $1";
  fi
  # INCREMENT VARIABLE
  if [[ $2 -eq 1 && $2 -eq $foundType ]] || ( [[ $2 -eq 2 || $2 -eq 0 ]] && [[ $2 -ne $foundType ]] ); then
    declare -gn IncRef=$3;
    ((IncRef++));
  fi
  # RUN EXIT ACTION ON CONDITION
  if [ $2 = $foundType ]; then
    echo -e "${cCyan}Running exit action: $EXIT_ACTION${nColor}";
    exitAction;
  fi
}

# VERBOSE STARTING INFORMATION
"$verbose" && echo "Exit action: $EXIT_ACTION";

# MAIN LOOP
runloop=1
while [ $runloop = 1 ]; do
  
  skip=0;
  keepChecking=true;
  # SKIP FILE CHECKS
  "$verbose" && echo -e "${cCyan}Running skip file checks${nColor}";
  if [ $ENABLE_SKIP_FILE = 1 ]; then
    "$verbose" && echo "Skip file check enabled";
    if [ ! -f $SKIP_FILE ]; then
      "$verbose" && echo "Skip file not found: $SKIP_FILE";
    else
      "$verbose" && echo "Skip file found: $SKIP_FILE";
      echo "Skipping all checks because skip file exists: $SKIP_FILE";
      skip=1;
    fi
  else
    "$verbose" && echo "Skip file check disabled";
  fi

  if [ $skip = 0 ]; then
    exited=false
    # RELOAD DEVICES FROM FILE
    populate "./not-allowed.txt" never
    populate "./all-required.txt" req
    populate "./some-required.txt" some
    
    # CHECK FOR DISALLOWED DEVICES
    if "$keepChecking"; then
      "$verbose" && echo -e "${cCyan}Checking for disallowed devices${nColor}";
      neverInc=0
      neverLen=0
      for device in ${never[@]}; do
        "$keepChecking" && checkDevice $device 1 neverInc;
        "$keepChecking" && ((neverLen++));
        if "$keepChecking" && [ $neverInc -ge 1 ]; then
          keepChecking=false;
          "$verbose" && echo "Stopping further checks, too many disallowed devices found.";
          exited=true;
        fi
      done
      "$verbose" && echo "$neverInc of $neverLen disallowed devices found.";
    else
      "$verbose" && echo "Skipping disallowed devices checks, exit action already triggered";
    fi
    
    # CHECK FOR REQUIRED DEVICES
    if "$keepChecking"; then
      "$verbose" && echo -e "${cCyan}Checking for required devices${nColor}";
      reqInc=0
      reqLen=0
      for device in ${req[@]}; do
        "$keepChecking" && checkDevice $device 2 reqInc;
        "$keepChecking" && ((reqLen++));
        if "$keepChecking" && [ $reqInc -lt $reqLen ]; then
          keepChecking=false;
          exited=true;
          "$verbose" && echo -e "Stopping further checks, not enough required devices found.";
        fi
      done
      "$verbose" && echo "$reqInc of $reqLen required devices found.";
    else 
      "$verbose" && echo "Skipping required devices checks, exit action already triggered";
    fi
    
    # CHECK FOR SOME-REQUIRED DEVICES
    if "$keepChecking"; then
      "$verbose" && echo -e "${cCyan}Checking for some-required devices. Minimum required: $MIN_DEVICES${nColor}";
      someInc=0
      someLen=0
      for device in ${some[@]}; do
        "$keepChecking" && checkDevice $device 0 someInc;
        "$keepChecking" && ((someLen++));
        if "$keepChecking" && [ $someInc -ge $MIN_DEVICES ]; then
          keepChecking=false;
          "$verbose" && echo "Stopping further checks because enough found.";
        fi
      done
      "$verbose" && echo "$someInc of $someLen some-required devices found. Minimum required: $MIN_DEVICES";
      [ $someLen -eq 0 ] && "$verbose" && echo "No devices in some-required list, skipping exit action.";
      if [[ $someInc -lt $MIN_DEVICES && $someLen -gt 0 ]]; then
        "$verbose" && echo "Triggered exit action, not enough devices were found";
        exitAction;
        exited=true;
      fi
    else 
      "$verbose" && echo "Skipping some-devices checks, exit action already triggered";
    fi
    if [ "$exited" = true ]; then
      echo -e "${cPurp}Failed: The exit action was triggered.${nColor}";
    else
      echo -e "${cGreen}Success: Completed all checks without triggering exit action.${nColor}";
    fi
  fi
  if [ "$LOOP" = 0 ]; then
    "$verbose" && echo "Not looping script";
    runloop=0;
  else
    "$verbose" && echo "Sleeping for $SCAN_INTERVAL seconds before running again. Press CTRL+C to exit script.";
    sleep $SCAN_INTERVAL;
  fi
done
