import os
import numpy as np

dataFiles = []
for subdir, dirs, files in os.walk('./data/'):
    dataFiles.extend(files)
    print(dataFiles)

dataAll = np.zeros([len(dataFiles), 36, 4])
# print(dataAll)

for ii, file in enumerate(dataFiles):
    # print(file)
    with open('./data/'+file) as f:
        lines = f.readlines()
        dataOne = np.zeros([len(lines), 4])
        for jj, line in enumerate(lines):
            myarray = np.fromstring(line, dtype=int, sep=',')
            dataOne[jj,:]=myarray
        dataAll[ii, :, :] = dataOne
        # print(dataOne)
        f.close()
print(dataAll)

        

