SELECT MIN("t"."title") AS "movie_title"
FROM (
SELECT *
FROM "title"
) AS "t"
INNER JOIN (
SELECT "id"
FROM "company_name"
WHERE "country_code" = '[us]'
INTERSECT
SELECT "id"
FROM "keyword"
WHERE "keyword" = 'character-name-in-title'
INTERSECT
SELECT "id"
FROM "movie_companies"
INTERSECT
SELECT "id"
FROM "movie_keyword"
) AS "sub"
ON "t"."id" = "sub"."id"