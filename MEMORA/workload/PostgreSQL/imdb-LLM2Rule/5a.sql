SELECT MIN("t"."title") AS "typical_european_movie"
FROM (
SELECT *
FROM "title"
WHERE "production_year" > 2005
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
WHERE "note" LIKE '%(theatrical)%' AND "note" LIKE '%(France)%'
INTERSECT
SELECT "id"
FROM "movie_info"
WHERE "info" IN ('Denish', 'Denmark', 'German', 'Germany', 'Norway', 'Norwegian', 'Sweden', 'Swedish')
) AS "sub"
ON "t"."id" = "sub"."id"