WITH UserBadgeCounts AS (
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
        COUNT(P.Id) AS TotalPosts,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS Questions,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS Answers,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
UserPostBadgeStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(UBC.BadgeCount, 0) AS BadgeCount,
        COALESCE(PS.TotalPosts, 0) AS TotalPosts,
        COALESCE(PS.Questions, 0) AS Questions,
        COALESCE(PS.Answers, 0) AS Answers,
        COALESCE(PS.TotalViews, 0) AS TotalViews,
        COALESCE(PS.TotalScore, 0) AS TotalScore
    FROM 
        Users U
    LEFT JOIN 
        UserBadgeCounts UBC ON U.Id = UBC.UserId
    LEFT JOIN 
        PostStatistics PS ON U.Id = PS.OwnerUserId
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.BadgeCount,
    U.TotalPosts,
    U.Questions,
    U.Answers,
    U.TotalViews,
    U.TotalScore,
    CASE 
        WHEN U.Reputation > 10000 THEN 'Expert'
        WHEN U.Reputation BETWEEN 1000 AND 10000 THEN 'Experienced'
        ELSE 'Novice'
    END AS UserLevel
FROM 
    UserPostBadgeStats U
ORDER BY 
    U.Reputation DESC,
    U.BadgeCount DESC,
    U.TotalPosts DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;
