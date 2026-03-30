SELECT MIN("t"."info1") AS "movie_budget", MIN("t"."info2") AS "movie_votes", MIN("title"."title") AS "movie_title"
FROM (SELECT *
FROM (VALUES (NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)) AS "t" ("person_role_id", "person_id", "movie_id", "id", "role_id", "nr_order", "note", "id0", "info", "id1", "info0", "id2", "movie_id0", "info_type_id", "info1", "note0", "id3", "movie_id1", "info_type_id0", "info2", "note1", "imdb_id", "id4", "imdb_index", "gender", "name_pcode_cf", "name_pcode_nf", "surname_pcode", "md5sum", "name")
WHERE 1 = 0) AS "t",
"title"