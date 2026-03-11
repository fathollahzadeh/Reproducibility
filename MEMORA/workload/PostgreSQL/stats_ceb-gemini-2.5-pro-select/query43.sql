 
 WITH user_posts AS
  (SELECT p.OwnerUserId,
          count(*) AS n
   FROM posts AS p
   WHERE p.Score >= -7
   GROUP BY p.OwnerUserId),
     user_ph AS
  (SELECT ph.UserId,
          count(*) AS n
   FROM posthistory AS ph
   WHERE ph.PostHistoryTypeId = 3
   GROUP BY ph.UserId),
     user_badges AS
  (SELECT b.UserId,
          count(*) AS n
   FROM badges AS b
   GROUP BY b.UserId)
SELECT sum(up.n * uph.n * ub.n)
FROM users AS u
JOIN user_posts AS up ON u.Id = up.OwnerUserId
JOIN user_ph AS uph ON u.Id = uph.UserId
JOIN user_badges AS ub ON u.Id = ub.UserId
WHERE u.Reputation >= 1
  AND u.UpVotes >= 0
  AND u.UpVotes <= 117;