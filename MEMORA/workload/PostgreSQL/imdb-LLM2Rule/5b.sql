SELECT MIN("t"."title") AS "american_vhs_movie"
FROM (
SELECT *
FROM "title"
WHERE "production_year" > 2010
) AS "t"
INNER JOIN (
SELECT "id"
FROM "company_type"
WHERE "kind" = 'production companies'
INTERSECT
SELECT "id"
FROM "info_type"
INTERSECT
SELECT "id"
FROM "movie_companies"
WHERE "note" LIKE '%(VHS)%' AND "note" LIKE '%(USA)%' AND "note" LIKE '%(1994)%'
INTERSECT
SELECT "id"
FROM "movie_info"
WHERE "info" IN ('America', 'USA')
) AS "sub"
ON "t"."id" = "sub"."id"