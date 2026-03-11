 
 WITH filtered_users AS
  (SELECT Id
   FROM users
   WHERE DownVotes >= 0),
     user_posts AS
  (SELECT p.OwnerUserId,
          count(*) AS post_count
   FROM posts AS p
   JOIN tags AS t ON p.Id = t.ExcerptPostId
   JOIN filtered_users fu ON p.OwnerUserId = fu.Id
   GROUP BY p.OwnerUserId),
     user_votes AS
  (SELECT v.UserId,
          count(*) AS vote_count
   FROM votes AS v
   JOIN filtered_users fu ON v.UserId = fu.Id
   GROUP BY v.UserId),
     user_badges AS
  (SELECT b.UserId,
          count(*) AS badge_count
   FROM badges AS b
   JOIN filtered_users fu ON b.UserId = fu.Id
   GROUP BY b.UserId)
SELECT SUM(up.post_count * uv.vote_count * ub.badge_count)
FROM filtered_users AS u
JOIN user_posts AS up ON u.Id = up.OwnerUserId
JOIN user_votes AS uv ON u.Id = uv.UserId
JOIN user_badges AS ub ON u.Id = ub.UserId;