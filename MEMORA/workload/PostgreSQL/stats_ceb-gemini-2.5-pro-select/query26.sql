 
 WITH filtered_users AS
  (SELECT Id
   FROM users
   WHERE UpVotes >= 0
     AND CreationDate >= '2010-08-21 21:27:38' :: timestamp),
     filtered_comments AS
  (SELECT PostId
   FROM comments
   WHERE CreationDate >= '2010-07-21 11:05:37' :: timestamp
     AND CreationDate <= '2014-08-25 17:59:25' :: timestamp)
SELECT COUNT(*)
FROM posts AS p
JOIN filtered_users AS u ON p.OwnerUserId = u.Id
JOIN filtered_comments AS c ON p.Id = c.PostId
JOIN postLinks AS pl ON p.Id = pl.RelatedPostId;