WITH UserVoteCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        P.AnswerCount,
        P.CommentCount,
        U.DisplayName AS OwnerDisplayName,
        U.Reputation AS OwnerReputation,
        COUNT(C.ID) AS TotalComments
    FROM Posts P
    LEFT JOIN Users U ON P.OwnerUserId = U.Id
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY P.Id, P.Title, P.Score, P.ViewCount, P.CreationDate, P.AnswerCount, P.CommentCount, U.DisplayName, U.Reputation
),
BenchmarkStats AS (
    SELECT
        P.PostId,
        P.Title,
        P.OwnerDisplayName,
        P.OwnerReputation,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.TotalComments,
        UV.TotalVotes,
        UV.Upvotes,
        UV.Downvotes
    FROM PostStatistics P
    LEFT JOIN UserVoteCounts UV ON P.OwnerDisplayName = UV.DisplayName
)

SELECT 
    PostId,
    Title,
    OwnerDisplayName,
    OwnerReputation,
    Score,
    ViewCount,
    AnswerCount,
    CommentCount,
    TotalComments,
    TotalVotes,
    Upvotes,
    Downvotes
FROM BenchmarkStats
ORDER BY Score DESC, ViewCount DESC
LIMIT 100;