
WITH UserBadgeCount AS (
    SELECT 
        U.Id AS UserId, 
        COUNT(B.Id) AS BadgeCount, 
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),

PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(P.Score) AS TotalScore,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.AnswerCount) AS AvgAnswersPerQuestion,
        AVG(P.CommentCount) AS AvgCommentsPerPost
    FROM 
        Posts P
    WHERE 
        P.PostTypeId IN (1, 2) 
    GROUP BY 
        P.OwnerUserId
),

UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(UB.BadgeCount, 0) AS BadgeCount,
        COALESCE(PS.PostCount, 0) AS PostCount,
        COALESCE(PS.TotalScore, 0) AS TotalScore,
        COALESCE(PS.TotalViews, 0) AS TotalViews,
        COALESCE(PS.AvgAnswersPerQuestion, 0) AS AvgAnswersPerQuestion,
        COALESCE(PS.AvgCommentsPerPost, 0) AS AvgCommentsPerPost,
        COALESCE(UB.GoldBadges, 0) AS GoldBadges,
        COALESCE(UB.SilverBadges, 0) AS SilverBadges,
        COALESCE(UB.BronzeBadges, 0) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        UserBadgeCount UB ON U.Id = UB.UserId
    LEFT JOIN 
        PostStatistics PS ON U.Id = PS.OwnerUserId
)

SELECT 
    UE.DisplayName,
    UE.Reputation,
    UE.BadgeCount,
    UE.PostCount,
    UE.TotalScore,
    UE.TotalViews,
    UE.AvgAnswersPerQuestion,
    UE.AvgCommentsPerPost,
    CASE 
        WHEN UE.Reputation >= 1000 THEN 'High Reputation'
        WHEN UE.Reputation >= 500 THEN 'Medium Reputation'
        ELSE 'Low Reputation'
    END AS ReputationTier,
    CONCAT('Badges: Gold(', UE.GoldBadges, '), Silver(', UE.SilverBadges, '), Bronze(', UE.BronzeBadges, ')') AS BadgeSummary
FROM 
    UserEngagement UE
ORDER BY 
    UE.Reputation DESC, UE.PostCount DESC;
