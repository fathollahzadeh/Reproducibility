 
 
SELECT SUM(T.total_count)
FROM
  (SELECT cb.total_badge_effect * pl.ct * ph.ct * v.ct AS total_count
   FROM posts AS p
   JOIN
     (SELECT c.PostId,
             SUM(b.ct) AS total_badge_effect
      FROM comments AS c
      JOIN
        (SELECT UserId,
                count(*) AS ct
         FROM badges
         WHERE Date >= '2010-07-30 03:49:24'::timestamp
         GROUP BY UserId) AS b ON c.UserId = b.UserId
      WHERE c.CreationDate BETWEEN '2010-07-26 20:21:15'::timestamp AND '2014-09-13 18:12:10'::timestamp
      GROUP BY c.PostId) AS cb ON p.Id = cb.PostId
   JOIN
     (SELECT RelatedPostId AS PostId,
             count(*) AS ct
      FROM postLinks
      GROUP BY RelatedPostId) AS pl ON p.Id = pl.PostId
   JOIN
     (SELECT PostId,
             count(*) AS ct
      FROM postHistory
      GROUP BY PostId) AS ph ON p.Id = ph.PostId
   JOIN
     (SELECT PostId,
             count(*) AS ct
      FROM votes
      WHERE VoteTypeId = 2
        AND CreationDate >= '2010-07-27 00:00:00'::timestamp
      GROUP BY PostId) AS v ON p.Id = v.PostId
   WHERE p.Score <= 61
     AND p.ViewCount <= 3627
     AND p.AnswerCount BETWEEN 0 AND 5
     AND p.CommentCount <= 8
     AND p.FavoriteCount >= 0) AS T;