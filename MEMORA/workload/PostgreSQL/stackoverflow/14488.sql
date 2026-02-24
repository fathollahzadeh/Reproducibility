WITH UserVoteCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS VoteUpCount,
        SUM(CASE WHEN V.VoteTypeId IN (3) THEN 1 ELSE 0 END) AS VoteDownCount
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        COALESCE(P.AnswerCount, 0) AS AnswerCount,
        COALESCE(P.CommentCount, 0) AS CommentCount,
        MAX(COALESCE(CASE WHEN V.VoteTypeId = 2 THEN 1 END, 0)) AS Upvoted,
        MAX(COALESCE(CASE WHEN V.VoteTypeId = 3 THEN 1 END, 0)) AS Downvoted
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title, P.Score, P.ViewCount, P.AnswerCount, P.CommentCount
)
SELECT 
    U.DisplayName,
    U.TotalVotes,
    U.VoteUpCount,
    U.VoteDownCount,
    P.Title AS PostTitle,
    P.Score AS PostScore,
    P.ViewCount AS PostViewCount,
    P.AnswerCount AS PostAnswerCount,
    P.CommentCount AS PostCommentCount,
    P.Upvoted,
    P.Downvoted
FROM 
    UserVoteCounts U
JOIN 
    PostStatistics P ON P.PostId IN (
        SELECT PostId 
        FROM Votes V 
        WHERE V.UserId = U.UserId
    )
ORDER BY 
    U.TotalVotes DESC, 
    P.Score DESC;