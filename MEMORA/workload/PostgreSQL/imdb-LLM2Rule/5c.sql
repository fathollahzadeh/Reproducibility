SELECT MIN("t"."title") AS "american_movie"
FROM (
SELECT *
FROM "title"
WHERE "production_year" > 1990
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
WHERE "note" LIKE '%(USA)%' AND "note" NOT LIKE '%(TV)%'
INTERSECT
SELECT "id"
FROM "movie_info"
WHERE "info" IN ('American', 'Denish', 'Denmark', 'German', 'Germany', 'Norway', 'Norwegian', 'Sweden', 'Swedish', 'USA')
) AS "sub"
ON "t"."id" = "sub"."id"