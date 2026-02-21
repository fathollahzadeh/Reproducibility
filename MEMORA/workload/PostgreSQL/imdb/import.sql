delete from aka_name;
delete from movie_info;

\set localpath `pwd`'/aka_name.csv'
copy aka_name from:'localpath' delimiter ','  NULL AS '' QUOTE '"' ESCAPE '\' csv;

\set localpath `pwd`'/movie_info.csv'
copy movie_info from:'localpath' delimiter ','  NULL AS '' QUOTE '"' ESCAPE '\' csv;

\set localpath `pwd`'/company_type.csv'
copy company_type from:'localpath' delimiter ','  NULL AS '' QUOTE '"' ESCAPE '\' csv;

\set localpath `pwd`'/comp_cast_type.csv'
copy comp_cast_type from:'localpath' delimiter ','  NULL AS '' QUOTE '"' ESCAPE '\' csv;

\set localpath `pwd`'/movie_link.csv'
copy movie_link from:'localpath' delimiter ','  NULL AS '' QUOTE '"' ESCAPE '\' csv;

\set localpath `pwd`'/name.csv'
copy name from:'localpath' delimiter ','  NULL AS '' QUOTE '"' ESCAPE '\' csv;

\set localpath `pwd`'/aka_title.csv'
copy aka_title from:'localpath' delimiter ','  NULL AS '' QUOTE '"' ESCAPE '\' csv;

\set localpath `pwd`'/keyword.csv'
copy keyword from:'localpath' delimiter ','  NULL AS '' QUOTE '"' ESCAPE '\' csv;

\set localpath `pwd`'/link_type.csv'
copy link_type from:'localpath' delimiter ','  NULL AS '' QUOTE '"' ESCAPE '\' csv;

\set localpath `pwd`'/role_type.csv'
copy role_type from:'localpath' delimiter ','  NULL AS '' QUOTE '"' ESCAPE '\' csv;

\set localpath `pwd`'/person_info.csv'
copy person_info from:'localpath' delimiter ','  NULL AS '' QUOTE '"' ESCAPE '\' csv;

\set localpath `pwd`'/kind_type.csv'
copy kind_type from:'localpath' delimiter ','  NULL AS '' QUOTE '"' ESCAPE '\' csv;

\set localpath `pwd`'/company_name.csv'
copy company_name from:'localpath' delimiter ','  NULL AS '' QUOTE '"' ESCAPE '\' csv;

\set localpath `pwd`'/title.csv'
copy title from:'localpath' delimiter ','  NULL AS '' QUOTE '"' ESCAPE '\' csv;

\set localpath `pwd`'/movie_info_idx.csv'
copy movie_info_idx from:'localpath' delimiter ',' csv  NULL AS '';

\set localpath `pwd`'/movie_keyword.csv'
copy movie_keyword from:'localpath' delimiter ','  NULL AS '' QUOTE '"' ESCAPE '\' csv;

\set localpath `pwd`'/movie_companies.csv'
copy movie_companies from:'localpath' delimiter ','  NULL AS '' QUOTE '"' ESCAPE '\' csv;

\set localpath `pwd`'/cast_info.csv'
copy cast_info from:'localpath' delimiter ','  NULL AS '' QUOTE '"' ESCAPE '\' csv;

\set localpath `pwd`'/char_name.csv'
copy char_name from:'localpath' delimiter ','  NULL AS '' QUOTE '"' ESCAPE '\' csv;

\set localpath `pwd`'/info_type.csv'
copy info_type from:'localpath' delimiter ','  NULL AS '' QUOTE '"' ESCAPE '\' csv;

\set localpath `pwd`'/complete_cast.csv'
copy complete_cast from:'localpath' delimiter ','  NULL AS '' QUOTE '"' ESCAPE '\' csv;