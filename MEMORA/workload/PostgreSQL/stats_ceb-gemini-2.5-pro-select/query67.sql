 
 WITH filtered_users AS
  (SELECT Id
   FROM users
   WHERE Reputation <= 270
     AND Views BETWEEN 0 AND 51
     AND DownVotes >= 0),
     filtered_posts AS
  (SELECT Id
   FROM posts
   WHERE PostTypeId = 1
     AND Score = 4
     AND ViewCount <= 4937),
     filtered_comments AS
  (SELECT PostId,
          UserId
   FROM comments
   WHERE Score = 0
     AND CreationDate BETWEEN '2010-08-02 20:27:48'::timestamp AND '2014-09-10 16:09:23'::timestamp)
SELECT COUNT(*)
FROM filtered_posts AS p
JOIN filtered_comments AS c ON p.Id = c.PostId
JOIN filtered_users AS u ON u.Id = c.UserId
JOIN postLinks AS pl ON p.Id = pl.PostId
AND pl.CreationDate >= '2011-11-03 05:09:35'::timestamp
JOIN postHistory AS ph ON p.Id = ph.PostId
AND ph.PostHistoryTypeId = 1
JOIN votes AS v ON u.Id = v.UserId;