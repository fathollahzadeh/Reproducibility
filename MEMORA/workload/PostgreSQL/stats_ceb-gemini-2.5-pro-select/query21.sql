 
 
SELECT COUNT(*)
FROM votes AS v
WHERE v.CreationDate <= '2014-09-12 00:00:00'::timestamp
  AND v.PostId IN
    (SELECT id
     FROM posts
     WHERE Score >= -1
       AND CreationDate BETWEEN '2010-10-21 13:21:24'::timestamp AND '2014-09-09 15:12:22'::timestamp)
  AND v.UserId IN
    (SELECT id
     FROM users
     WHERE UpVotes >= 0
       AND CreationDate BETWEEN '2010-07-27 17:15:57'::timestamp AND '2014-09-03 12:47:42'::timestamp);