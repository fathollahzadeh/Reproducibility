SELECT MIN("t"."keyword") AS "movie_keyword", MIN("t0"."name") AS "actor_name", MIN("t1"."title") AS "hero_movie"
FROM "cast_info"
CROSS JOIN (SELECT *
FROM "keyword"
WHERE "keyword" IN ('based-on-comic', 'fight', 'marvel-comics', 'second-part', 'sequel', 'superhero', 'tv-special', 'violence')) AS "t"
INNER JOIN "movie_keyword" ON "t"."id" = "movie_keyword"."keyword_id" AND "cast_info"."movie_id" = "movie_keyword"."movie_id"
INNER JOIN (SELECT *
FROM "name"
WHERE "name" LIKE '%Downey%Robert%') AS "t0" ON "cast_info"."person_id" = "t0"."id"
INNER JOIN (SELECT *
FROM "title"
WHERE "production_year" > 2014) AS "t1" ON "movie_keyword"."movie_id" = "t1"."id"