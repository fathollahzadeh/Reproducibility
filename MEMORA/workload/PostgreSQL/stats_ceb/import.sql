\set localpath `pwd`'/badges.csv'
copy badges from :'localpath' with CSV header;

\set localpath `pwd`'/comments.csv'
copy comments from :'localpath' with CSV header;

\set localpath `pwd`'/users.csv'
copy users from :'localpath' with CSV header;

\set localpath `pwd`'/tags.csv'
copy tags from :'localpath' with CSV header;

\set localpath `pwd`'/posts.csv'
copy posts from :'localpath' with CSV header;

\set localpath `pwd`'/votes.csv'
copy votes from :'localpath' with CSV header;

\set localpath `pwd`'/postHistory.csv'
copy posthistory from :'localpath' with CSV header;

\set localpath `pwd`'/postLinks.csv'
copy postlinks from :'localpath' with CSV header;