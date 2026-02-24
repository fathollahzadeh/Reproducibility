
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        COUNT(c.Id) AS CommentCount,
        COALESCE(MAX(b.Class), 0) AS HighestBadge,
        STRING_AGG(DISTINCT t.TagName, ', ') AS AssociatedTags
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON c.PostId = rp.PostId
    LEFT JOIN 
        Posts p ON p.Id = rp.PostId
    LEFT JOIN 
        Badges b ON b.UserId = p.OwnerUserId
    LEFT JOIN 
        LATERAL (SELECT unnest(string_to_array(p.Tags, '><')) AS TagName) t ON TRUE
    WHERE 
        rp.Rank <= 10
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.ViewCount, rp.Score
),
PostHistoryAggregation AS (
    SELECT 
        ph.PostId,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS CloseReopenCount,
        AVG(CASE WHEN ph.PostHistoryTypeId IN (4, 5) THEN (LENGTH(ph.Text) - LENGTH(REPLACE(ph.Text, ' ', ''))) / NULLIF(LENGTH(ph.Text), 0) ELSE NULL END) AS AverageEditLengthRatio
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
FinalResults AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.ViewCount,
        tp.Score,
        tp.CommentCount,
        tp.HighestBadge,
        tp.AssociatedTags,
        COALESCE(pga.CloseReopenCount, 0) AS CloseReopenCount,
        COALESCE(pga.AverageEditLengthRatio, 0) AS AverageEditLengthRatio
    FROM 
        TopPosts tp
    LEFT JOIN 
        PostHistoryAggregation pga ON tp.PostId = pga.PostId
)
SELECT 
    *,
    CASE 
        WHEN CloseReopenCount > 5 THEN 'Frequent Changes' 
        WHEN AverageEditLengthRatio > 0.5 THEN 'Significant Edits'
        ELSE 'Stable Posts'
    END AS PostCategory,
    CASE 
        WHEN HighestBadge = 1 THEN 'Gold Badge Holder'
        WHEN HighestBadge = 2 THEN 'Silver Badge Holder'
        WHEN HighestBadge = 3 THEN 'Bronze Badge Holder'
        ELSE 'No Badges'
    END AS BadgeStatus
FROM 
    FinalResults
ORDER BY 
    Score DESC, ViewCount DESC;
