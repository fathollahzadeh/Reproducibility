 
 
SELECT SUM(c.n_comments * ph.n_ph * v.n_votes)
FROM users u
JOIN
  (SELECT UserId,
          COUNT(*) AS n_comments
   FROM comments
   WHERE CreationDate BETWEEN '2010-08-12 20:33:46'::timestamp AND '2014-09-13 19:26:55'::timestamp
   GROUP BY UserId) c ON u.id = c.UserId
JOIN
  (SELECT UserId,
          COUNT(*) AS n_ph
   FROM postHistory
   WHERE CreationDate BETWEEN '2011-04-11 14:46:09'::timestamp AND '2014-08-17 16:37:23'::timestamp
   GROUP BY UserId) ph ON u.id = ph.UserId
JOIN
  (SELECT UserId,
          COUNT(*) AS n_votes
   FROM votes
   WHERE CreationDate BETWEEN '2010-07-26 00:00:00'::timestamp AND '2014-09-12 00:00:00'::timestamp
   GROUP BY UserId) v ON u.id = v.UserId
WHERE u.Views BETWEEN 0 AND 783
  AND u.DownVotes BETWEEN 0 AND 1
  AND u.UpVotes <= 123;