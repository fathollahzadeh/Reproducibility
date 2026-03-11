 
 WITH p_details AS
  (SELECT p.Id
   FROM posts p
   JOIN postLinks pl ON p.Id = pl.RelatedPostId
   JOIN postHistory ph ON p.Id = ph.PostId
   JOIN votes v ON p.Id = v.PostId
   WHERE p.Score >= -1
     AND p.ViewCount >= 0
     AND p.CommentCount <= 9
     AND ph.CreationDate BETWEEN '2010-09-20 17:45:15'::timestamp AND '2014-08-07 01:00:45'::timestamp
     AND v.VoteTypeId = 15),
     c_details AS
  (SELECT c.PostId
   FROM comments c
   JOIN badges b ON c.UserId = b.UserId
   WHERE c.CreationDate >= '2010-07-22 01:19:43'::timestamp)
SELECT COUNT(*)
FROM p_details
JOIN c_details ON p_details.Id = c_details.PostId;