 
 WITH comment_counts AS
  (SELECT UserId,
          COUNT(*) AS c_count
   FROM comments
   WHERE Score = 0
   GROUP BY UserId)
SELECT SUM(cc.c_count *
             (SELECT COUNT(*)
              FROM votes v
              WHERE v.UserId = cc.UserId))
FROM comment_counts cc;