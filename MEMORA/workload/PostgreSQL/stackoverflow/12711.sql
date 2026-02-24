WITH UserPostCounts AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS PostCount,
        SUM(ViewCount) AS TotalViews,
        SUM(Score) AS TotalScore
    FROM 
        Posts
    GROUP BY 
        OwnerUserId
),
UserBadgeCounts AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
),
UserMetrics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(UPC.PostCount, 0) AS PostCount,
        COALESCE(UPC.TotalViews, 0) AS TotalViews,
        COALESCE(UPC.TotalScore, 0) AS TotalScore,
        COALESCE(UBC.BadgeCount, 0) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        UserPostCounts UPC ON U.Id = UPC.OwnerUserId
    LEFT JOIN 
        UserBadgeCounts UBC ON U.Id = UBC.UserId
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    TotalViews,
    TotalScore,
    BadgeCount
FROM 
    UserMetrics
ORDER BY 
    PostCount DESC, 
    TotalScore DESC;