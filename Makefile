#
# Eltrun web site creation and data validation
#
# (C) Copyright 2005 Diomidis Spinellis
#
# $Id$
#

MEMBERFILES=$(wildcard data/members/*.xml)
GROUPFILES=$(wildcard data/groups/*.xml)
PROJECTFILES=$(wildcard data/projects/*.xml)
PUBFILE=build/pubs.xml
BIBFILES=$(wildcard data/publications/*.bib)

# BibTeX paths (used under Unix)
BIBINPUTS=data/publications:tools
BSTINPUTS=tools
export BIBINPUTS
export BSTINPUTS

# Database containing all the above
DB=build/db.xml
# XSLT file for public data
PXSLT=schema/eltrun-public.xslt
# XSLT file for fetching the ids
IDXSLT=schema/eltrun-ids.xslt
# Today' date in ISO format
TODAY=$(shell date +'%Y%m%d')
# Fetch the ids
GROUPIDS=$(shell xml tr ${IDXSLT} -s category=group ${DB})
PROJECTIDS=$(shell xml tr ${IDXSLT} -s category=project ${DB})
MEMBERIDS=$(shell xml tr ${IDXSLT} -s category=member ${DB})
# HTML output directory
HTML=public_html

ifdef MACHTYPE
# Unix
SSH=ssh
else
# Windows
SSH=plink
endif

all: html

$(DB): ${MEMBERFILES} ${GROUPFILES} ${PROJECTFILES} $(BIBFILES) tools/makepub.pl
	@echo '<?xml version="1.0"?>' > $@
	@echo '<eltrun>' >>$@ 
	@echo '<group_list>' >>$@ 
	for file in $(GROUPFILES); \
	do \
		grep -v -e "xml version=" $$file ; \
	done >>$@
	@echo '</group_list>' >>$@
	@echo '<member_list>' >>$@
	@for file in $(MEMBERFILES); \
	do \
		grep -v -e "xml version=" $$file ; \
	done >>$@
	@echo '</member_list>' >>$@
	@echo '<project_list>' >>$@
	@for file in $(PROJECTFILES); \
	do \
		grep -v -e "xml version=" $$file ; \
	done >>$@
	@echo '</project_list>' >>$@
	@perl -n tools/makepub.pl $(BIBFILES) >>$@
	@echo '</eltrun>' >>$@

clean:
	-rm -f  build/* \
		${HTML}/groups/* \
		${HTML}/projects/* \
		${HTML}/members/* \
		${HTML}/publications/* 2>/dev/null

val: ${DB}
	@echo '---> Checking group data XML files ... '
	@-for file in $(GROUPFILES); \
	do \
		xml val -d schema/eltrun-group.dtd $$file; \
	done 
	@echo '---> Checking member data XML files ...'
	@-for file in $(MEMBERFILES); \
	do \
		xml val -d schema/eltrun-member.dtd $$file; \
	done
	@echo '---> Checking project data XML files ...'
	@-for file in $(PROJECTFILES); \
	do \
		xml val -d schema/eltrun-project.dtd $$file; \
	done
	@echo '---> Checking db.xml '
	xml val -d schema/eltrun.dtd $(DB)

html: ${DB}	
	# For all groups and the empty group
	for group in $(GROUPIDS) ; \
	do \
		xml tr ${PXSLT} -s today=${TODAY} -s ogroup=$$group -s what=group-details ${DB} >${HTML}/groups/$$group-details.html ; \
		xml tr ${PXSLT} -s today=${TODAY} -s ogroup=$$group -s what=completed-projects ${DB} >${HTML}/groups/$$group-completed-projects.html ; \
		xml tr ${PXSLT} -s today=${TODAY} -s ogroup=$$group -s what=current-projects ${DB} >${HTML}/groups/$$group-current-projects.html ; \
		xml tr ${PXSLT} -s today=${TODAY} -s ogroup=$$group -s what=members ${DB} >${HTML}/groups/$$group-members.html ; \
		xml tr ${PXSLT} -s today=${TODAY} -s ogroup=$$group -s what=alumni ${DB} >${HTML}/groups/$$group-alumni.html ; \
		xml tr ${PXSLT} -s ogroup=$$group -s what=group-publications ${DB} >${HTML}/publications/$$group-publications.html ; \
	done
	for project in $(PROJECTIDS) ; \
	do \
		xml tr ${PXSLT} -s oproject=$$project -s what=project-details ${DB} >${HTML}/projects/$$project.html ; \
		xml tr ${PXSLT} -s oproject=$$project -s what=project-publications ${DB} >${HTML}/publications/$$project-publications.html ; \
	done
	for member in $(MEMBERIDS) ; \
	do \
		xml tr ${PXSLT} -s omember=$$member -s what=member-details ${DB} >${HTML}/members/$$member.html ; \
		xml tr ${PXSLT} -s omember=$$member -s what=member-publications ${DB} >${HTML}/publications/$$member-publications.html ; \
	done
	$(SHELL) build/bibrun

dist: html
	$(SSH) istlab.dmst.aueb.gr "cd /home/dds/src/eltrun-web ; \
	tar -C public_html -cf - . | tar -C /home/dds/web/istlab/eltrun -xvf -"
