 
 
SELECT COUNT(*)
FROM badges AS b,
     votes AS v,
     users AS u
WHERE u.Id = v.UserId
  AND v.UserId = b.UserId
  AND u.DownVotes = 0
  AND v.BountyAmount >= 0
  AND v.BountyAmount <= 50;