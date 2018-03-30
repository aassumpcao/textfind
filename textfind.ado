// Textfind command
// by Andre Assumpcao
// aassumpcao@unc.edu
// Version 1.0 created: Jan 27, 2018

// Textfind is a data-driven program to identify and perform statistical tests on textual data
// based on flexible search criteria following regular expressions. Textfind is useful for people
// who want to do more content analysis but are not familiar with other more popular platforms 
// to that end. Any suggestions are welcome and should be submitted to the author in the e-mail
// above. Have fun!

capture program drop textfind
program textfind, rclass	
	version 15.0 // Version in which program was created
				 // Version required to run program: 14.0 or higher
	syntax varlist [if] [in] [, KEYword(string asis) but(string asis) nocase exact ///
		 or notable tag(string) nfinds length position tfidf]				  	// Syntax
		
	marksample touse, strok
	
	if c(stata_version) < 14 {
			dis as err "Stata 14 or higher required."
			exit 198
	}
	// Commands by variable and keyword
	foreach i of local varlist {									// Loop over variables
		if	`"`keyword'"'=="" & `"`but'"'=="" {										
				di as err "At least one keyword or exclusion must be defined."
				exit 198
		}
		else {
			qui {
				// General locals, scalars and inputs which will be used later
				local n: word count `keyword'								// Count number of keywords
				local m: word count `but'								// Count number of exclusions
				return scalar nkey = `n'								// Store number of keywords
				return scalar mbut = `m'								// Store number of exclusions
				return local allkey = `"`keyword'"'							// Store keywords for future display
				return local allbut = `"`but'"'								// Store exclusions for future display
				tempvar `i'length `i'count								// Temporary variables for word length and count of observations
				gen  ``i'length'=ustrwordcount(stritrim(ustrtrim(`i'))) if `touse'			// Count words in string variable
				sum ``i'length', meanonly
				return scalar max = `r(max)'
				egen ``i'count' =count(`i')								// Count observations for future tf-idf statistic
				
				// Creation of individual keyword search criteria
				forv z=1/`n' {
					local y: word `z' of `keyword'										
					if `"`exact'"'!="" {								// Exact search
						if `"`case'"'!="" {							// Case-insensitive search
							local key`z' strmatch(strlower(`i'),strlower(`"`y'"'))==1	// Keyword found ==1
						}
						else {									// Case-sensitive search
							local key`z' strmatch(`i',`"`y'"')==1				// Keyword found ==1
						}
					}
					else {										// Partial search
						if `"`case'"'!="" {							// Case-insensitive search
							local key`z' ustrregexm(`i',`"`y'"',1)==1			// Keyword found ==1
						}
						else {									// Case-sensitive search
							local key`z' ustrregexm(`i',`"`y'"',0)==1			// Keyword found ==1
						}
					}
					//di `"`key`z''"'
				}
				// Creation of individual exclusion search criteria
				forv z=1/`m' {
					local y: word `z' of `but'
					if `"`exact'"'!="" {								// Exact search
						if `"`case'"'!="" {							// Case-insensitive search
							local not`z' strmatch(strlower(`i'),strlower(`"`y'"'))==0	// Exclusion not found ==0
						}
						else {									// Case-sensitive search
							local not`z' strmatch(`i',`"`y'"')==0				// Exclusion not found ==0
						}
					}
					else {										// Partial search
						if `"`case'"'!="" {							// Case-insensitive search
							local not`z' ustrregexm(`i',`"`y'"',1)==0			// Exclusion not found ==0
						}
						else {									// Case-sensitive search
							local not`z' ustrregexm(`i',`"`y'"',0)==0			// Exclusion not found ==0
						}
					}
					//di `"`not`z''"'
				}
				
				// Table statistics for keyword(s)
				forv z=1/`n' {
					local y: word `z' of `keyword'
					tempvar `i'`z'1 `i'`z'2 `i'`z'3 `i'`z'4 `i'`z'5	`i'`z'6				// These are the six ordered
															// statistics used in table
					// Statistic 1: Total finds
					gen ``i'`z'1'	  	   	= `key`z'' if `touse'
					sum ``i'`z'1'	  	   	if `touse'
					return scalar f`i'`z'1 	   		= `r(sum)'
					
					// Statistic 2: Average finds per obs
					tempvar `i'keylength`z'
					gen	 ``i'keylength`z'' 		= cond(`key`z'',ustrlen(`"`y'"'),0) if `touse'
					if `"`case'"'!="" {
						gen ``i'`z'2'	   	= cond(`key`z'',(ustrlen(`i')-ustrlen(ustrregexra(`i',`"`y'"',"",1)))/``i'keylength`z'',.,.) if `touse'
					}
					else {
						gen ``i'`z'2'	   	= cond(`key`z'',(ustrlen(`i')-ustrlen(ustrregexra(`i',`"`y'"',"",0)))/``i'keylength`z'',.,.) if `touse'
					}
					capture assert ``i'`z'2'==.
					if _rc {
						sum ``i'`z'2'      		if ``i'`z'2'!=. & `touse'
						return scalar f`i'`z'2 		= `r(mean)'
					}
					else {
						return scalar f`i'`z'2 		= 0
					}
					
					// Statistic 3: Average word length when keyword is found
					gen  ``i'`z'3'		   	= cond(`key`z'',ustrwordcount(`i'),0,.) if `touse'
					capture assert ``i'`z'3'==0 | assert ``i'`z'3'==.
					if _rc {
						sum ``i'`z'3'      		if (``i'`z'3'!=0 | ``i'`z'3'!=.) & `touse'
						return scalar f`i'`z'3 		= `r(mean)'
					}
					else {
						return scalar f`i'`z'3 		= .
					}
					
					// Statistic 4: Average word position when keyword is found
					gen ``i'`z'4' 		   	= 0 if `touse'
					forv j=1/`return(max)' {
						if `"`case'"'!="" {
							replace ``i'`z'4'	= cond(ustrregexm(ustrword(`i',`j'), `"`y'"',1)==1,`j',0,.)
						}
						else {
							replace ``i'`z'4'	= cond(ustrregexm(ustrword(`i',`j'), `"`y'"',0)==1,`j',0,.)
						}
					}
					capture assert ``i'`z'4'==0 | assert ``i'`z'4'==.
					if _rc {
						sum ``i'`z'4'	   	if (``i'`z'4'!=0 | ``i'`z'4'!=.) & `touse'
						return scalar f`i'`z'4 		= `r(mean)'
					}
					else {
						return scalar f`i'`z'4 		= .
					}
					
					// Statistic 5: Average tf-idf when keyword is found
					tempvar `i'sum`z' `i'keytfidf`z'
					egen ``i'sum`z''			= total(``i'`z'1') if `touse'
					gen ``i'keytfidf`z''   		= cond(`key`z'',(``i'`z'2'/``i'length')*ln(``i'count'/``i'sum`z''),0,.) if `touse'
					capture assert ``i'keytfidf`z''==0 | assert ``i'keytfidf`z''==.
					if _rc {
						sum ``i'keytfidf`z''	if (``i'keytfidf`z''!=0 | ``i'keytfidf`z''!=.) & `touse'
						return scalar f`i'`z'5		= `r(mean)'
					}
					else {
						return scalar f`i'`z'5		= .
					}
					
					// Statistic 6: Type-I error p-value
					tempvar `i'0
					gen ``i'0'			   	=0 if `touse'
					if		`z'==1 {
						ttest ``i'0' 	  	== ``i'`z'1' if `touse'
						return scalar f`i'`z'6		= `r(p)'
					}
					else if  `z'>1 {
						local q=`z'-1
						local w: word `q' of `keyword'
						ttest ``i'`q'1'	  	== ``i'`z'1' if `touse'
						return scalar f`i'`z'6		= `r(p)'
					}				
				}
				
				// Table statistics for exclusion(s)
				forv z=1/`m' {
					local y: word `z' of `but'
					tempvar `i'`z'1 `i'`z'2 `i'`z'3 `i'`z'4 `i'`z'5 `i'`z'6				// These are the six ordered
															// statistics used in table
					// Statistic 1: Total exclusions
					gen ``i'`z'1'	  	   	= cond(`not`z'',0,1,.) if `touse'
					sum ``i'`z'1'	  	   	if ``i'`z'1'!=. & `touse'
					return scalar n`i'`z'1 	   		= `r(sum)'
					
					// Statistic 2: Average number of exclusions
					tempvar `i'notlength`z'
					gen	 ``i'notlength`z'' 		= cond(cond(`not`z'',0,1)==1,ustrlen(`"`y'"'),0,.) if `touse'
					if `"`case'"'!="" {
						gen ``i'`z'2'	   	= cond(cond(`not`z'',0,1)==1 & ``i'notlength`z''!=.,(ustrlen(`i')-ustrlen(ustrregexra(`i',`"`y'"',"",1)))/``i'notlength`z'',.) if `touse'
					}
					else {
						gen ``i'`z'2'	   	= cond(cond(`not`z'',0,1)==1 & ``i'notlength`z''!=.,(ustrlen(`i')-ustrlen(ustrregexra(`i',`"`y'"',"",0)))/``i'notlength`z'',.) if `touse'
					}
					capture assert ``i'`z'2'==.
					if _rc {
						sum ``i'`z'2'      		if ``i'`z'2'!=. & `touse'
						return scalar n`i'`z'2 		= `r(mean)'
					}
					else {
						return scalar n`i'`z'2 		= 0
					}
					
					// Statistic 3: Average word length when keyword is found
					gen  ``i'`z'3'		   	= cond(cond(`not`z'',0,1)==1,ustrwordcount(`i'),0,.) if `touse'
					capture assert ``i'`z'3'==0 | assert ``i'`z'3'==. 
					if _rc {
						sum ``i'`z'3'      		if (``i'`z'3'!=0 | ``i'`z'3'!=.) & `touse'
						return scalar n`i'`z'3 		= `r(mean)'
					}
					else {
						return scalar n`i'`z'3 		= .
					}
					
					// Statistic 4: Average position of exclusion
					gen ``i'`z'4' 	   		= 0 if `touse'
					forv j=1/`return(max)' {
						if `"`case'"'!="" {
							replace ``i'`z'4'	= cond(ustrregexm(ustrword(`i',`j'), `"`y'"',1)==1,`j',0,.)
						}
						else {
							replace ``i'`z'4'	= cond(ustrregexm(ustrword(`i',`j'), `"`y'"',0)==1,`j',0,.)
						}
					}
					capture assert ``i'`z'4'==0 | assert ``i'`z'4'==.
					if _rc {
						sum ``i'`z'4'	   	if (``i'`z'4'!=0 | ``i'`z'4'!=.) & `touse'
						return scalar n`i'`z'4 		= `r(mean)'
					}
					else {
						return scalar n`i'`z'4 		= .
					}
								
					// Statistic 5: Average tf-idf when keyword is not found
					tempvar `i'sum`z' `i'keytfidf`z'
					egen ``i'sum`z''			= total(cond(``i'`z'1',0,1)) if `touse'
					gen ``i'keytfidf`z''   		= cond(cond(`not`z'',0,1)==1,(``i'`z'2'/``i'length')*ln(``i'count'/``i'sum`z''),0,.) if `touse'
					capture assert ``i'keytfidf`z'' ==0 | assert ``i'keytfidf`z''==.
					if _rc {
						sum ``i'keytfidf`z''	if (``i'keytfidf`z''!=0 | ``i'keytfidf`z''!=.) & `touse'
						return scalar n`i'`z'5		= `r(mean)'
					}
					else {
						return scalar n`i'`z'5		= .
					}			
							
					// Statistic 6: Type-I error p-value
					tempvar `i'0
					gen ``i'0'			   	=0 if `touse'
					if		`z'==1 {
						ttest ``i'0' 	   	== ``i'`z'1' if `touse'
						return scalar n`i'`z'6 		= `r(p)'
					}
					else if  `z'>1 {
						local q=`z'-1
						local w: word `q' of `but'
						ttest ``i'`q'1'	   		== ``i'`z'1' if `touse'
						return scalar n`i'`z'6 		= `r(p)'
					}
				}
				
				// Creation of compiled keyword criteria
				if 		 `n'>1 {								// The code below is basically renaming the criteria
					if `"`or'"'!="" {								// so that we can easily use it later. We start off
						forv z=2/`n' {								// with keyword(s). I include two new alternatives
							local w=`z'-1							// here: (i) a joint search for all keywords or an
							local key`z' `"`key`w'' | `key`z''"'				// (ii) alternative search for each keyword
						}
					}
					else {
						forv z=2/`n' {
							local w=`z'-1
							local key`z' `"`key`w'' & `key`z''"'
						}
					}
					local key `"`key`n''"'
				}
				else if `n'==1 {									// In any of the cases above (single, multiple, joint or	
					local key `"`key1'"'								// or alternative search, they all lead to one	
				}											// single local: `key'.
				di `"`key'"'
				
				// Creation of compiled exclusion criteria											
				if 		 `m'>1 {								// The code below is doing the same for exclusion(s).
					forv z=2/`m' {									// However, the exclusion(s) just require(s) that any of the
						local w=`z'-1								// `but' is present. Thus, the search criteria is for any
						local not`z' `"`not`w'' & `not`z''"'					// occurrences of `but'.		
					}
					local not `"`not`m''"'
				}
				else if `m'==1 {									// In any of the cases above (single, multiple, joint or
					local not `"`not1'"'								// or alternative search, they all lead to one single local: `key'.
				}
				//di `"`not'"'
				
				// Table statistics for compiled keyword and exclusion criteria
				local t=`n'+1
				tempvar `i'tot `i'`t'2 `i'len `i'totlen `i'ttest
					
				
				// Table statistics for compiled criteria (keyword(s) and exclusion(s))
				if `"`keyword'"'!="" {
					if `"`but'"'=="" {
						// Case 1: key==1 & but==0
						// Statistic 1: Total finds
						gen ``i'tot'	  	   = `key' if `touse'
						sum ``i'tot'	  	   if `touse'
						return scalar f`i'`t'1 	   = `r(sum)'
						
						// Statistic 2: Average finds per obs
						if `n'==1 {
							tempvar `i'keylength`t'
							gen	 ``i'keylength`t'' 		= cond(`key',ustrlen(`"`y'"'),0) if `touse'
							if `"`case'"'!="" {
								gen ``i'`t'2'	   	= cond(`key',(ustrlen(`i')-ustrlen(ustrregexra(`i',`"`y'"',"",1)))/``i'keylength`t'',.) if `touse'
							}
							else {
								gen ``i'`t'2'	   	= cond(`key',(ustrlen(`i')-ustrlen(ustrregexra(`i',`"`y'"',"",0)))/``i'keylength`t'',.) if `touse'
							}
							capture assert ``i'`t'2'==.
							if _rc {
								sum ``i'`t'2'      		if ``i'`t'2'!=. & `touse'
								return scalar f`i'`t'2 		= `r(mean)'
							}
							else {
								return scalar f`i'`t'2 		= 0
							}
						}
						else {
							return scalar f`i'`t'2 	   = .
						}
						
						// Statistic 3: Average string length when keyword is found
						gen  ``i'len'		   = cond(`key',ustrwordcount(`i'),0,.) if `touse'
						capture assert ``i'len'==0 | assert ``i'len'==.
						if _rc {
							sum ``i'`len''     if (``i'len'!=0 | ``i'len'!=.) & `touse'
							return scalar f`i'`t'3 = `r(mean)'
						}
						else {
							return scalar f`i'`t'3 = .
						}
						
						// Statistic 4: Average position when keyword is found
						if `n'==1 {
							return scalar f`i'`t'4 = `return(f`i'14)'
						}
						else {
							return scalar f`i'`t'4 	   = . 						// This statistic doesn't make sense for the combined search
						}
						
						// Statistic 5: TF-IDF
						if `n'==1 {
							return scalar f`i'`t'5 = `return(f`i'15)'
						}
						else {
							return scalar f`i'`t'5	   = . 						// This statistic doesn't make sense for the combined search
						}
						
						// Statistic 6: Type-I error p-value
						
						ttest ``i'`n'1'	   	   == ``i'tot'
						return scalar f`i'`t'6 	   = `r(p)'
					}
					else {
						// Case 2: key==1 & but==1
						// Statistic 1: Total finds
						gen ``i'tot'	  	   = (`key') & `not' if `touse'
						sum ``i'tot'	  	   if `touse'
						return scalar f`i'`t'1 	   = `r(sum)'
						
						// Statistic 2: Average finds per obs
						if `n'==1 {
							local y: word `n' of `keyword'
							tempvar `i'keylength`t' `i'`t'2
							gen	 ``i'keylength`t'' 		= cond(`key' & (`not'),ustrlen(`"`y'"'),0) if `touse'
							if `"`case'"'!="" {
								gen ``i'`t'2'   	= cond(`key' & (`not'),(ustrlen(`i')-ustrlen(ustrregexra(`i',`"`y'"',"",1)))/``i'keylength`t'',.) if `touse'
							}
							else {
								gen ``i'`t'2' 	   	= cond(`key' & (`not'),(ustrlen(`i')-ustrlen(ustrregexra(`i',`"`y'"',"",0)))/``i'keylength`t'',.) if `touse'
							}
							capture assert ``i'`t'2' ==.
							if _rc {
								sum ``i'`t'2'       		if ``i'`t'2'!=. & `touse'
								return scalar f`i'`t'2 		= `r(mean)'
							}
							else {
								return scalar f`i'`t'2 		= 0
							}
						}
						else {
							return scalar f`i'`t'2 	   = . 						// This statistic doesn't make sense for the combined search
						}
						
						// Statistic 3: Average string length when keyword is found
						gen  ``i'len'		   = cond((`key') & (`not'),ustrwordcount(`i'),0,.) if `touse'
						capture assert ``i'len'==0 | assert ``i'len'==.
						if _rc {
							sum ``i'len'       if (``i'len'!=0 | ``i'len'!=.) & `touse'
							return scalar f`i'`t'3 = `r(mean)'
						}
						else {
							return scalar f`i'`t'3 = .
						}

						// Statistic 4: Average position when keyword is found
						if `n'==1 {
							tempvar `i'`t'4
							gen ``i'`t'4' 		   	= 0 if `touse'
							forv j=1/`return(max)' {
								if `"`case'"'!="" {
									replace ``i'`t'4'	= cond(ustrregexm(ustrword(`i',`j'), `"`y'"',1)==1,`j',0,.)
								}
								else {
									replace ``i'`t'4'	= cond(ustrregexm(ustrword(`i',`j'), `"`y'"',0)==1,`j',0,.)
								}
							}
							capture assert ``i'`t'4'==0 | assert ``i'`t'4'==.
							if _rc {
								sum ``i'`t'4'	   	if (``i'`t'4'!=0 | ``i'`t'4'!=.) & `touse'
								return scalar f`i'`t'4 		= `r(mean)'
							}
							else {
								return scalar f`i'`t'4 		= .
							}
						}
						else {
							return scalar f`i'`t'4 	   = . 						// This statistic doesn't make sense for the combined search
						}
						
						// Statistic 5: TF-IDF
						if `n'==1 {
							tempvar `i'sum`t' `i'keytfidf`t'
							egen ``i'sum`t''			= total(``i'tot') if `touse'
							gen ``i'keytfidf`t''   		= cond((`key') & (`not'),(``i'`t'2'/``i'length')*ln(``i'count'/``i'sum`t''),0,.) if `touse'
							capture assert ``i'keytfidf`t''==0 | assert ``i'keytfidf`t''==.
							if _rc {
								sum ``i'keytfidf`t''	if (``i'keytfidf`t''!=0 | ``i'keytfidf`t''!=.) & `touse'
								return scalar f`i'`t'5		= `r(mean)'
							}
							else {
								return scalar f`i'`t'5		= .
							}
						}
						else {
							return scalar f`i'`t'5	   = . 						// This statistic doesn't make sense for the combined search
						}
						
						// Statistic 6: Type-I error p-value
						ttest ``i'`n'1'	   	   == ``i'tot'
						return scalar f`i'`t'6 	   = `r(p)'
					}
				}
				else {
					if `"`but'"'!="" {
						// Case 3: key==0 & but==1
						// Statistic 1: Total finds
						gen ``i'tot'	  	   = `not' if `touse'
						sum ``i'tot'	  	   if `touse'
						return scalar f`i'`t'1 	   = `r(sum)'
						
						// Statistic 2: Average finds per obs
						return scalar f`i'`t'2 	   = . 						// This statistic doesn't make sense for the combined search
						
						// Statistic 3: Average string length when keyword not is found
						gen  ``i'len'		   = cond(`not',ustrwordcount(`i'),0,.) if `touse'
						capture assert ``i'len'==0 | assert ``i'len'==.
						if _rc {
							sum ``i'`len''     if (``i'len'!=0 | ``i'len'!=.) & `touse'
							return scalar f`i'`t'3 = `r(mean)'
						}
						else {
							return scalar f`i'`t'3 = .
						}
						
						// Statistic 4: Average position when keyword is found
						return scalar f`i'`t'4 	   = . 						// This statistic doesn't make sense for the combined search
						
						// Statistic 5: TF-IDF
						return scalar f`i'`t'5	   = . 						// This statistic doesn't make sense for the combined search
						
						// Statistic 6: Type-I error p-value
						ttest ``i'`m'1'	   	   == ``i'tot'
						return scalar f`i'`t'6 	   = `r(p)'	
					}
				}
			} // quietly loop ends
			
			// Table commands
			if	`"`table'"'!="" {
					// No table (do nothing)
			}
			else if `"`table'"'=="" {
				// Table header
				di _newline
				di as text "The following table displays the keyword(s) and exclusion(s) criteria used in"
				di as text "the search and returns six statistics for each variable specified:" _newline
				di as text "Total finds: " _skip(10) "the number of observations when criterion is met."
				di as text "Average finds per obs: the average occurence of word when criterion is met."
				di as text "Average length: " _skip(7) "the average word length when criterion is met."
				di as text "Average position:" _skip(6) "the average position of match when criterion is met."
				di as text "Average tf-idf: " _skip(7) "the average term frequency-inverse document frequency"
				di as text _skip(23) "when the criterion is met."
				di as text "Type-I error p-value:  the p-value for a means comparison test across samples"
				di as text _skip(23) "identified by the different criteria." _newline
				di %~80s "{bf:Summary Table}"
				di "{hline 80}"
				di as result %-12s "variable:" as text `"`i'"'
				qui tab `i'
				di as text "n: `r(N)'" _continue
				di as text _col(28) %~44s "Average" _col(75) "Type-I"
				di as text _col(21) "Total" _col(29) _dup(41) "-" _col(76) "error"
				
				// Filling out keywords by row
				if `"`keyword'"'!="" {
					// Keyword==1
					di as result "keyword(s)" as text _col(21) "Finds" _col(32) "Finds" _col(42) "Length" _col(51) "Position" _col(64) "TF-IDF" _col(74) "p-value"
					di as text _dup(80) "-"
					forv z=1/`n' {
						local y: word `z' of `keyword'
						di as text %-14s abbrev(`"`y'"', 14) _continue
						di as text _skip(3) %8.0g `return(f`i'`z'1)' _continue
						di as text _skip(3) %8.0g `return(f`i'`z'2)' _continue
						di as text _skip(3) %8.0g `return(f`i'`z'3)' _continue
						di as text _skip(3) %8.0g `return(f`i'`z'4)' _continue
						di as text _skip(3) %8.0g `return(f`i'`z'5)' _continue
						di as text _skip(3) %8.0g `return(f`i'`z'6)'
					}
				}
				else {
					if `"`but'"'!="" {
						// Keyword==0 & exclusions==1
						di as result "exclusion(s)" as text _col(21) "Excl." _col(32) "Excl." _col(42) "Length" _col(51) "Position" _col(64) "TF-IDF" _col(74) "p-value"
						di as text _dup(80) "-"
						forv z=1/`m' {
							local y: word `z' of `but'
							di as text %-14s abbrev(`"`y'"', 14) _continue
							di as text _skip(3) %8.0g `return(n`i'`z'1)' _continue
							di as text _skip(3) %8.0g `return(n`i'`z'2)' _continue
							di as text _skip(3) %8.0g `return(n`i'`z'3)' _continue
							di as text _skip(3) %8.0g `return(n`i'`z'4)' _continue
							di as text _skip(3) %8.0g `return(n`i'`z'5)' _continue
							di as text _skip(3) %8.0g `return(n`i'`z'6)'
						}
					}
				}
				di as text _dup(80) "-"
				di as text %-14s abbrev("Total finds",14) _continue
				di as text _skip(3) %8.0g `return(f`i'`t'1)' _continue
				di as text _skip(3) %8.0g `return(f`i'`t'2)' _continue
				di as text _skip(3) %8.0g `return(f`i'`t'3)' _continue
				di as text _skip(3) %8.0g `return(f`i'`t'4)' _continue
				di as text _skip(3) %8.0g `return(f`i'`t'5)' _continue
				di as text _skip(3) %8.0g `return(f`i'`t'6)'
				di "{hline 80}"
				di as result "exclusion(s):"
				di as text `"`return(allbut)'"'
			}
			
			// key matrix creation
			if `n'>0 {
				local w=`n'+1
				matrix key = J(`w',6,.)
				forv z=1/`w' {
					forv j=1/6 {
						matrix key[`z',`j'] = `return(f`i'`z'`j')'
					}
				}
				return matrix key = key, copy
			}
			
			// but matrix creation
			if `m'>0 {
				local w=`m'
				if `"`keyword'"'=="" {
					local w=`m'+1
				}
				matrix but = J(`w',6,.)
				forv z=1/`m' {
					forv j=1/6 {
						matrix but[`z',`j'] = `return(n`i'`z'`j')'
					}
				}
				if `"`keyword'"'=="" {
					forv j=1/6 {
						matrix but[`w',`j'] = `return(f`i'1`j')'
					}
				}
				return matrix but = but, copy
			}
			
			// Actions
			if `"`tag'"'!="" {
				// Tag marks observations that meet the compiled criteria.
				clonevar `tag'= ``i'tot'
			}
			if `"`nfinds'"'!="" {
				// Number of finds creates as many new variables as keywords containing the number of
				// finds within each observation.
				if `n'!=0 {
					forv z=1/`n' {
						local y: word `z' of `keyword'
						clonevar `i'`z'_nfinds = ``i'`z'2' 
					}
				}
				else {
					di _newline
					di as result "Number of finds" as text " variables are only created when keyword is specified."
				}
			}
			if `"`length'"'!="" {
				// Length creates a new variable with the word length of observation.
				clonevar `i'_len = ``i'len'
			}
			if `"`position'"'!="" {
				// Position creates as many new variables as keywords containing the position
				// the keyword was first found.
				if `n'!=0 {
					forv z=1/`n' {
						local y: word `z' of `keyword'
						clonevar `i'`z'_pos = ``i'`z'4' 
					}
				}
				else {
					di _newline
					di as result "Avg. position" as text " variables are only created when keyword is specified."
				}
			}
			if `"`tfidf'"'!="" {
				// TF-IDF creates the tf-idf statistic per observation when keyword is specified.
				if `n'!=0 {
					forv z=1/`n' {
						local y: word `z' of `keyword'
						clonevar `i'`z'_tfidf = ``i'`z'5' 
					}
				}
				else {
					di _newline
					di as result "TF-IDF" as text " statistics are only created when keyword is specified."
				}
			}
		}
	}
end
