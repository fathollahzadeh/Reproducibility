WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.CreationDate,
        U.DisplayName AS OwnerDisplay,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.ViewCount DESC) AS RankedViewCount
    FROM 
        Posts P
    INNER JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1 
        AND P.ViewCount IS NOT NULL
),
TopComments AS (
    SELECT 
        C.PostId,
        COUNT(C.Id) AS CommentCount
    FROM 
        Comments C
    GROUP BY 
        C.PostId
),
RecentPostHistory AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        PHT.Name AS ChangeType
    FROM 
        PostHistory PH
    INNER JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    WHERE 
        PH.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.ViewCount,
    RP.OwnerDisplay,
    COALESCE(TC.CommentCount, 0) AS TotalComments,
    COALESCE(PH.ChangeType, 'No Recent Changes') AS RecentChangeType
FROM 
    RankedPosts RP
LEFT JOIN 
    TopComments TC ON RP.PostId = TC.PostId
LEFT JOIN 
    RecentPostHistory PH ON RP.PostId = PH.PostId
WHERE 
    RP.RankedViewCount = 1
ORDER BY 
    RP.ViewCount DESC;