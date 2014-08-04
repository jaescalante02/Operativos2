import sys
import random

casos = int(raw_input())
print "<processes>"
for i in range(0,casos):
	print "\t<process>"
	print "\t\t<id>","p"+str(i),"</id>"
	size = random.randint(1,45)
	arrival = random.randint(500,10000)
	print "\t\t<item>"
	print "\t\t\t<arrival>",arrival,"</arrival>"
	print "\t\t\t<size>",size,"</size>"
	acs  = random.randint(1,20)
	for k in range(0,acs):
		tmp = random.randint(0,size-1)
		print "\t\t\t<page>",tmp,"<page>"
	print "\t\t</item>"
	print "\t</process>"

print "</processes>"
