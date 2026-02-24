
WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        DisplayName,
        Reputation,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
), 
PostStats AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.Title,
        Posts.CreationDate,
        COUNT(Comments.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN Votes.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN Votes.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        COALESCE(SUM(CASE WHEN Votes.VoteTypeId = 1 THEN 1 ELSE 0 END), 0) AS AcceptedByOriginatorCount
    FROM Posts
    LEFT JOIN Comments ON Posts.Id = Comments.PostId
    LEFT JOIN Votes ON Posts.Id = Votes.PostId
    WHERE Posts.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY Posts.Id, Posts.Title, Posts.CreationDate
), 
PostMetrics AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        CommentCount,
        UpVoteCount,
        DownVoteCount,
        (UpVoteCount - DownVoteCount) AS Score,
        CASE 
            WHEN AcceptedByOriginatorCount > 0 THEN 'Accepted'
            ELSE 'Not Accepted'
        END AS AcceptanceStatus
    FROM PostStats
)
SELECT 
    UR.DisplayName,
    UR.Reputation,
    UR.ReputationRank,
    PM.Title,
    PM.CreationDate,
    PM.CommentCount,
    PM.UpVoteCount,
    PM.DownVoteCount,
    PM.Score,
    PM.AcceptanceStatus
FROM UserReputation UR
JOIN Posts P ON P.OwnerUserId = UR.UserId
JOIN PostMetrics PM ON P.Id = PM.PostId
WHERE PM.Score > 0
  AND UR.ReputationRank <= 10
ORDER BY UR.Reputation DESC, PM.Score DESC;
