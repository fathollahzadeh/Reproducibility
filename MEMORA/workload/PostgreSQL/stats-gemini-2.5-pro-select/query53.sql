 
 WITH post_products AS
  (SELECT p.OwnerUserId,
          (c.n * pl.n) AS prod
   FROM
     (SELECT Id,
             OwnerUserId
      FROM posts
      WHERE ViewCount >= 0) AS p
   JOIN
     (SELECT PostId,
             COUNT(*) AS n
      FROM comments
      WHERE CreationDate <= '2014-09-08 15:58:08' :: timestamp
      GROUP BY PostId) AS c ON p.Id = c.PostId
   JOIN
     (SELECT RelatedPostId,
             COUNT(*) AS n
      FROM postLinks
      GROUP BY RelatedPostId) AS pl ON p.Id = pl.RelatedPostId)
SELECT SUM(pp.prod * b.n)
FROM post_products AS pp
JOIN
  (SELECT UserId,
          COUNT(*) AS n
   FROM badges
   GROUP BY UserId) AS b ON pp.OwnerUserId = b.UserId
JOIN users u ON pp.OwnerUserId = u.Id
AND u.Reputation >= 1;