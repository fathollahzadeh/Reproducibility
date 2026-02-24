WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN P.AnswerCount ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END) AS CommentCount,
        SUM(B.Class) AS BadgeCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Badges B ON U.Id = B.UserId
    WHERE U.Reputation > 0
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        AVG(P.Score) AS AvgScore,
        MAX(P.ViewCount) AS MaxViewCount,
        MAX(P.CreationDate) AS LatestPostDate
    FROM Posts P
    GROUP BY P.OwnerUserId
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.Reputation,
    US.PostCount,
    US.QuestionCount,
    US.AnswerCount,
    US.CommentCount,
    US.BadgeCount,
    PS.TotalPosts,
    PS.AvgScore,
    PS.MaxViewCount,
    PS.LatestPostDate
FROM UserStats US
LEFT JOIN PostStats PS ON US.UserId = PS.OwnerUserId
ORDER BY US.Reputation DESC, US.PostCount DESC;
