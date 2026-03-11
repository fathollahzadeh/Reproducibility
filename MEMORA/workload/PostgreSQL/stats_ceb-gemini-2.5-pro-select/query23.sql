 
 WITH filtered_vote_counts AS
  (SELECT UserId,
          COUNT(*) AS v_count
   FROM votes
   WHERE UserId IN
       (SELECT id
        FROM users
        WHERE DownVotes >= 0
          AND DownVotes <= 0)
   GROUP BY UserId)
SELECT SUM(fvc.v_count)
FROM filtered_vote_counts fvc
JOIN badges b ON fvc.UserId = b.UserId;