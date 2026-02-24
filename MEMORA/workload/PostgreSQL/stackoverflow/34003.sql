
WITH RECURSIVE UserBadges AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
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
PostStatistics AS (
    SELECT 
        P.OwnerUserId, 
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        AVG(P.Score) AS AvgScore,
        COALESCE(MAX(P.CreationDate), CAST('1900-01-01' AS timestamp)) AS LastPostDate
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
UsersWithPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(PS.TotalPosts, 0) AS TotalPosts,
        COALESCE(PS.Questions, 0) AS Questions,
        COALESCE(PS.Answers, 0) AS Answers,
        COALESCE(PS.AvgScore, 0) AS AvgScore,
        COALESCE(PS.LastPostDate, CAST('1900-01-01' AS timestamp)) AS LastPostDate,
        UB.GoldBadges,
        UB.SilverBadges,
        UB.BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        PostStatistics PS ON U.Id = PS.OwnerUserId
    LEFT JOIN 
        UserBadges UB ON U.Id = UB.UserId
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.TotalPosts,
    U.Questions,
    U.Answers,
    U.AvgScore,
    U.LastPostDate,
    (U.GoldBadges + U.SilverBadges + U.BronzeBadges) AS TotalBadges,
    CASE 
        WHEN U.TotalPosts > 100 THEN 'Active Contributor'
        WHEN U.TotalPosts BETWEEN 50 AND 100 THEN 'Moderately Active'
        ELSE 'New Contributor'
    END AS ActivityStatus
FROM 
    UsersWithPostStats U
WHERE 
    (U.TotalPosts > 0 OR U.GoldBadges > 0 OR U.SilverBadges > 0 OR U.BronzeBadges > 0)
ORDER BY 
    U.TotalPosts DESC, U.AvgScore DESC
LIMIT 50;
