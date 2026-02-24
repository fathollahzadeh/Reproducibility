
WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        AVG(P.Score) AS AverageScore
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(UB.BadgeCount, 0) AS BadgeCount,
        COALESCE(PS.TotalPosts, 0) AS TotalPosts,
        COALESCE(PS.Questions, 0) AS Questions,
        COALESCE(PS.Answers, 0) AS Answers,
        COALESCE(PS.AverageScore, 0) AS AverageScore,
        ROW_NUMBER() OVER (ORDER BY COALESCE(PS.TotalPosts, 0) DESC, COALESCE(UB.BadgeCount, 0) DESC) AS EngagementRank
    FROM 
        Users U
    LEFT JOIN 
        UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN 
        PostStats PS ON U.Id = PS.OwnerUserId
)
SELECT 
    UEng.UserId,
    UEng.DisplayName,
    UEng.BadgeCount,
    UEng.TotalPosts,
    UEng.Questions,
    UEng.Answers,
    UEng.AverageScore,
    UEng.EngagementRank,
    CASE 
        WHEN UEng.BadgeCount > 10 THEN 'High Achiever'
        WHEN UEng.TotalPosts > 50 THEN 'Active Contributor'
        ELSE 'New User'
    END AS EngagementLevel
FROM 
    UserEngagement UEng
WHERE 
    UEng.EngagementRank <= 10
ORDER BY 
    UEng.EngagementRank;
