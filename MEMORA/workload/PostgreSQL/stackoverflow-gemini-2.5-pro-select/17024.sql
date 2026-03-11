WITH CommentCounts AS
  (SELECT PostId,
          COUNT(Id) AS Cnt
   FROM Comments
   GROUP BY PostId),
     VoteCounts AS
  (SELECT PostId,
          SUM(CASE
                  WHEN VoteTypeId = 2 THEN 1
                  ELSE 0
              END) AS UpVotes,
          SUM(CASE
                  WHEN VoteTypeId = 3 THEN 1
                  ELSE 0
              END) AS DownVotes
   FROM Votes
   GROUP BY PostId)
SELECT p.Id AS PostId,
       p.Title,
       p.CreationDate,
       u.DisplayName AS OwnerDisplayName,
       COALESCE(cc.Cnt, 0) AS CommentCount,
       COALESCE(vc.UpVotes, 0) AS UpVotes,
       COALESCE(vc.DownVotes, 0) AS DownVotes
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
LEFT JOIN CommentCounts cc ON p.Id = cc.PostId
LEFT JOIN VoteCounts vc ON p.Id = vc.PostId
WHERE p.PostTypeId = 1
ORDER BY p.CreationDate DESC
LIMIT 10;