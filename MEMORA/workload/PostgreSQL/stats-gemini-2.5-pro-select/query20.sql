 
 WITH valid_post_ids AS
  (SELECT p.Id
   FROM posts AS p
   JOIN users AS u ON p.OwnerUserId = u.Id
   WHERE u.Reputation >= 1
     AND u.Reputation <= 6524
     AND u.Views >= 0
     AND p.CreationDate >= '2010-07-26 19:26:37' :: timestamp
     AND p.CreationDate <= '2014-08-22 14:43:39' :: timestamp)
SELECT COUNT(*)
FROM postHistory AS ph
WHERE ph.CreationDate <= '2014-08-17 21:24:11' :: timestamp
  AND ph.PostId IN
    (SELECT Id
     FROM valid_post_ids);