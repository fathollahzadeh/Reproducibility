 
 
SELECT COUNT(*)
FROM posts AS p
JOIN users AS u ON p.OwnerUserId = u.Id
JOIN votes AS v ON p.Id = v.PostId
JOIN postHistory AS ph ON p.Id = ph.PostId
WHERE p.PostTypeId = 1
  AND p.AnswerCount BETWEEN 0 AND 4
  AND u.DownVotes = 0
  AND u.CreationDate <= '2014-08-08 07:03:29'::timestamp
  AND v.CreationDate BETWEEN '2010-07-20 00:00:00' :: timestamp AND '2014-09-03 00:00:00' :: timestamp
  AND ph.CreationDate <= '2014-07-28 13:25:35'::timestamp;