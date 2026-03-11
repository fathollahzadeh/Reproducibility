 
 WITH badge_counts AS
  (SELECT UserId,
          count(*) AS b_count
   FROM badges
   WHERE Date <= '2014-09-11 14:33:06' :: timestamp
   GROUP BY UserId)
SELECT sum(bc.b_count)
FROM comments c
JOIN badge_counts bc ON c.UserId = bc.UserId
WHERE c.Score = 0;