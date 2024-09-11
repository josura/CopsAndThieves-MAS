from  matplotlib import pyplot as plt 
import numpy as np
import pandas as pd

# Data
# tsv file has the following format:
# robbed	ticks	nPolice	nThieves	nCivilians	coneofVisionRadius	coneofVisionAngle	behavior
fullTestData = pd.read_csv('robbed.tsv', sep='\t')

random_behavior_testdata = fullTestData[fullTestData['behavior'] == 'random']

fixed_looking_behavior_testdata = fullTestData[fullTestData['behavior'] == 'fixed-looking']

# plotting 3d wireframe for random behavior
ax = plt.figure().add_subplot(projection='3d')
ticks = np.array(random_behavior_testdata['ticks'])
nPolice = np.array(random_behavior_testdata['nPolice'])
X, Y = np.meshgrid(ticks, nPolice)
Z = np.zeros_like(X, dtype=np.float64)

for i, tick in enumerate(ticks):
    for j, police in enumerate(nPolice):
        Z[j, i] = random_behavior_testdata[(random_behavior_testdata['ticks'] == tick) & (random_behavior_testdata['nPolice'] == police)]['robbed'].mean()

ax.plot_wireframe(X, Y, Z, color='black')
ax.set_xlabel('ticks')
ax.set_ylabel('nPolice')
ax.set_zlabel('robbed')
ax.set_title('random behavior')
plt.show()

# plotting 3d wireframe for fixed-looking behavior
ax = plt.figure().add_subplot(projection='3d')
ticks = np.array(fixed_looking_behavior_testdata['ticks'])
nPolice = np.array(fixed_looking_behavior_testdata['nPolice'])
X, Y = np.meshgrid(ticks, nPolice)
Z = np.zeros_like(X, dtype=np.float64)

for i, tick in enumerate(ticks):
    for j, police in enumerate(nPolice):
        Z[j, i] = fixed_looking_behavior_testdata[(fixed_looking_behavior_testdata['ticks'] == tick) & (fixed_looking_behavior_testdata['nPolice'] == police)]['robbed'].mean()
        
ax.plot_wireframe(X, Y, Z, color='black')
ax.set_xlabel('ticks')
ax.set_ylabel('nPolice')
ax.set_zlabel('robbed')
ax.set_title('fixed-looking behavior')
plt.show()
