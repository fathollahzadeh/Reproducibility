 
 
SELECT COUNT(*)
FROM badges AS b
JOIN
  (SELECT Id
   FROM users
   WHERE UpVotes >= 0) AS u ON b.UserId = u.Id;