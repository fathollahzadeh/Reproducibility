WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(P.Score) AS TotalScore,
        SUM(P.ViewCount) AS TotalViews
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
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges B
    GROUP BY 
        B.UserId
),
PostHistoryStats AS (
    SELECT 
        PH.UserId,
        COUNT(PH.Id) AS HistoryCount,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoreUpdates
    FROM 
        PostHistory PH
    JOIN 
        Posts P ON PH.PostId = P.Id
    GROUP BY 
        PH.UserId
)
SELECT 
    US.UserId,
    US.Reputation,
    US.PostCount,
    US.QuestionCount,
    US.AnswerCount,
    US.TotalScore,
    US.TotalViews,
    COALESCE(BS.BadgeCount, 0) AS BadgeCount,
    COALESCE(BS.GoldBadges, 0) AS GoldBadges,
    COALESCE(BS.SilverBadges, 0) AS SilverBadges,
    COALESCE(BS.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(PHS.HistoryCount, 0) AS HistoryCount,
    COALESCE(PHS.PositiveScoreUpdates, 0) AS PositiveScoreUpdates
FROM 
    UserStats US
LEFT JOIN 
    BadgeStats BS ON US.UserId = BS.UserId
LEFT JOIN 
    PostHistoryStats PHS ON US.UserId = PHS.UserId
ORDER BY 
    US.TotalScore DESC, US.Reputation DESC;