
WITH UserReputation AS (
    SELECT Id, Reputation
    FROM Users
    WHERE Reputation > (SELECT AVG(Reputation) FROM Users)
),
HighScoringPosts AS (
    SELECT P.Id, P.Score, P.Title, U.DisplayName, P.CreationDate, P.OwnerUserId
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
    WHERE P.Score > 100 AND P.PostTypeId = 1
),
PostComments AS (
    SELECT C.PostId, COUNT(C.Id) AS CommentCount
    FROM Comments C
    GROUP BY C.PostId
),
PostVoteCounts AS (
    SELECT V.PostId, 
           SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes V
    GROUP BY V.PostId
)
SELECT PS.Title, 
       PS.Score AS PostScore, 
       UC.Reputation AS UserReputation, 
       COALESCE(PC.CommentCount, 0) AS TotalComments,
       COALESCE(PVC.UpVotes, 0) AS UpVotes,
       COALESCE(PVC.DownVotes, 0) AS DownVotes,
       PS.CreationDate
FROM HighScoringPosts PS
JOIN UserReputation UC ON PS.OwnerUserId = UC.Id
LEFT JOIN PostComments PC ON PS.Id = PC.PostId
LEFT JOIN PostVoteCounts PVC ON PS.Id = PVC.PostId
ORDER BY UC.Reputation DESC, PS.Score DESC
LIMIT 50;
