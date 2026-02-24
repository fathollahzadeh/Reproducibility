
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank,
        u.Reputation AS OwnerReputation,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
        LEFT JOIN Users u ON p.OwnerUserId = u.Id
        LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1' YEAR
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.Reputation
),
RecentActivities AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS EditDate,
        ph.UserDisplayName,
        ph.Comment,
        ph.PostHistoryTypeId,
        CASE 
            WHEN ph.PostHistoryTypeId IN (10, 11) THEN 'Close/Open'
            ELSE 'Edit'
        END AS ActivityType
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '2' MONTH
),
PostLinksSummary AS (
    SELECT 
        pl.PostId,
        COUNT(*) AS RelatedPostCount
    FROM 
        PostLinks pl
    GROUP BY 
        pl.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.OwnerReputation,
    rp.CommentCount,
    COALESCE(pls.RelatedPostCount, 0) AS RelatedPostCount,
    ra.EditDate,
    ra.UserDisplayName,
    ra.Comment,
    ra.ActivityType
FROM 
    RankedPosts rp
    LEFT JOIN PostLinksSummary pls ON rp.PostId = pls.PostId
    LEFT JOIN RecentActivities ra ON rp.PostId = ra.PostId
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC, rp.CreationDate DESC;
