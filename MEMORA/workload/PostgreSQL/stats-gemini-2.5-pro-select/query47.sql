 
 WITH p_counts AS
  (SELECT OwnerUserId,
          count(*) AS ct
   FROM posts
   WHERE Score <= 13
     AND AnswerCount BETWEEN 0 AND 4
     AND CommentCount >= 0
     AND FavoriteCount <= 2
   GROUP BY OwnerUserId),
     c_counts AS
  (SELECT UserId,
          count(*) AS ct
   FROM comments
   GROUP BY UserId),
     ph_counts AS
  (SELECT UserId,
          count(*) AS ct
   FROM postHistory
   WHERE PostHistoryTypeId = 3
   GROUP BY UserId),
     v_counts AS
  (SELECT UserId,
          count(*) AS ct
   FROM votes
   WHERE BountyAmount <= 50
   GROUP BY UserId)
SELECT sum(p.ct * c.ct * ph.ct * v.ct)
FROM users u
JOIN p_counts p ON u.id = p.OwnerUserId
JOIN c_counts c ON u.id = c.UserId
JOIN ph_counts ph ON u.id = ph.UserId
JOIN v_counts v ON u.id = v.UserId
WHERE u.DownVotes >= 0;