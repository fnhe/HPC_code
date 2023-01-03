#!usr/bin/python3
import numpy as np
import pandas as pd
import sys

fi = pd.read_table(sys.argv[1], header = None)

for i in range(len(fi)):
    print ('echo Job' + str(i))
    print ('echo "Job'+str(i)+' start: `date`"')
    print ('if')
    print ('\t'+ str(fi[0].iloc[i]))
    print ('then')
    print ('\techo "Job'+str(i)+' done:`date`"')
    print ('else')
    print ('\techo "ERROR in: "' + str(fi[0].iloc[i]))
    print ('\texit')
    print ('fi')
