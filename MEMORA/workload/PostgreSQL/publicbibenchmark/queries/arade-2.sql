SELECT arade1.f4 AS f4 FROM arade1 WHERE ((CAST(arade1.f3 as DATE) >= cast('2014-10-17' as DATE)) AND (CAST(arade1.f3 as DATE) <= cast('2015-10-16' as DATE))) GROUP BY f4 LIMIT 130;
