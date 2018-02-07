{smcl}
{* created 23jan2018}{...}
{cmd:help textfind}
{hline}

{title:Title}

{phang}
{bf:textfind} {hline 2} identify, analyze, and convert text entries into categorical data


{title:Syntax}

{p 8 16 2}{cmd:textfind}
	{varlist}
	{ifin}
	[{cmd:,}
	{cmdab:key:word(}{cmd:"}{it:text1}{cmd:"} {cmd:"}{it:text2}{cmd:"} {it:...}{cmd:)}
	{cmd:but(}{cmd:"}{it:text1}{cmd:"} {cmd:"}{it:text2}{cmd:"} {it:...}{cmd:)}
	{cmd:nocase}
	{cmd:exact}
	{cmd:or}
	{cmd:notable}
	{cmd:tag(}{newvar}{cmd:)}
	{cmd:nfinds}
	{cmd:length}
	{cmd:position}
	{cmd:tfidf}]


{title:Description}

{pstd}
{cmd:textfind} is a data-driven program that identifies, analyzes, and converts
textual data into categorical variables for further use in quantitative
analysis. It uses regular expressions to search for one (or more) keyword and
exclusion, reporting six statistics summarizing the quality of matches: the number
of observations in the dataset that were matched; the word occurrence
per observation; the text length in which word is found; the position at which 
word was first found; and the term frequency-inverse document frequency (tf-idf)
of the word used in the search.


{title:Options}

{phang}{cmdab:key:word(}{cmd:"}{it:text1}{cmd:"} {cmd:"}{it:text2}{cmd:"}
{it:...}{cmd:)} is the main search criterion. It looks up {it:"text1"},
{it:"text2"},..., in each observation of {varlist}, where {it:text} can be
string, numbers, or any other {help regexm()} search criterion.

{phang}{cmd:but(}{cmd:"}{it:text1}{cmd:"} {cmd:"}{it:text2}{cmd:"} {it:...}{cmd:)}
is the main exclusion criterion. It looks up {it:"text1"}, {it:"text2"},{it:...},
in each observation of {varlist}, where {it:text} can be string, numbers, or any
other {help regexm()} search criterion, and removes from the match criterion in
{cmd:keyword(}{it:...}{cmd:)}.

{phang}{cmd:nocase} performs a case-insensitive search.

{phang}{cmd:exact} performs an exact search of {cmd:keyword(}{it:...}{cmd:)} in
{varlist} and only matches observations that are entirely equal to {it:"text1"},
{it:"text2"},..., etc.

{phang}{cmd:or} performs an alternative ("or") match for multiple entries in 
{cmd:keyword(}{it:...}{cmd:)}. The default is {it:"text1"} {it:and} {it:"text2"}
{it:and} {it:...}, etc.

{phang}{cmd:notable} asks Stata not to return table of summary statistics.

{phang}{cmd:tag({newvar})} generates one variable called {newvar} marking all
observations that were found under criteria {cmd:keyword(}{it:...}{cmd:)} and
{cmd:but(}{it:...}{cmd:)}.

{phang}{cmd:nfinds} generates one variable per {it:"text"} in {cmd:keyword(}{it:...}{cmd:)}
containing the number of occurrences of {it:"text"} in each observation. Default
variable names are {cmd:{it:myvar1_nfinds}}, {cmd:{it:myvar2_nfinds}}, ..., for
{it:text1}, {it:text2},..., etc.

{phang}{cmd:length} generates new variable {cmd:{it:myvar_length}} containing the
word length of each variable in {varlist} for which search criteria is found.

{phang}{cmd:position} generates one variable per {it:"text"} in {cmd:keyword(}{it:...}{cmd:)}
containing the position where {it:"text"} was first found in each observation. Default
variable names are {cmd:{it:myvar1_pos}}, {cmd:{it:myvar2_pos}}, ..., for
{it:text1}, {it:text2},..., etc.

{phang}{cmd:tfidf} generates one variable per {it:"text"} in {cmd:keyword(}{it:...}{cmd:)}
containing the term frequency-inverse document frequency statistic of {it:"text"}
in each observation. Default variable names are {cmd:{it:myvar1_tfidf}},
{cmd:{it:myvar2_tfidf}}, ..., for {it:text1}, {it:text2},..., etc.


{title:Remarks}

{pstd}
{cmd:textfind} increases Stata's capabilities for conducting content analysis. Beyond
standard keyword search made possible by {help string functions}, {cmd:textfind}
allows users to use multiple keyword and exclusion criteria to identify observations
in the dataset.

{pstd}
In particular, {cmd:textfind} has three important features: (i) it
makes use of regular expressions for highly-complex search patterns; (ii) it 
performs means comparison tests across samples created with different search
criteria, helping the user in deciding whether the use of more search criteria is
significantly better than the the use of fewer criteria; (iii) it uses Unicode
encoding, instead of ASCII, thus making it compatible with non-English text
excerpts and strings.

{pstd}
The program produces a summary table with six statistics by each keyword and exclusion.

{phang}{cmd:(1) Total Finds (exclusions):} returns the number of observations
found by search criteria in {cmd:keyword({it:...})} or {cmd:but({it:...})}.

{phang}{cmd:(2) Average Finds (exclusions):} returns the average number of
occurrences of {cmd:keyword({it:...})} [or exclusions for {cmd:but({it:...})}] by
observation.

{phang}{cmd:(3) Average Length:} returns the average length (in words) of
observations where {cmd:keyword({it:...})} [or {cmd:but({it:...})}] were [not]
found.

{phang}{cmd:(4) Average Position:} returns the average position in which
{cmd:keyword({it:...})} or {cmd:but({it:...})} were found.

{phang}{cmd:(5) Average TF-IDF:} returns the average tf-idf statistic for all
observations where {cmd:keyword({it:...})} or {cmd:but({it:...})} were found.

{phang}{cmd:(6) Type-I error p-value:} returns the p-value of a means comparison
test across two immediate samples identified by search criterion {it:n} vs. {it:n-1}.


{title:Examples}

{phang}{cmd:. use "(...)"}{p_end}

{phang}This is a fake dataset reporting positions of 5,000 government officials
in Neverland. {cmd:textfind} identifies the same observations as command below but
returns six statistics on the quality of match.{p_end}

{phang}{cmd:. tab post if ustrregexm(post, "officer", 1)==1 & ustrregexm(post, "level", 1)==0}{p_end}

{phang}{cmd:. textfind post, key("officer") but("level") nocase}



{title:Stored Results}

{pstd}
{cmd:textfind} stores the following in {cmd:r()}:

{synoptset 16 tabbed}{...}
{p2col 5 16 18 2: Scalars}{p_end}
{synopt:{cmd:r(fvarmn)}} word {it:m} = [1,2,...], statistic {it:n} = [1,6], found in each {it:var} from {varlist}.
{p_end}
{synopt:{cmd:r(nvarmn)}} word {it:m} = [1,2,...], statistic {it:n} = [1,6], not found in each {it:var} from {varlist}.
{p_end}
{synopt:{cmd:r(max)}} maximum number of words in largest string {it:var} in {varlist}.  
{p_end}
{synopt:{cmd:r(nkey)}} number of find criteria.  
{p_end}
{synopt:{cmd:r(mbut)}} number of exclusion criteria.  
{p_end}


{p2col 5 16 18 2: Macros}{p_end}
{synopt:{cmd:r(allkey)}} all find criteria.
{p_end}
{synopt:{cmd:r(allbut)}} all exclusion criteria.
{p_end}

{p2col 5 16 18 2: Matrices}{p_end}
{synopt:{cmd:r(key)}} ({it:m+1}) x {it:6} matrix containing all find statistics.
{p_end}
{synopt:{cmd:r(but)}} [{it:m},{it:m+1}] x {it:6} matrix containing all exclusion statistics.
{p_end}


{title:Author}

{phang}Andre Assumpcao{p_end}
{phang}The University of North Carolina at Chapel Hill{p_end}
{phang}Department of Public Policy{p_end}
{phang}aassumpcao@unc.edu{p_end}


{title:Acknowledgments}

{pstd}
{browse "http://www.stata-journal.com/sjpdf.html?articlenum=dm0056":Cox (2011)}
created the original number of occurrences statistics in {cmd:textfind},
where I have only modified the function arguments to allow for Unicode enconding
search.


{title:References}

{phang} Cox, N. J. 2011. {browse "http://www.stata-journal.com/sjpdf.html?articlenum=dm0056":Stata tip 98: Counting substrings within strings.} {it:Stata Journal}, 11(2): 318-320.


{title:Also see}

{psee}
Help: {manhelp ustrregexm() D}, {help string functions}, {help moss()}

{psee}
FAQs: {browse "http://www.stata.com/support/faqs/data/regex.html":What are regular expressions and how can I use them in Stata?}
{p_end}

{psee}
FAQs: {browse "https://stats.idre.ucla.edu/stata/faq/how-can-i-extract-a-portion-of-a-string-variable-using-regular-expressions/":How can I extract a portion of a string variable using regular expressions? | Stata FAQ}
{p_end}
