 
 WITH user_branch AS
  (SELECT v.UserId,
          COUNT(*) AS user_multiplicity
   FROM votes AS v
   JOIN users AS u ON v.UserId = u.Id
   WHERE v.BountyAmount <= 50
     AND v.CreationDate BETWEEN '2010-07-21 00:00:00' :: timestamp AND '2014-09-14 00:00:00' :: timestamp
     AND u.Views >= 0
     AND u.CreationDate <= '2014-08-19 21:33:14'::timestamp
   GROUP BY v.UserId)
SELECT SUM(ub.user_multiplicity)
FROM comments AS c
JOIN user_branch AS ub ON c.UserId = ub.UserId
JOIN posts AS p ON c.PostId = p.Id
JOIN postLinks AS pl ON p.Id = pl.PostId
JOIN postHistory AS ph ON p.Id = ph.PostId
WHERE c.CreationDate BETWEEN '2010-07-26 20:21:15' :: timestamp AND '2014-09-13 01:26:16' :: timestamp
  AND p.Score BETWEEN -1 AND 19
  AND p.CommentCount <= 13
  AND ph.PostHistoryTypeId = 2
  AND ph.CreationDate <= '2014-08-07 12:06:00'::timestamp;