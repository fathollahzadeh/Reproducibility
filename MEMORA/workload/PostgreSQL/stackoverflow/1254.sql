WITH RankedPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.ViewCount,
        P.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.ViewCount DESC) AS Rank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(P.Score) AS TotalScore
    FROM 
        Users U
    INNER JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        P.ViewCount > 100
    GROUP BY 
        U.Id, U.DisplayName
    HAVING 
        SUM(P.Score) > 0
),
ClosestPosts AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS CloseCount,
        MAX(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS Closed,
        MAX(CASE WHEN PH.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS Reopened
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId
)
SELECT 
    U.DisplayName,
    RP.Title,
    RP.ViewCount,
    COALESCE(CP.CloseCount, 0) AS CloseCount,
    COALESCE(CP.Closed, 0) AS Closed,
    COALESCE(CP.Reopened, 0) AS Reopened,
    RANK() OVER (ORDER BY U.TotalScore DESC) AS UserRank
FROM 
    TopUsers U
JOIN 
    RankedPosts RP ON U.UserId = RP.Id 
LEFT JOIN 
    ClosestPosts CP ON RP.Id = CP.PostId
WHERE 
    RP.Rank <= 5
ORDER BY 
    UserRank, RP.ViewCount DESC;