 
 WITH user_badges AS
  (SELECT UserId,
          count(*) AS c
   FROM badges
   WHERE Date BETWEEN '2010-07-20 20:47:27'::timestamp AND '2014-09-09 13:24:28'::timestamp
   GROUP BY UserId),
     user_posts AS
  (SELECT OwnerUserId,
          count(*) AS c
   FROM posts
   WHERE CreationDate <= '2014-09-02 10:21:04'::timestamp
     AND AnswerCount <= 4
     AND CommentCount BETWEEN 0 AND 12
     AND FavoriteCount BETWEEN 0 AND 89
   GROUP BY OwnerUserId),
     user_posthistory AS
  (SELECT UserId,
          count(*) AS c
   FROM posthistory
   WHERE PostHistoryTypeId = 2
     AND CreationDate BETWEEN '2011-01-08 03:03:48'::timestamp AND '2014-08-25 14:04:43'::timestamp
   GROUP BY UserId)
SELECT sum(ub.c * up.c * uph.c)
FROM users u
JOIN user_badges ub ON u.Id = ub.UserId
JOIN user_posts up ON u.Id = up.OwnerUserId
JOIN user_posthistory uph ON u.Id = uph.UserId
WHERE u.Reputation <= 705
  AND u.CreationDate BETWEEN '2010-07-28 23:56:00'::timestamp AND '2014-09-02 10:04:41'::timestamp;