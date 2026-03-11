 
 WITH filtered_core AS
  (SELECT p.Id AS post_id,
          u.Id AS user_id
   FROM posts AS p
   JOIN postLinks AS pl ON p.Id = pl.RelatedPostId
   JOIN users AS u ON p.OwnerUserId = u.Id
   WHERE p.Score = 1
     AND p.ViewCount >= 0
     AND p.FavoriteCount >= 0
     AND pl.LinkTypeId = 1
     AND pl.CreationDate >= '2011-04-12 15:23:59' :: timestamp
     AND u.CreationDate >= '2011-02-08 18:11:37' :: timestamp)
SELECT SUM(
             (SELECT COUNT(*)
              FROM comments c
              WHERE c.PostId = fc.post_id) *
             (SELECT COUNT(*)
              FROM badges b
              WHERE b.UserId = fc.user_id))
FROM filtered_core fc;