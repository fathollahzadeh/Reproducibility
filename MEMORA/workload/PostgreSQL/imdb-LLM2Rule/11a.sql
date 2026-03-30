SELECT MIN("t"."name") AS "from_company", MIN("t"."link") AS "movie_link_type", MIN("title"."title") AS "non_polish_sequel_movie"
FROM (SELECT *
FROM (VALUES (NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)) AS "t" ("imdb_id", "id", "country_code", "md5sum", "name_pcode_nf", "name_pcode_sf", "name", "id0", "kind", "id1", "keyword", "phonetic_code", "id2", "link", "id3", "movie_id", "company_id", "company_type_id", "note", "id4", "movie_id0", "keyword_id", "id5", "movie_id1", "linked_movie_id", "link_type_id")
WHERE 1 = 0) AS "t",
"title"