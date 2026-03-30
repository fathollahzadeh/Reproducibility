SELECT MIN("t1"."note") AS "production_note", MIN("title"."title") AS "movie_title", MIN("title"."production_year") AS "movie_year"
FROM (SELECT *
FROM "company_type"
WHERE "kind" = 'production companies') AS "t"
CROSS JOIN (SELECT *
FROM "info_type"
WHERE "info" = 'top 250 rank') AS "t0"
INNER JOIN (SELECT *
FROM "movie_companies"
WHERE ("note" LIKE '%(co-production)%' OR "note" LIKE '%(presents)%') AND "note" NOT LIKE '%(as Metro-Goldwyn-Mayer Pictures)%') AS "t1" ON "t"."id" = "t1"."company_type_id"
INNER JOIN "movie_info_idx" ON "t1"."movie_id" = "movie_info_idx"."movie_id" AND "t0"."id" = "movie_info_idx"."info_type_id"
INNER JOIN "title" ON "t1"."movie_id" = "title"."id"