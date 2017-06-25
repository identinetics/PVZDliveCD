#!/usr/bin/env python3

'''
convert text with tabs  from stdin to a html table on stdout
'''

import sys

print('<table>')
for line in sys.stdin.readlines():
    cols = line.split('\t')
    cols += ('', '')
    print('<tr><td>{}</td><td>{}</td><td>{}</td></tr>'.format(cols[0], cols[1], cols[2]))

print('</table>')
