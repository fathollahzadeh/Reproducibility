
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostsCreated,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsAsked,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersGiven,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostsCreated,
        QuestionsAsked,
        AnswersGiven,
        TotalViews,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank,
        RANK() OVER (ORDER BY TotalViews DESC) AS ViewRank
    FROM 
        UserReputation
),
BadgeCounts AS (
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
FinalReport AS (
    SELECT 
        TU.UserId,
        TU.DisplayName,
        TU.Reputation,
        TU.PostsCreated,
        TU.QuestionsAsked,
        TU.AnswersGiven,
        TU.TotalViews,
        COALESCE(BC.BadgeCount, 0) AS TotalBadges,
        COALESCE(BC.GoldBadges, 0) AS GoldBadges,
        COALESCE(BC.SilverBadges, 0) AS SilverBadges,
        COALESCE(BC.BronzeBadges, 0) AS BronzeBadges,
        TU.ReputationRank,
        TU.ViewRank
    FROM 
        TopUsers TU
    LEFT JOIN 
        BadgeCounts BC ON TU.UserId = BC.UserId
)
SELECT 
    *,
    (ReputationRank + ViewRank) AS OverallRank
FROM 
    FinalReport
WHERE 
    (ReputationRank + ViewRank) <= 10
ORDER BY 
    OverallRank;
