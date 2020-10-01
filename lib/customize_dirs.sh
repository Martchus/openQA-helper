# allow customizing some directories
os_autoinst_dir=${CUSTOM_OS_AUTOINST_DIR:-os-autoinst}
if [[ $CUSTOM_MOJO_IO_LOOP_READ_WRITE_PROCESS ]]; then
    read_write_process_path=$OPENQA_BASEDIR/repos/Mojo-IOLoop-ReadWriteProcess/lib
    if [[ ! -f $read_write_process_path/Mojo/IOLoop/ReadWriteProcess.pm ]]; then
        echo "Unable to find Mojo-IOLoop-ReadWriteProcess under $read_write_process_path."
        exit -1
    fi
    export PERL5LIB=$read_write_process_path:$PERL5LIB
fi
echo "PERL5LIB: $PERL5LIB"
