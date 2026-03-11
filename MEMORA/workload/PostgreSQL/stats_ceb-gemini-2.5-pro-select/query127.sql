 
 WITH filtered_posts AS
  (SELECT Id
   FROM posts
   WHERE FavoriteCount >= 0
     AND CreationDate BETWEEN '2010-07-23 02:00:12'::timestamp AND '2014-09-08 13:52:41'::timestamp),
     filtered_comments AS
  (SELECT PostId
   FROM comments
   WHERE Score = 0),
     filtered_postlinks AS
  (SELECT PostId
   FROM postLinks
   WHERE LinkTypeId = 1
     AND CreationDate >= '2011-10-06 21:41:26' :: timestamp),
     filtered_votes AS
  (SELECT PostId
   FROM votes
   WHERE VoteTypeId = 2)
SELECT COUNT(*)
FROM filtered_posts p
JOIN filtered_comments c ON p.Id = c.PostId
JOIN filtered_postlinks pl ON p.Id = pl.PostId
JOIN filtered_votes v ON p.Id = v.PostId
JOIN postHistory ph ON p.Id = ph.PostId;