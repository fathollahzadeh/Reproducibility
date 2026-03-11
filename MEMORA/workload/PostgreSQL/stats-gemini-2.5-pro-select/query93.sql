 
 WITH user_post_counts AS
  (SELECT p.OwnerUserId,
          COUNT(*) AS num_posts
   FROM posts AS p
   WHERE p.PostTypeId = 2
     AND p.CreationDate <= '2014-08-26 22:40:26' :: timestamp
   GROUP BY p.OwnerUserId),
     user_vote_counts AS
  (SELECT v.UserId,
          COUNT(*) AS num_votes
   FROM votes AS v
   GROUP BY v.UserId)
SELECT SUM(upc.num_posts * uvc.num_votes)
FROM users AS u
JOIN user_post_counts AS upc ON u.Id = upc.OwnerUserId
JOIN user_vote_counts AS uvc ON u.Id = uvc.UserId
WHERE u.Views >= 0;