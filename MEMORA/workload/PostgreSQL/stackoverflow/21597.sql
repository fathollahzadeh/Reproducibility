WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE 
        u.Reputation > 100
),
FilteredTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount
    FROM 
        Tags T
    JOIN Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.TagName
    HAVING 
        COUNT(P.Id) > 5
),
PostHistoryInfo AS (
    SELECT 
        PH.PostId,
        MIN(CASE WHEN PH.PostHistoryTypeId = 10 THEN PH.CreationDate END) AS ClosureDate,
        COUNT(CASE WHEN PH.PostHistoryTypeId IN (10, 11) THEN PH.Id END) AS ClosureCount
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId
)
SELECT 
    RP.PostId,
    RP.Title,
    COALESCE(PH.ClosureCount, 0) AS TotalClosureVotes,
    F.TagName,
    RP.CreationDate,
    RP.ViewCount,
    RP.Score
FROM 
    RankedPosts RP
LEFT JOIN 
    PostHistoryInfo PH ON RP.PostId = PH.PostId
LEFT JOIN 
    FilteredTags F ON RP.Title LIKE '%' || F.TagName || '%'
WHERE 
    RP.rn = 1
ORDER BY 
    RP.Score DESC, RP.ViewCount DESC
LIMIT 10;