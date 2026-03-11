
SELECT MIN(t.title)
FROM title AS t
WHERE t.id IN (
                 (SELECT t_inner.id
                  FROM title AS t_inner
                  JOIN kind_type AS kt ON t_inner.kind_id = kt.id
                  WHERE t_inner.production_year > 1950
                    AND kt.kind = 'movie') INTERSECT
                 (SELECT mk.movie_id
                  FROM movie_keyword AS mk
                  JOIN keyword AS k ON mk.keyword_id = k.id
                  WHERE k.keyword IN ('superhero', 'sequel', 'second-part', 'marvel-comics', 'based-on-comic', 'tv-special', 'fight', 'violence')) INTERSECT
                 (SELECT ci.movie_id
                  FROM cast_info AS ci
                  JOIN char_name AS chn ON ci.person_role_id = chn.id
                  WHERE chn.name NOT LIKE '%Sherlock%'
                    AND (chn.name LIKE '%Tony%Stark%'
                         OR chn.name LIKE '%Iron%Man%')) INTERSECT
                 (SELECT cc.movie_id
                  FROM complete_cast AS cc
                  JOIN comp_cast_type AS cct1 ON cc.subject_id = cct1.id
                  JOIN comp_cast_type AS cct2 ON cct2.id = cc.status_id
                  WHERE cct1.kind = 'cast'
                    AND cct2.kind LIKE '%complete%'));