
\set localpath `pwd`'/PostHistoryTypes.csv'
copy PostHistoryTypes from :'localpath' with (delimiter ',', format csv, null '');

\set localpath `pwd`'/LinkTypes.csv'
copy LinkTypes from :'localpath' with (delimiter ',', format csv, null '');

\set localpath `pwd`'/PostTypes.csv'
copy PostTypes from :'localpath' with (delimiter ',', format csv, null '');

\set localpath `pwd`'/CloseReasonTypes.csv'
copy CloseReasonTypes from :'localpath' with (delimiter ',', format csv, null '');

\set localpath `pwd`'/VoteTypes.csv'
copy VoteTypes from :'localpath' with (delimiter ',', format csv, null '');

\set localpath `pwd`'/Users.csv'
copy Users from :'localpath' with (delimiter ',', format csv, null '');

\set localpath `pwd`'/Badges.csv'
copy Badges from :'localpath' with (delimiter ',', format csv, null '');

\set localpath `pwd`'/Posts.csv'
copy Posts from :'localpath' with (delimiter ',', format csv, null '');

\set localpath `pwd`'/Comments.csv'
copy Comments from :'localpath' with (delimiter ',', format csv, null '');

\set localpath `pwd`'/PostHistory.csv'
copy PostHistory from :'localpath' with (delimiter ',', format csv, null '');

\set localpath `pwd`'/PostLinks.csv'
copy PostLinks from :'localpath' with (delimiter ',', format csv, null '');

\set localpath `pwd`'/Tags.csv'
copy Tags from :'localpath' with (delimiter ',', format csv, null '');

\set localpath `pwd`'/Votes.csv'
copy Votes from :'localpath' with (delimiter ',', format csv, null '');
