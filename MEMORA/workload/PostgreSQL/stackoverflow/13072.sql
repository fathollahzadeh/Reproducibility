WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        CreationDate,
        LastAccessDate,
        Views,
        UpVotes,
        DownVotes
    FROM Users
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate AS PostCreationDate,
        P.ViewCount,
        P.Score,
        P.AnswerCount,
        P.CommentCount,
        P.FavoriteCount,
        P.LastActivityDate,
        P.OwnerUserId,
        U.Reputation AS OwnerReputation
    FROM Posts P
    JOIN UserReputation U ON P.OwnerUserId = U.UserId
),
VoteSummary AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM Votes
    GROUP BY PostId
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.ViewCount,
    PS.Score,
    PS.AnswerCount,
    PS.CommentCount,
    PS.FavoriteCount,
    PS.OwnerReputation,
    V.UpVotes,
    V.DownVotes,
    PS.PostCreationDate,
    PS.LastActivityDate,
    EXTRACT(EPOCH FROM (cast('2024-10-01 12:34:56' as timestamp) - PS.PostCreationDate)) AS AgeInSeconds,
    EXTRACT(EPOCH FROM (cast('2024-10-01 12:34:56' as timestamp) - PS.LastActivityDate)) AS InactivityDurationInSeconds
FROM PostStatistics PS
LEFT JOIN VoteSummary V ON PS.PostId = V.PostId
ORDER BY PS.Score DESC, PS.ViewCount DESC
LIMIT 100;