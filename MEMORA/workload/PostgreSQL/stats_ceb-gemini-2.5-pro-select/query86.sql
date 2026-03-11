 
 WITH relevant_posts AS
  (SELECT c.PostId
   FROM comments AS c
   JOIN users AS u ON c.UserId = u.Id
   WHERE c.Score = 0
     AND u.Views >= 0
     AND u.Views <= 74)
SELECT COUNT(*)
FROM relevant_posts AS rp
JOIN votes AS v ON rp.PostId = v.PostId;