# For Mac:

- ----------------------------------------
# For Windows:
cd into directory:
``` linux
cd part2/sisc_p2_files
```

compile:
``` linux
iverilog -o sisc_sim sisc_tb_p2-4.v sisc.v ctrl.v alu.v br.v im.v ir.v pc.v rf.v mux32.v statreg.v
```

run and save in txt file:
``` linux
vvp sisc_sim > transcript.txt
```