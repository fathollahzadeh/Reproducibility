 
 
SELECT SUM(p.p_cnt * c.c_cnt * b.b_cnt * ph.ph_cnt)
FROM
  (SELECT Id
   FROM users
   WHERE DownVotes <= 0
     AND UpVotes >= 0
     AND UpVotes <= 123) AS u
JOIN
  (SELECT OwnerUserId,
          COUNT(*) AS p_cnt
   FROM posts
   WHERE PostTypeId = 1
     AND ViewCount >= 0
     AND ViewCount <= 25597
     AND CommentCount >= 0
     AND CommentCount <= 11
     AND FavoriteCount >= 0
   GROUP BY OwnerUserId) AS p ON u.Id = p.OwnerUserId
JOIN
  (SELECT UserId,
          COUNT(*) AS c_cnt
   FROM comments
   WHERE CreationDate >= '2010-08-19 09:33:49' :: timestamp
     AND CreationDate <= '2014-08-28 06:54:21' :: timestamp
   GROUP BY UserId) AS c ON u.Id = c.UserId
JOIN
  (SELECT UserId,
          COUNT(*) AS b_cnt
   FROM badges
   GROUP BY UserId) AS b ON u.Id = b.UserId
JOIN
  (SELECT UserId,
          COUNT(*) AS ph_cnt
   FROM postHistory
   GROUP BY UserId) AS ph ON u.Id = ph.UserId;