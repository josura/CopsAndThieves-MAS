from  matplotlib import pyplot as plt 
import numpy as np
import pandas as pd

# Data
# tsv file has the following format:
# robbed	ticks	nPolice	nThieves	nCivilians	coneofVisionRadius	coneofVisionAngle	behavior
fullTestData = pd.read_csv('robbed.tsv', sep='\t')

random_behavior_testdata = fullTestData[fullTestData['behavior'] == 'random']

fixed_looking_behavior_testdata = fullTestData[fullTestData['behavior'] == 'fixed-looking']

# # plotting 3d wireframe for random behavior
# ax = plt.figure().add_subplot(projection='3d')
# ticks = np.array(random_behavior_testdata['ticks'])
# nPolice = np.array(random_behavior_testdata['nPolice'])
# X, Y = np.meshgrid(ticks, nPolice)
# Z = np.zeros_like(X, dtype=np.float64)

# for i, tick in enumerate(ticks):
#     for j, police in enumerate(nPolice):
#         Z[j, i] = random_behavior_testdata[(random_behavior_testdata['ticks'] == tick) & (random_behavior_testdata['nPolice'] == police)]['robbed'].mean()

# ax.plot_wireframe(X, Y, Z, color='black')
# ax.set_xlabel('ticks')
# ax.set_ylabel('nPolice')
# ax.set_zlabel('robbed')
# ax.set_title('random behavior')
# plt.show()

# plotting 3d scatter for random behavior
fig = plt.figure()
ax = fig.add_subplot(111, projection='3d')
# compute the average number of robbed for each tick and nPolice
average_robbed_data = random_behavior_testdata.groupby(['ticks', 'nPolice'])['robbed'].mean().reset_index()
ticks = np.array(average_robbed_data['ticks'])
nPolice = np.array(average_robbed_data['nPolice'])
average_robbed = np.array(average_robbed_data['robbed'])

ax.scatter(ticks, nPolice, average_robbed, c='r', marker='o')
ax.set_xlabel('ticks')
ax.set_ylabel('nPolice')
ax.set_zlabel('robbed')
ax.set_title('random behavior')
plt.show()

# plotting line plots in 3d for random behavior, changing ticks but keeping nPolice fixed for each line
fig = plt.figure()
ax = fig.add_subplot(111, projection='3d')

police_unique = random_behavior_testdata['nPolice'].unique()

for police in police_unique:
    data = random_behavior_testdata[random_behavior_testdata['nPolice'] == police]
    data_mean = data.groupby('ticks')['robbed'].mean().reset_index()
    ax.plot(data_mean['ticks'], data_mean['robbed'], zs=police, zdir='y')

ax.set_xlabel('ticks')
ax.set_ylabel('nPolice')
ax.set_zlabel('robbed')
ax.set_title('random behavior')
plt.show()

# plotting line plots in 2d for random behavior, changing ticks but keeping nPolice fixed for each line
fig = plt.figure()
ax = fig.add_subplot(111)

for police in police_unique:
    data = random_behavior_testdata[random_behavior_testdata['nPolice'] == police]
    data_mean = data.groupby('ticks')['robbed'].mean().reset_index()
    ax.plot(data_mean['ticks'], data_mean['robbed'], label=police)

ax.set_xlabel('ticks')
ax.set_ylabel('robbed')
ax.set_title('random behavior')
ax.legend()
plt.show()



# # plotting 3d wireframe for fixed-looking behavior
# ax = plt.figure().add_subplot(projection='3d')
# ticks = np.array(fixed_looking_behavior_testdata['ticks'])
# nPolice = np.array(fixed_looking_behavior_testdata['nPolice'])
# X, Y = np.meshgrid(ticks, nPolice)
# Z = np.zeros_like(X, dtype=np.float64)

# for i, tick in enumerate(ticks):
#     for j, police in enumerate(nPolice):
#         Z[j, i] = fixed_looking_behavior_testdata[(fixed_looking_behavior_testdata['ticks'] == tick) & (fixed_looking_behavior_testdata['nPolice'] == police)]['robbed'].mean()
        
# ax.plot_wireframe(X, Y, Z, color='black')
# ax.set_xlabel('ticks')
# ax.set_ylabel('nPolice')
# ax.set_zlabel('robbed')
# ax.set_title('fixed-looking behavior')
# plt.show()


# plotting 3d scatter for fixed-looking behavior
fig = plt.figure()
ax = fig.add_subplot(111, projection='3d')
average_robbed_data = fixed_looking_behavior_testdata.groupby(['ticks', 'nPolice'])['robbed'].mean().reset_index()
ticks = np.array(average_robbed_data['ticks'])
nPolice = np.array(average_robbed_data['nPolice'])
average_robbed = np.array(average_robbed_data['robbed'])

ax.scatter(ticks, nPolice, average_robbed, c='r', marker='o')
ax.set_xlabel('ticks')
ax.set_ylabel('nPolice')
ax.set_zlabel('robbed')
ax.set_title('fixed-looking behavior')
plt.show()

# plotting line plots in 3d for fixed-looking behavior, changing ticks but keeping nPolice fixed for each line
fig = plt.figure()
ax = fig.add_subplot(111, projection='3d')

police_unique = fixed_looking_behavior_testdata['nPolice'].unique()

for police in police_unique:
    data = fixed_looking_behavior_testdata[fixed_looking_behavior_testdata['nPolice'] == police]
    data_mean = data.groupby('ticks')['robbed'].mean().reset_index()
    ax.plot(data_mean['ticks'], data_mean['robbed'], zs=police, zdir='y')

ax.set_xlabel('ticks')
ax.set_ylabel('nPolice')
ax.set_zlabel('robbed')
ax.set_title('fixed-looking behavior')
plt.show()

# plotting line plots in 2d for fixed-looking behavior, changing ticks but keeping nPolice fixed for each line
fig = plt.figure()
ax = fig.add_subplot(111)

for police in police_unique:
    data = fixed_looking_behavior_testdata[fixed_looking_behavior_testdata['nPolice'] == police]
    data_mean = data.groupby('ticks')['robbed'].mean().reset_index()
    ax.plot(data_mean['ticks'], data_mean['robbed'], label=police)

ax.set_xlabel('ticks')
ax.set_ylabel('robbed')
ax.set_title('fixed-looking behavior')
ax.legend()
plt.show()

# saving aggregated data for plots (max robbed, min robbed, mean robbed, std robbed, median robbed, 25th percentile robbed, 75th percentile robbed)
aggregated_data_random_behavior = random_behavior_testdata.groupby('nPolice')['robbed'].agg(['max', 'min', 'mean', 'std', 'median', lambda x: x.quantile(0.25), lambda x: x.quantile(0.75)]).reset_index().to_csv('random_behavior_aggregated.tsv', sep='\t', index=False)
aggregated_data_fixed_looking_behavior = fixed_looking_behavior_testdata.groupby('nPolice')['robbed'].agg(['max', 'min', 'mean', 'std', 'median', lambda x: x.quantile(0.25), lambda x: x.quantile(0.75)]).reset_index().to_csv('fixed_looking_behavior_aggregated.tsv', sep='\t', index=False)


# hypothesis testing on the number of robbed for random behavior and fixed-looking behavior, showing that the number of robbed is significantly different between the two behaviors