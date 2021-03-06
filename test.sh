# Build the database with one thread
echo "Building the database"
./target/debug/bigs_id build -s 750000 -n 4 -k 27 -b ./test_data/phage.bxi -r ./test_data/ref_file.txt
if [ $? -gt 0 ]; then
  echo "ERROR building bigs_id database ./test_data/phage.bxi using ./test_data/ref_file.txt";
  exit 1
fi

# Build the database with two threads
echo "Building the database"
./target/debug/bigs_id build -s 750000 -n 4 -k 27 -b ./test_data/phage.bxi -r ./test_data/ref_file.txt -t 2
if [ $? -gt 0 ]; then
  echo "ERROR building bigs_id database ./test_data/phage.bxi using ./test_data/ref_file.txt";
  exit 1
fi

#simple read classifier
echo "Classifying reads"
./target/debug/bigs_id read_id -b ./test_data/phage.bxi -q ./test_data/SRR548019.fastq.gz > classification.out
if [ $? -gt 0 ]; then
  echo "ERROR classifying reads ./test_data/SRR548019.fastq.gz with ./test_data/phage.bxi"
  exit 1
fi


# Query the database: create test.out but remove the
# file when this script ends.
echo "Querying the database"
trap " { rm -vf test.out; rm -vf classification.out; } " EXIT
./target/debug/bigs_id search -b ./test_data/phage.bxi -q ./test_data/SRR548019.fastq.gz -f 1 > test.out
if [ $? -gt 0 ]; then
  echo "ERROR querying ./test_data/phage.bxi with ./test_data/SRR548019.fastq.gz"
  exit 1
fi

# Test the output k-mer search
echo "Testing the output";
declare -a expected=(Listeria_phage_B056: 1.00 206.20 35 26711)
lastIndex=$((${#expected[@]} - 1))
#echo "$lastIndex .. ${expected[@]}"
for i in $(seq 0 $lastIndex); do
  j=$((i + 1));
  observed="$(grep Listeria_phage_B056 test.out | cut -f $j -d ' ')"
  echo "${expected[$i]} <=> $observed";
  if [ "${expected[$i]}" != "$observed" ]; then
    echo "ERROR: test output was incorrect in field $i.  I expected ${expected[$i]} but got $observed."
    exit 1;
  fi
done
echo "All fields matched!"
