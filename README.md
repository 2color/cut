# cut

cut cli tool implemented in D2


## compiling

`dmd cut.d optionsparser.d`


## running tests

```shell
dmd cut.d optionsparser.d -unittest
./cut
```
Make sure that you see the following lines
```
tests: Cut 	 passed ✓
tests: CutOptionsParser 	 passed  ✓
```

## Usage Example
```
./cut -b 1-7 data.log
./cut -f -3 -d " " data.log
./cut -f -3,6,7 -d " " data.log
./cut -f -3,6,7 -d " " --complement data.log
```

## Performance comparsion to the original cut

```
./cut -f 2- -d " " /var/log/install.log > benchmark.log  1.55s user 0.08s system 92% cpu 1.770 total
cut -f 2- -d " " /var/log/install.log > benchmark.log  2.00s user 0.07s system 98% cpu 2.096 total
```