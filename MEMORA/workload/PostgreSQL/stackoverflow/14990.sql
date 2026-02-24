WITH UserPostCounts AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(P.Id) AS PostCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.Reputation
),

UserBadgeCounts AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Badges B
    GROUP BY 
        B.UserId
),

OverallStats AS (
    SELECT
        UPC.UserId,
        UPC.Reputation,
        UPC.PostCount,
        COALESCE(UBC.BadgeCount, 0) AS BadgeCount
    FROM 
        UserPostCounts UPC
    LEFT JOIN 
        UserBadgeCounts UBC ON UPC.UserId = UBC.UserId
)

SELECT 
    UserId,
    Reputation,
    PostCount,
    BadgeCount,
    (PostCount + BadgeCount) AS TotalScore
FROM 
    OverallStats
ORDER BY 
    TotalScore DESC
LIMIT 10;