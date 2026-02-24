WITH UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS TotalBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
RecentPostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        AVG(P.ViewCount) AS AvgViewCount,
        AVG(P.Score) AS AvgScore
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'  
    GROUP BY 
        P.OwnerUserId
),
UserPostHistory AS (
    SELECT 
        PH.UserId,
        COUNT(PH.Id) AS TotalEdits,
        STRING_AGG(DISTINCT P.Title, ', ') AS EditedPostTitles
    FROM 
        PostHistory PH
    JOIN 
        Posts P ON PH.PostId = P.Id
    WHERE 
        PH.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'  
    GROUP BY 
        PH.UserId
),
CombineStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(UBC.TotalBadges, 0) AS BadgeCount,
        COALESCE(RPS.TotalPosts, 0) AS PostsCount,
        COALESCE(RPS.AvgViewCount, 0) AS AvgViewCount,
        COALESCE(RPS.AvgScore, 0) AS AvgScore,
        COALESCE(UPH.TotalEdits, 0) AS TotalEdits,
        COALESCE(UPH.EditedPostTitles, 'None') AS EditedPostTitles
    FROM 
        Users U
    LEFT JOIN 
        UserBadgeCounts UBC ON U.Id = UBC.UserId
    LEFT JOIN 
        RecentPostStats RPS ON U.Id = RPS.OwnerUserId
    LEFT JOIN 
        UserPostHistory UPH ON U.Id = UPH.UserId
)
SELECT 
    *,
    CASE 
        WHEN PostsCount > 50 THEN 'High Activity'
        WHEN PostsCount BETWEEN 20 AND 50 THEN 'Moderate Activity'
        ELSE 'Low Activity'
    END AS ActivityLevel
FROM 
    CombineStats
ORDER BY 
    BadgeCount DESC, PostsCount DESC, AvgScore DESC
LIMIT 10;