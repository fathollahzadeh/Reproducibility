WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopScoringPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CreationDate,
        u.DisplayName AS OwnerName,
        u.Reputation AS OwnerReputation,
        u.Views AS OwnerViews,
        pht.Name AS HistoryTypeName,
        COUNT(ph.Id) AS EditCount
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN 
        PostHistory ph ON rp.PostId = ph.PostId
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        rp.Rank = 1
    GROUP BY 
        rp.PostId, rp.Title, rp.Score, rp.ViewCount, rp.CreationDate, u.DisplayName, u.Reputation, u.Views, pht.Name
)
SELECT 
    tsp.PostId,
    tsp.Title,
    tsp.Score,
    tsp.ViewCount,
    tsp.CreationDate,
    tsp.OwnerName,
    tsp.OwnerReputation,
    tsp.OwnerViews,
    tsp.HistoryTypeName,
    tsp.EditCount
FROM 
    TopScoringPosts tsp
ORDER BY 
    tsp.Score DESC, tsp.ViewCount DESC
LIMIT 10;