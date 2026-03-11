 
 
SELECT COUNT(*)
FROM users AS u
JOIN badges AS b ON u.Id = b.UserId
JOIN posts AS p ON u.Id = p.OwnerUserId
JOIN votes AS v ON u.Id = v.UserId
JOIN tags AS t ON p.Id = t.ExcerptPostId
WHERE p.CommentCount >= 0
  AND p.CommentCount <= 13
  AND u.Reputation >= 1
  AND b.Date <= '2014-09-06 17:33:22'::timestamp;