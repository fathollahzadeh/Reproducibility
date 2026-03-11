 
 WITH p_filtered AS
  (SELECT Id
   FROM posts
   WHERE Score <= 44
     AND FavoriteCount BETWEEN 0 AND 3
     AND CreationDate BETWEEN '2010-08-11 13:53:56' :: timestamp AND '2014-09-03 11:52:36' :: timestamp)
SELECT SUM(
             (SELECT count(*)
              FROM comments c
              WHERE c.PostId = p.Id
                AND c.CreationDate >= '2010-08-01 12:12:41' :: timestamp) *
             (SELECT count(*)
              FROM postLinks pl
              WHERE pl.PostId = p.Id
                AND pl.LinkTypeId = 1
                AND pl.CreationDate <= '2014-08-11 17:26:31' :: timestamp) *
             (SELECT count(*)
              FROM postHistory ph
              WHERE ph.PostId = p.Id
                AND ph.CreationDate >= '2010-09-20 19:11:45' :: timestamp) *
             (SELECT count(*)
              FROM votes v
              WHERE v.PostId = p.Id
                AND v.CreationDate <= '2014-09-11 00:00:00' :: timestamp))
FROM p_filtered p
WHERE EXISTS
    (SELECT 1
     FROM comments c
     WHERE c.PostId = p.Id
       AND c.CreationDate >= '2010-08-11 13:53:56' :: timestamp)
  AND EXISTS
    (SELECT 1
     FROM postLinks pl
     WHERE pl.PostId = p.Id
       AND pl.LinkTypeId = 1
       AND pl.CreationDate <= '2014-08-11 17:26:31' :: timestamp)
  AND EXISTS
    (SELECT 1
     FROM postHistory ph
     WHERE ph.PostId = p.Id
       AND ph.CreationDate >= '2010-09-20 19:11:45' :: timestamp)
  AND EXISTS
    (SELECT 1
     FROM votes v
     WHERE v.PostId = p.Id
       AND v.CreationDate <= '2014-09-11 00:00:00' :: timestamp);