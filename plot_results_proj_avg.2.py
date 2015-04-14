#!/usr/bin/env python
# -*- coding: utf-8 -*-

from numpy import *
from scipy import *
from matplotlib import pylab
from sqlShort import sqlShort

db = sqlShort(host='results/jvo_db.sqlite', type='sqlite')

subject_clause = "  "

#s, = db.query("SELECT subject FROM thr GROUP BY subject")
#print len(s)

cm = array([[207, 82, 10], [237, 186, 70], [78, 164, 38], [25, 112, 176], [149, 38, 138], [250, 90, 0], [200, 0, 0], [0, 150, 255], [158, 204, 59], [54, 102, 255]])/255.

cols = {4: cm[4], 8: cm[5]}
lw = 2
marker = {4: 'o', 8: 's'}

#pylab.xkcd()

fig = pylab.figure()
ax  = fig.add_axes((.12, .15, .8, .8))

ax.axhline(y=3.6, ls=':', color=ones(3)*.7)

shifts = [0, 2, 4, 6]

for nOrd in [4, 8]:
	
	col = cols[nOrd]
	
	x  = list()
	ex = list()
	
	for shift in shifts:
	
		vName = 'n-%dch-%dord-%dmm' % (12, nOrd, shift)

		#col = cols[nOrd]

		voc, thr, se_thr = db.query("""
			SELECT vocoder,
				AVG(threshold) AS thr,
				STD(threshold)/SQRT(COUNT(*)) AS se_thr
			FROM 
				(
					SELECT subject, vocoder, AVG(threshold) as threshold
					FROM thr
					WHERE vocoder_name='%s'
					GROUP BY subject, vocoder
				) AS tmp
			GROUP BY vocoder
			""" % (vName))
		x.extend(thr)
		ex.extend(se_thr)
		
		
		subj, thr = db.query("""
			SELECT subject,
				AVG(ABS(threshold)) AS thr
			FROM thr
			WHERE vocoder_name='%s'
			GROUP BY subject
			""" % (vName),
			array=True)
	
		ax.scatter(shift-.005+linspace(-1,1,len(thr))*.01, thr, marker=marker[nOrd], s=3, linewidths=.5, facecolors='none', edgecolors=r_[col,1], zorder=-1)

		print r_[col,1]
		
	ax.errorbar(shifts, x, yerr=ex, ls='-', marker=marker[nOrd], color=col, ms=6, mec=col*.7, elinewidth=1, label="%dth order" % nOrd, lw=lw)    


ax.legend(loc='upper left', prop={'size': 11})
ax.set_ylabel("VTL JND (semitones re. reference)")

#ax.set_yticks(range(-14, 10, 2))

ax.set_xlim([-.5+shifts[0], shifts[-1]+.5])
ax.set_xticks(shifts)
ax.set_ylim([0, 14.5])
ax.set_xlabel('Place-frequency shift (mm)')

s = 5.1/6.
fig.set_size_inches(6*s, 5*s)
fig.savefig("Results_proj_avg.png", dpi=200, format="png")
fig.savefig("Results_proj_avg.eps", format="eps")


