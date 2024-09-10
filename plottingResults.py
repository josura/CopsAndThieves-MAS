from  matplotlib import pyplot as plt 
import numpy as np
import pandas as pd

# Data
# tsv file has the following format:
# robbed	ticks	nPolice	nThieves	nCivilians	coneofVisionRadius	coneofVisionAngle	behavior
testData = pd.read_csv('robbed.tsv', sep='\t')
