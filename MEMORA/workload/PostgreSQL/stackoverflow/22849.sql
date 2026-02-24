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

PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AverageViews,
        MAX(P.LastActivityDate) AS LastPostDate
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
    GROUP BY 
        P.OwnerUserId
),

UserRanking AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(UB.BadgeCount, 0) AS TotalBadges,
        COALESCE(PS.PostCount, 0) AS TotalPosts,
        COALESCE(PS.TotalScore, 0) AS TotalScore,
        COALESCE(PS.AverageViews, 0) AS AverageViews,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS Rank
    FROM 
        Users U
    LEFT JOIN 
        UserBadgeCounts UB ON U.Id = UB.UserId
    LEFT JOIN 
        PostStats PS ON U.Id = PS.OwnerUserId
),

ClosedPosts AS (
    SELECT 
        P.Id,
        PH.UserDisplayName AS ClosedBy,
        PH.CreationDate AS ClosedDate,
        P.Title,
        P.Score,
        (SELECT COUNT(C.Id) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount
    FROM 
        Posts P
    JOIN 
        PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId = 10
)

SELECT
    UR.Rank,
    UR.DisplayName,
    UR.TotalBadges,
    UR.TotalPosts,
    UR.TotalScore,
    UR.AverageViews,
    CP.Title,
    CP.ClosedBy,
    CP.ClosedDate,
    CP.Score,
    CP.CommentCount
FROM 
    UserRanking UR
LEFT JOIN 
    ClosedPosts CP ON UR.UserId = CP.Id
WHERE 
    UR.Rank <= 50
ORDER BY 
    UR.TotalScore DESC, 
    UR.TotalPosts DESC NULLS LAST
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;