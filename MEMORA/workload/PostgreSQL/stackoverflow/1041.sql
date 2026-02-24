
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId, 
        P.Title, 
        P.CreationDate, 
        P.Score, 
        P.ViewCount, 
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS rn
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 AND 
        P.Score > 0
),
UserStats AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty, 
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostHistoryStats AS (
    SELECT 
        PH.PostId, 
        COUNT(*) AS EditCount, 
        MAX(PH.CreationDate) AS LastEditDate
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (4, 5, 24) 
    GROUP BY 
        PH.PostId
)
SELECT 
    UP.DisplayName, 
    UP.TotalBounty, 
    UP.BadgeCount, 
    RP.Title, 
    RP.CreationDate, 
    RP.Score, 
    PH.EditCount, 
    PH.LastEditDate
FROM 
    UserStats UP
JOIN 
    RankedPosts RP ON RP.rn = 1 AND RP.PostId = UP.UserId  
LEFT JOIN 
    PostHistoryStats PH ON RP.PostId = PH.PostId
WHERE 
    UP.TotalBounty > 0
ORDER BY 
    UP.TotalBounty DESC, UP.BadgeCount DESC, RP.Score DESC
LIMIT 50;
