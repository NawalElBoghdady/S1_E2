#!/usr/bin/env python
# -*- coding: utf-8 -*-

from numpy import *
from scipy import *
from matplotlib import pylab
from sqlShort import sqlShort

db = sqlShort(host='results/jvo_db.sqlite', type='sqlite')

subject_clause = "  "

cm = array([[207, 82, 10], [237, 186, 70], [78, 164, 38], [25, 112, 176], [149, 38, 138], [250, 90, 0], [200, 0, 0], [0, 150, 255], [158, 204, 59], [54, 102, 255]])/255.

cols = {4: cm[0], 12: cm[1]}
lw = 2

fig = pylab.figure()
ax  = fig.add_axes((.12, .1, .8, .8))

for side in [-1, 1]:

	if side==1:
		sql = 'dir_ser<ref_ser'
	else:
		sql = 'dir_ser>ref_ser'

	for nChan in [4, 12]:
		
		col = cols[nChan]
		
		x = list()
		ex = list()
		
		nOrds = [4, 8, 16]
		for nOrd in nOrds:
		
			vName = 'n-%dch-%dord' % (nChan, nOrd)
	
			col = cols[nChan]
	
			voc, thr, se_thr = db.query("""
				SELECT vocoder,
					AVG(threshold) AS thr,
					STD(threshold)/SQRT(COUNT(*)) AS se_thr
				FROM thr
				WHERE %s AND vocoder_name='%s'
				GROUP BY vocoder
				""" % (sql, vName))
			x.extend(thr)
			ex.extend(se_thr)
	
		ax.errorbar(log2(nOrds), x, yerr=ex, ls='-', marker='o', color=col, ms=6, mec=col*.7, elinewidth=1, label="%d" % side, lw=lw)    


ax.legend(loc='upper left', prop={'size': 11})
ax.set_ylabel("JND (semitones re. reference)")

#ax.set_yticks(range(-14, 10, 2))

#ax.set_xlim([-.3, len(nOrds)-1+.3])
ax.set_xticks(log2(nOrds))
ax.set_xticklabels(nOrds)

fig.set_size_inches(6, 5)
fig.savefig("Results_proj.png", dpi=200, format="png")
fig.savefig("Results_proj.eps", format="eps")


