WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= '2022-01-01'
),
HighestScoredPosts AS (
    SELECT 
        RP.PostId, 
        RP.Title,
        RP.Score,
        RP.ViewCount,
        RP.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        COALESCE(SUM(b.Class), 0) AS TotalBadges
    FROM 
        RankedPosts RP
    JOIN 
        Users U ON RP.OwnerUserId = U.Id
    LEFT JOIN 
        Badges b ON U.Id = b.UserId
    WHERE 
        RP.Rank = 1
    GROUP BY 
        RP.PostId, RP.Title, RP.Score, RP.ViewCount, RP.CreationDate, U.DisplayName
),
PostHistoryInfo AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS PostHistoryTypes,
        COUNT(DISTINCT ph.Id) AS EditCount
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    HSP.PostId,
    HSP.Title,
    HSP.Score,
    HSP.ViewCount,
    HSP.CreationDate,
    HSP.OwnerDisplayName,
    HPI.PostHistoryTypes,
    HPI.EditCount,
    (CASE 
        WHEN HSP.TotalBadges > 5 THEN 'Expert'
        WHEN HSP.TotalBadges BETWEEN 3 AND 5 THEN 'Intermediate'
        WHEN HSP.TotalBadges < 3 THEN 'Novice' 
        ELSE 'Unknown'
    END) AS UserLevel
FROM 
    HighestScoredPosts HSP
LEFT JOIN 
    PostHistoryInfo HPI ON HSP.PostId = HPI.PostId
WHERE 
    (HSP.Score > (SELECT AVG(Score) FROM Posts WHERE CreationDate >= '2022-01-01') OR HPI.EditCount > 5) 
    AND HSP.ViewCount IS NOT NULL
ORDER BY 
    HSP.Score DESC, HSP.ViewCount DESC
FETCH FIRST 10 ROWS ONLY;
