WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UPVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        SUM(COALESCE(CAST(P.ViewCount AS INT), 0)) AS TotalViews
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName
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
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.PostCount,
    U.QuestionCount,
    U.AnswerCount,
    U.UPVoteCount,
    U.DownVoteCount,
    U.TotalViews,
    B.BadgeCount,
    B.GoldBadgeCount,
    B.SilverBadgeCount,
    B.BronzeBadgeCount
FROM UserStats U
LEFT JOIN BadgeStats B ON U.UserId = B.UserId
ORDER BY U.TotalViews DESC;