#!/bin/sh
###################################################################################
#  Job Name: exhrymos_obs.sh.ecf
#
#  Purpose: To extract metar observations from bufrtanks, perform gross QC and
#           write ASCII files with obs.
#
#  Remarks: The sfctbl.* files produced in this job script are used as MDL's offical
#           metar observation archive.
#
#  History: Aug  5,  1996     - standardize and add SMS hooks 
#           Aug  5,  1996     - added qsub to kick off MDL job 
#           Nov 18,  1999 RLA - set up script to test hrlytbl job on the IBM SP.
#           Mar  8,  2002 RLC - fixed if test associate with the llsubmit.
#           Apr 15,  2004 RLC - Made changes to dumpjb setup.  Now use mneumonic for  
#                               tank instead of the 000 007, and use form=ibm so the  
#                               file name for unit 42 is different.
#           Dec 03,  2012 EFE - Transitioned to WCOSS (Linux). Changed
#                               all 'XLFUNIT_  ' env vars to 'FORT  '.
#                               Modified script comments
#           Jan 16,  2013 EFE - Changed syntax for $lines; Changed syntax for
#                               $stations to conform to bash shell arithmetic;
#                               Further cleaned up the script; Removed the copying
#                               of ncepdate file into $DATA, not needed.
#           Nov  5,  2018 SDS - Migrated to Phase 3 (Dell)
##################################################################################
echo MDLLOG: `date` - Begin job exhrymos_obs

set -x

cd $DATA

#   Print information
set +x
echo "------------------------------------------------------"
echo "           IBM/WCOSS $envir PROCESSING                "
echo " Date: `date`                                         "
echo " Processing executable environment is ......... $envir"
echo " Temporary processing file directory is .......  $DATA"
echo " unique machine processing id is ................ $pid"
echo "------------------------------------------------------"
set -x

#   Establish date variables
echo "PDY=$PDY"
echo "HOUR=$HOUR"
export DAT="$PDY$cyc"
export PDH="$PDY$HOUR"
export dumpjb=$DUMPJB
###export bufrsh=/nwprod/ush

#################################################
#
#   Begin processing hourly files
# 
#   DUMP SURFACE METAR DATA, TYPE 000 SUBTYPE 007
# 
#################################################
hour=$HOUR
msg="Processing hour ${HOUR}Z."
echo "$msg"

msg="The Dump for $PDH has started."
echo "$msg"

time $dumpjb $PDH 0.25 metar

cat metar.out >> $pgmout

msg="The Dump has ended."
echo "$msg"

msg="Creating the MDL Hourly Table." 
echo "$msg"
#######################################################################
#
# PROGRAM HRLYTBL - MOS-2000 PROGRAM TO PERFORM GROSS QUALITY CONTROL
#                   METAR OBS AND CREATE ASCII FILES OF OBS.
#######################################################################
export pgm=mdl_hrlytbl
. prep_step
export FORT30="ncepdate" 
export FORT42="metar.ibm" 
export FORT60="sfctbl.$PDH" 
export FORT70="rawmetar.$PDH" 
export FORT80="bufrmetar.$PDH" 
startmsg
$EXECcode/mdl_hrlytbl >> $pgmout 2> errfile
export err=$?;err_chk

sort bufrmetar.$PDH >> sfctbl.$PDH
sort -o rawmetar.$PDH rawmetar.$PDH
 
echo -e "\nThe following files were created: \n"
ls -al *.$PDH
 
lines=`wc -l sfctbl.$PDH | cut -d" " -f 1`
stations=$(( $lines - 3 ))

msg="$stations STATIONS WERE PROCESSED"
echo "$msg"

if test "$SENDCOM" = 'YES'
then
   cp sfctbl.$PDH $COMOUT/sfctbl.$HOUR
   cp rawmetar.$PDH $COMOUT/rawmetar.$HOUR
   cp metar.ibm $COMOUT/hrymos_bufr.$HOUR
fi

echo MDLLOG: `date` - Job exhrymos_obs has ended.
# ----------------- END OF EXHRYMOS_OBS SCRIPT ----------------
