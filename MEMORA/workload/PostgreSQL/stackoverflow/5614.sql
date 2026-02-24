WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
        LEFT JOIN Users u ON p.OwnerUserId = u.Id
        LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
        AND p.PostTypeId IN (1, 2) 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
TopRankedPosts AS (
    SELECT 
        rp.*,
        pt.Name AS PostType,
        ht.Name AS HistoryType
    FROM 
        RankedPosts rp
        JOIN PostTypes pt ON pt.Id = CASE WHEN rp.Rank = 1 THEN 1 ELSE 2 END
        LEFT JOIN PostHistory ph ON ph.PostId = rp.PostId
        LEFT JOIN PostHistoryTypes ht ON ph.PostHistoryTypeId = ht.Id
    WHERE 
        rp.Rank <= 3
)
SELECT 
    trp.PostId,
    trp.Title,
    trp.CreationDate,
    trp.Score,
    trp.ViewCount,
    trp.OwnerDisplayName,
    trp.CommentCount,
    trp.PostType,
    trp.HistoryType
FROM 
    TopRankedPosts trp
ORDER BY 
    trp.Score DESC, 
    trp.ViewCount DESC, 
    trp.CreationDate DESC
LIMIT 20;