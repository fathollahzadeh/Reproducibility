 
 WITH filtered_users AS
  (SELECT Id
   FROM users
   WHERE DownVotes <= 0
     AND UpVotes >= 0
     AND CreationDate >= '2010-09-18 01:58:41'::timestamp),
     filtered_comments AS
  (SELECT PostId,
          UserId
   FROM comments
   WHERE Score = 0
     AND CreationDate BETWEEN '2010-07-20 06:26:28'::timestamp AND '2014-09-11 18:45:09'::timestamp),
     filtered_posts AS
  (SELECT Id
   FROM posts
   WHERE PostTypeId = 1
     AND FavoriteCount BETWEEN 0 AND 2),
     filtered_posthistory AS
  (SELECT PostId
   FROM postHistory
   WHERE PostHistoryTypeId = 5)
SELECT COUNT(*)
FROM filtered_comments AS c
JOIN filtered_posts AS p ON c.PostId = p.Id
JOIN filtered_users AS u ON c.UserId = u.Id
JOIN postLinks AS pl ON p.Id = pl.PostId
JOIN filtered_posthistory AS ph ON p.Id = ph.PostId
JOIN votes AS v ON u.Id = v.UserId;