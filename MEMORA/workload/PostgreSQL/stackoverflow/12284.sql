
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBountyAmount,
        SUM(COALESCE(C.Score, 0)) AS TotalCommentScore
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        COUNT(C.Id) AS CommentCount,
        SUM(CASE WHEN V.voteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.voteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id, P.Title, P.Score, P.ViewCount
)
SELECT 
    U.DisplayName,
    U.PostCount,
    U.QuestionCount,
    U.AnswerCount,
    U.TotalBountyAmount,
    U.TotalCommentScore,
    P.Title AS PostTitle,
    P.Score AS PostScore,
    P.ViewCount AS PostViewCount,
    P.CommentCount AS PostCommentCount,
    P.UpVoteCount,
    P.DownVoteCount
FROM UserStats U
JOIN PostStats P ON U.UserId = P.PostId  
ORDER BY U.PostCount DESC, U.TotalBountyAmount DESC;
