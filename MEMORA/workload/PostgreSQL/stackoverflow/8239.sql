
WITH UserVoteStats AS (
    SELECT 
        UserId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM Votes
    GROUP BY UserId
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        U.Id AS OwnerUserId,
        U.DisplayName AS OwnerDisplayName,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT A.Id) AS AnswerCount,
        COALESCE(SUM(VS.UpVotes), 0) AS TotalUpVotes,
        COALESCE(SUM(VS.DownVotes), 0) AS TotalDownVotes,
        P.CreationDate,
        P.Score
    FROM Posts P
    LEFT JOIN Users U ON P.OwnerUserId = U.Id
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Posts A ON P.Id = A.ParentId AND A.PostTypeId = 2
    LEFT JOIN UserVoteStats VS ON U.Id = VS.UserId
    WHERE P.CreationDate >= '2020-01-01'
    GROUP BY P.Id, P.Title, U.Id, U.DisplayName, P.CreationDate, P.Score
),
FinalStats AS (
    SELECT 
        PS.*,
        CASE 
            WHEN Score > 0 THEN 'Positive' 
            WHEN Score < 0 THEN 'Negative' 
            ELSE 'Neutral' 
        END AS ScoreTrend
    FROM PostStats PS
)
SELECT 
    PostId,
    Title,
    OwnerUserId,
    OwnerDisplayName,
    CommentCount,
    AnswerCount,
    TotalUpVotes,
    TotalDownVotes,
    Score,
    ScoreTrend
FROM FinalStats
WHERE TotalUpVotes + TotalDownVotes > 10
ORDER BY Score DESC, CommentCount DESC
LIMIT 100;
