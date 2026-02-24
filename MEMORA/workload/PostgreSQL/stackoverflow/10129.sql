WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostsCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        COUNT(DISTINCT C.Id) AS CommentsCount,
        COUNT(DISTINCT B.Id) AS BadgesCount,
        SUM(V.BountyAmount) AS TotalBountyAmount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.UserId = U.Id
    GROUP BY U.Id, U.DisplayName
)
SELECT 
    UserId,
    DisplayName,
    PostsCount,
    QuestionsCount,
    AnswersCount,
    CommentsCount,
    BadgesCount,
    TotalBountyAmount
FROM UserPostStats
ORDER BY PostsCount DESC
LIMIT 100;