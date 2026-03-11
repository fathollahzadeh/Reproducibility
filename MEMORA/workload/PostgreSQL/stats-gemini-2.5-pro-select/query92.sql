 
 
SELECT COUNT(*)
FROM postHistory AS ph
WHERE EXISTS
    (SELECT 1
     FROM posts AS p
     JOIN users AS u ON p.OwnerUserId = u.Id
     WHERE p.Id = ph.PostId
       AND p.CreationDate BETWEEN '2010-08-17 19:08:05' :: timestamp AND '2014-08-31 06:58:12' :: timestamp
       AND u.UpVotes BETWEEN 0 AND 9);