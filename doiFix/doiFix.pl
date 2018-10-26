#!perl -wp

use strict;
use Getopt::Std;
our $opt_j, # convert to JSON by wrapping in array: [line1, line2, ...]
our $opt_l; # convert to JSONLD by also prepending a context: {"@context": {...}, "@graph": [line1, line2, ...]}

BEGIN {
  getopts("jl");
  $opt_j ||= $opt_l;        # JSONLD *is* JSON
  print <<'EOF' if $opt_l;  # JSONLD context
{
  "@context": {
    "@base": "https://github.com/sandrolabruzzo/doiBoost/data/",
    "@vocab": "https://github.com/sandrolabruzzo/doiBoost/ontology/",
    "doib": "https://github.com/sandrolabruzzo/doiBoost/ontology/",
    "xsd": "http://www.w3.org/2001/XMLSchema#",
    "doi-url": "@id",
    "type": "@type",
    "issued": {"@type": "xsd:date"},
    "published-print": {"@type": "xsd:date"},
    "published-online": {"@type": "xsd:date"},
    "date-time": {"type": "xsd:dateTime"},
    "authors": {"@id": "doib:author"},
    "instances": {"@id": "doib:instance"}
  },
 "@graph": 
EOF
  print "[\n" if $opt_j; # JSON array start
}

END {
  print "]" if $opt_j;  # JSON array end
  print "}" if $opt_l;  # JSONLD end
}

print ",\n" if ($opt_j || $opt_l) && $. > 1;  # JSON array separator

s{^"(.*)"$}{$1};                              # strip surrounding quotes
s{'\\"delay-in-days'}{'delay-in-days'}g;      # this field name starts with double quote (wicked)
s{['\w-]+': (None|\[\]|u'UNKNOWN')}{}g;       # kill null/empty/useless values
s{, (?=,)}{}g;                                # remove doubled comma delimiters resulting from prev step
s{([\[\{]), }{$1}g;                           # remove leading comma delimiter
s{, ([\]\}])}{$1}g;                           # remove trailing comma delimiter
s{-(\d)-}{-0$1-}g;                            # fix dates to 2-digit month
s{-(\d)'}{-0$1'}g;                            # fix dates to 2-digit day
s{(': |, )([\[\{]*)u'}{$1$2'}g;               # remove strange unicode string marker
s{\\x}{\\u00}g;                               # JSON uses unicode escapes \uXXXX rather than \xXX. Pray we get valid unicode chars
s{\\\\\\\\u}{\\u}g;                           # fix quadruple backslashes to single backslashes
s{'}{"}g;                                     # JSON strings/keys should use double quotes not single quotes. TODO: check what happens to some "O'Hara" name (in general O')
s{(?<=http://dx.doi.org/)(\S+)}{              # URL-encode chars that are not allowed in URL
  local $_ = $1;
  s{([<>])}{sprintf("%%%2x",ord($1))}ge;
  $_
}e;