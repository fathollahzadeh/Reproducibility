WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END) AS CommentCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY U.Id, U.Reputation
),
BadgeStats AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount,
        SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldBadgeCount,
        SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverBadgeCount,
        SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeBadgeCount
    FROM Badges
    GROUP BY UserId
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(*) AS TotalPosts,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        AVG(P.ViewCount) AS AverageViews
    FROM Posts P
    GROUP BY P.OwnerUserId
)

SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    US.PostCount,
    US.QuestionCount,
    US.AnswerCount,
    US.CommentCount,
    BS.BadgeCount,
    BS.GoldBadgeCount,
    BS.SilverBadgeCount,
    BS.BronzeBadgeCount,
    PS.TotalPosts,
    PS.TotalScore,
    PS.AverageViews
FROM Users U
LEFT JOIN UserStats US ON U.Id = US.UserId
LEFT JOIN BadgeStats BS ON U.Id = BS.UserId
LEFT JOIN PostStats PS ON U.Id = PS.OwnerUserId
ORDER BY U.Reputation DESC;