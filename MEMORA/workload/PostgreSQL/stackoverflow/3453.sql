WITH UserBadgeCounts AS (
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
        AVG(P.Score) AS AvgScore,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
TopUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        COALESCE(UB.BadgeCount, 0) AS BadgeCount,
        PU.TotalPosts,
        PU.Questions,
        PU.Answers,
        PU.AvgScore,
        PU.TotalViews
    FROM 
        Users U
    LEFT JOIN 
        UserBadgeCounts UB ON U.Id = UB.UserId
    LEFT JOIN 
        PostStats PU ON U.Id = PU.OwnerUserId
    WHERE 
        U.Reputation > 1000
)
SELECT 
    T.DisplayName,
    T.TotalPosts,
    T.Questions,
    T.Answers,
    T.BadgeCount,
    T.AvgScore,
    T.TotalViews
FROM 
    TopUsers T
ORDER BY 
    T.BadgeCount DESC, T.TotalPosts DESC
LIMIT 10;