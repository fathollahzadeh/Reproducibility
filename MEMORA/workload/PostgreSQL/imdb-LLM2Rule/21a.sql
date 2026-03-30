SELECT MIN("t"."name") AS "company_name", MIN("t"."link") AS "link_type", MIN("title"."title") AS "western_follow_up"
FROM (SELECT *
FROM (VALUES (NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)) AS "t" ("imdb_id", "id", "country_code", "md5sum", "name_pcode_nf", "name_pcode_sf", "name", "id0", "kind", "id1", "keyword", "phonetic_code", "id2", "link", "id3", "movie_id", "company_id", "company_type_id", "note", "id4", "movie_id0", "info_type_id", "info", "note0", "id5", "movie_id1", "keyword_id", "id6", "movie_id2", "linked_movie_id", "link_type_id")
WHERE 1 = 0) AS "t",
"title"