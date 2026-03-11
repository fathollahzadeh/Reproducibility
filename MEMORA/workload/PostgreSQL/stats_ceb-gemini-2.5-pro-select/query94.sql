 
 WITH filtered_users AS
  (SELECT Id
   FROM users
   WHERE CreationDate >= '2010-12-15 06:00:24'::timestamp),
     qualifying_posts AS
  (SELECT p.OwnerUserId,
          COUNT(*) AS post_count
   FROM posts AS p
   JOIN filtered_users fu ON p.OwnerUserId = fu.Id
   WHERE p.CommentCount >= 0
   GROUP BY p.OwnerUserId),
     user_votes AS
  (SELECT v.UserId,
          COUNT(*) AS vote_count
   FROM votes AS v
   JOIN filtered_users fu ON v.UserId = fu.Id
   GROUP BY v.UserId)
SELECT SUM(qp.post_count * user_votes.vote_count)
FROM qualifying_posts AS qp
JOIN user_votes ON qp.OwnerUserId = user_votes.UserId;