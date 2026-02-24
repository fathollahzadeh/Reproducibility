WITH UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
ActivePosts AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AvgViewCount
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        P.OwnerUserId
),
PostHistorySummary AS (
    SELECT 
        PH.UserId,
        PH.PostId,
        COUNT(PH.Id) AS EditCount,
        MAX(PH.CreationDate) AS LastEditDate
    FROM 
        PostHistory PH
    GROUP BY 
        PH.UserId, PH.PostId
),
CombinedData AS (
    SELECT 
        UBC.UserId,
        UBC.DisplayName,
        COALESCE(AP.PostCount, 0) AS TotalPosts,
        COALESCE(AP.TotalScore, 0) AS TotalPostScore,
        COALESCE(AP.AvgViewCount, 0) AS AvgPostViewCount,
        COALESCE(PHS.EditCount, 0) AS TotalEdits,
        COALESCE(PHS.LastEditDate, '1970-01-01') AS LastEditTime,
        UBC.BadgeCount
    FROM 
        UserBadgeCounts UBC
    LEFT JOIN 
        ActivePosts AP ON UBC.UserId = AP.OwnerUserId
    LEFT JOIN 
        PostHistorySummary PHS ON UBC.UserId = PHS.UserId
)
SELECT 
    DisplayName,
    TotalPosts,
    TotalPostScore,
    AvgPostViewCount,
    TotalEdits,
    LastEditTime,
    BadgeCount
FROM 
    CombinedData
ORDER BY 
    BadgeCount DESC, TotalPostScore DESC
LIMIT 10;