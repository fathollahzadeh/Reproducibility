 
 WITH user_counts AS
  (SELECT u.Id,
          b.c AS badge_count,
          c.c AS comment_count
   FROM users u
   JOIN
     (SELECT UserId,
             COUNT(*) AS c
      FROM badges
      GROUP BY 1) b ON u.Id = b.UserId
   JOIN
     (SELECT UserId,
             COUNT(*) AS c
      FROM comments
      WHERE CreationDate <= '2014-09-10 00:33:30' :: timestamp
      GROUP BY 1) c ON u.Id = c.UserId
   WHERE u.DownVotes <= 0
     AND u.UpVotes <= 47),
     ph_counts AS
  (SELECT UserId,
          COUNT(*) AS c
   FROM postHistory
   GROUP BY 1)
SELECT SUM(uc.badge_count * uc.comment_count * pc.c)
FROM user_counts uc
JOIN ph_counts pc ON uc.Id = pc.UserId;