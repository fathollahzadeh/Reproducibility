WITH FilteredKeywords AS
  (SELECT id,
          keyword
   FROM keyword
   WHERE keyword = 'marvel-cinematic-universe'),
     FilteredTitles AS
  (SELECT id,
          title
   FROM title
   WHERE production_year > 2010)
SELECT MIN(fk.keyword),
       MIN(n.name),
       MIN(ft.title)
FROM FilteredKeywords AS fk
JOIN movie_keyword AS mk ON fk.id = mk.keyword_id
JOIN FilteredTitles AS ft ON mk.movie_id = ft.id
JOIN cast_info AS ci ON ft.id = ci.movie_id
JOIN name AS n ON ci.person_id = n.id
WHERE n.name LIKE '%Downey%Robert%';