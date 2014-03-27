sh ./dyplo_example.sh 0

if [ ! -f bitstreams/static.bit ]
then
	echo "No(t all) bitstreams generated"
	exit 1
fi

# Create the "main" file for the OE part
mv bitstreams/static.bit fpga.bit

