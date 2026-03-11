 
 WITH filtered_users AS
  (SELECT Id
   FROM users
   WHERE DownVotes <= 0),
     filtered_posts AS
  (SELECT Id,
          OwnerUserId
   FROM posts
   WHERE CommentCount >= 0),
     filtered_badges AS
  (SELECT UserId
   FROM badges
   WHERE Date <= '2014-08-22 02:21:55' :: timestamp)
SELECT COUNT(*)
FROM filtered_users u
JOIN filtered_badges b ON u.Id = b.UserId
JOIN filtered_posts p ON u.Id = p.OwnerUserId
JOIN tags t ON p.Id = t.ExcerptPostId
JOIN postHistory ph ON u.Id = ph.UserId;