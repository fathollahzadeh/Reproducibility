
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoreCount,
        AVG(P.Score) AS AvgScore,
        MAX(P.CreationDate) AS LatestPostDate
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.Reputation
),

BadgeStats AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadgeCount,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadgeCount,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadgeCount
    FROM 
        Badges B
    GROUP BY 
        B.UserId
)

SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    COALESCE(US.PostCount, 0) AS PostCount,
    COALESCE(US.QuestionCount, 0) AS QuestionCount,
    COALESCE(US.AnswerCount, 0) AS AnswerCount,
    COALESCE(US.PositiveScoreCount, 0) AS PositiveScoreCount,
    COALESCE(US.AvgScore, 0) AS AvgScore,
    COALESCE(US.LatestPostDate, '1970-01-01') AS LatestPostDate,
    COALESCE(BS.BadgeCount, 0) AS BadgeCount,
    COALESCE(BS.GoldBadgeCount, 0) AS GoldBadgeCount,
    COALESCE(BS.SilverBadgeCount, 0) AS SilverBadgeCount,
    COALESCE(BS.BronzeBadgeCount, 0) AS BronzeBadgeCount
FROM 
    Users U
LEFT JOIN 
    UserStats US ON U.Id = US.UserId
LEFT JOIN 
    BadgeStats BS ON U.Id = BS.UserId
ORDER BY 
    U.Reputation DESC;
