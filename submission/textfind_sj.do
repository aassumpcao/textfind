*------------------------------------------------------------------------------*
* textfind: a data-driven text analysis tool for Stata                         *
* Stata Journal Submission Do-file                                             *
* Prepared by:                                                                 *
* Andre aassumpcao                                                             *
* aassumpcao@unc.edu                                                           *
*------------------------------------------------------------------------------*
set more off


/*-----------------------------------------------------------------------------*
README:
This do-file implements textfind on three different datasets. The goal is to
show how textfind helps overcome some common text analysis problems, such as
knowing what is the quality of your search algorithm, how to address text that
contains many misspelled words and errors, and finally how to work with text in
languages other than English. The datasets included in this file are also
available at textfind's github page: https://github.com/aassumpcao/textfind

Datasets:

1. CivilServantsNeverland.dta
Hypothetical dataset on government officials in Neverland. It is used to show
the main features in textfind.

2. textprogram.dta
Actual dataset from corruption research with 524 government officials in Malawi
from 2016. I use two questions from the survey on their current job function and
seniority. Text has not been processed.

3. soData.dta
Actual dataset from expenditure audits in Brazil. The text variables are two
different descriptions of government expenditures carried out by local govern-
ments between 2004 and 2010. Text has not been processed.

********************************************************************************
NB: I edited out table headers after output 3 to improve visualization in SJ.
********************************************************************************
*-----------------------------------------------------------------------------*/


********************************************************************************
******************** Replace for your own working directory ********************
********************************************************************************
global folder = "/Users/aassumpcao/OneDrive - University of North Carolina " ///
  + "at Chapel Hill/Documents/Research/2017 Stata Text Command/" ///
  + "submission/"

*** Define working directory
cd "$folder"


********************************************************************************
********************************** Data 1 **************************************
********************************************************************************
*** Overview of positions in Neverland
sjlog using textfind_output1, replace
use CivilServantsNeverland, clear
tab post
sjlog close, replace

*** Identification of sample containing "analyst" or  "officer" but not "senior"
sjlog using textfind_output2, replace
tab post if ustrregexm(post, "anal[yi]st|officer", 1) == 1 & ustrregexm(post, "senior", 1) == 0
sjlog close, replace

*** textfind
*** I have manually edited out the header of the table for better visualization
*** in SJ
sjlog using textfind_output3, replace
textfind post, key("anal[yi]st" "officer") but("senior") or nocase
sjlog close, replace


********************************************************************************
********************************** Data 2 **************************************
********************************************************************************
use textprogram, clear

*** Overview of positions containing substring "ict"
sjlog using textfind_output4, replace
tab post if ustrregexm(post, "ict", 1) == 1
sjlog close, replace

*** Case-sensitive search
sjlog using textfind_output5, replace
textfind post, key("ICT") but("district") nocase
textfind post, key("ICT")
sjlog close, replace

*** Additive search
sjlog using textfind_output6, replace
textfind post, key("principal" "economist") nocase
textfind post, key("principal(.)+economist") nocase
textfind post, key("principal") but("account|management|officer|administ|planning|analyst|system|secretary|policy|nutrition|in[dt]|human|finan|audit|insp|comm|infor|sc") nocase
sjlog close, replace

********************************************************************************
********************************** Data 3 **************************************
********************************************************************************
use soData, clear

*** Define keywords that match SO to public purchases
local purchase = ///
  `""aquisi" "execu" "ve[íi]culo" "despesa" "medicamento(.)*peaf" "' + ///
  `""compra" "pnate" "transporte(.)*escola" "kit" "adquir""'

*** Define keywords that match SO to public works
local works = ///
  `""constru" "obra" "implant" "infra(.)*estrut" "amplia" "'       + ///
  `""abasteci(.)*(.)*[áa]gua" "reforma" "esgot" "'                 + ///
  `""m[óo]dul(.)*sanit[áa]ri[ao]" "(melhoria)+(.)*(f[íi]sica)+" "' + ///
  `""benfeit""'

*** Run textfind for procurement
sjlog using textfind_output7_test, replace
textfind soDescription, key(`purchase') or nocase

*** Run textfind for public works
textfind soDescription, key(`works') but("psf") or nocase
sjlog close, replace