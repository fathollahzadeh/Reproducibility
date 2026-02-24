
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation, U.CreationDate, U.LastAccessDate
),
PostSummary AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.FavoriteCount,
        COALESCE(A.OwnerUserId, -1) AS AcceptedAnswerUserId
    FROM Posts P
    LEFT JOIN Posts A ON P.AcceptedAnswerId = A.Id
    WHERE P.PostTypeId = 1 
)
SELECT 
    U.DisplayName AS UserName,
    U.Reputation,
    U.PostCount,
    U.CommentCount,
    U.TotalBounty,
    P.Title AS QuestionTitle,
    P.CreationDate AS QuestionCreationDate,
    P.Score AS QuestionScore,
    P.ViewCount AS QuestionViewCount,
    P.AnswerCount AS QuestionAnswerCount,
    P.CommentCount AS QuestionCommentCount,
    P.FavoriteCount AS QuestionFavoriteCount,
    CASE 
        WHEN P.AcceptedAnswerUserId = -1 THEN 'No Accepted Answer'
        ELSE (SELECT DisplayName FROM Users WHERE Id = P.AcceptedAnswerUserId)
    END AS AcceptedAnswerUserName
FROM UserStats U
LEFT JOIN PostSummary P ON U.UserId = P.AcceptedAnswerUserId
ORDER BY U.Reputation DESC, U.PostCount DESC;
