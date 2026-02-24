
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        RANK() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Tags t ON t.ExcerptPostId = p.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
TopRankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        rp.Tags,
        rp.Rank
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10 
),
PostHistoryInfo AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName,
        ph.CreationDate AS ChangeDate,
        ph.PostHistoryTypeId,
        pht.Name AS ChangeType,
        ph.Comment AS CloseReason
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.PostId IN (SELECT PostId FROM TopRankedPosts) 
        AND ph.PostHistoryTypeId IN (10, 11) 
)
SELECT 
    trp.PostId,
    trp.Title,
    trp.CreationDate,
    trp.Score,
    trp.ViewCount,
    trp.CommentCount,
    trp.Tags,
    ARRAY_AGG(DISTINCT phi.UserDisplayName || ' - ' || phi.ChangeType || ' on ' || CAST(phi.ChangeDate AS DATE) || COALESCE(' (Reason: ' || phi.CloseReason || ')', '')) AS History
FROM 
    TopRankedPosts trp
LEFT JOIN 
    PostHistoryInfo phi ON trp.PostId = phi.PostId
GROUP BY 
    trp.PostId, trp.Title, trp.CreationDate, trp.Score, trp.ViewCount, trp.CommentCount, trp.Tags
ORDER BY 
    trp.Score DESC, trp.ViewCount DESC;
