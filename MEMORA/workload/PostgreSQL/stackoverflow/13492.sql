WITH UserPostCounts AS (
    SELECT 
        U.Id AS UserId,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(P.Score) AS TotalScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
),
UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Badges B
    GROUP BY 
        B.UserId
),
FinalMetrics AS (
    SELECT 
        UPC.UserId,
        UPC.PostCount,
        UPC.Questions,
        UPC.Answers,
        UPC.TotalScore,
        COALESCE(UB.BadgeCount, 0) AS BadgeCount
    FROM 
        UserPostCounts UPC
    LEFT JOIN 
        UserBadges UB ON UPC.UserId = UB.UserId
)

SELECT 
    UserId,
    PostCount,
    Questions,
    Answers,
    TotalScore,
    BadgeCount,
    (PostCount + BadgeCount) AS TotalMetrics
FROM 
    FinalMetrics
ORDER BY 
    TotalMetrics DESC;