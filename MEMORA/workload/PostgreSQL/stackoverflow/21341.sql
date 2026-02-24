
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        SUM(v.BountyAmount) AS TotalBounty,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT ba.Id) AS BadgeCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagList
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges ba ON p.OwnerUserId = ba.UserId
    LEFT JOIN 
        LATERAL unnest(string_to_array(p.Tags, ',')) AS tag ON TRUE
    LEFT JOIN 
        Tags t ON TRIM(tag) = t.TagName
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 month' 
        AND p.Score IS NOT NULL
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.PostTypeId
),
PostsWithCloseReasons AS (
    SELECT 
        p.Id AS PostId,
        ph.Comment AS CloseReason,
        ph.CreationDate AS CloseDate
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10 
),
QualifiedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.Rank,
        rp.TotalBounty,
        rp.CommentCount,
        rp.BadgeCount,
        rp.TagList,
        COALESCE(pc.CloseReason, 'No Closure') AS CloseReason,
        pc.CloseDate
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostsWithCloseReasons pc ON rp.PostId = pc.PostId
    WHERE 
        rp.Rank <= 5
        AND (rp.CommentCount > 0 OR rp.TotalBounty > 0)
)
SELECT 
    qp.PostId,
    qp.Title,
    qp.CreationDate,
    qp.Score,
    qp.ViewCount,
    qp.Rank,
    qp.TotalBounty,
    qp.CommentCount,
    qp.BadgeCount,
    qp.TagList,
    qp.CloseReason,
    COALESCE(EXTRACT(EPOCH FROM TIMESTAMP '2024-10-01 12:34:56' - qp.CloseDate), 0) AS TimeSinceClose
FROM 
    QualifiedPosts qp
ORDER BY 
    qp.Score DESC, qp.ViewCount DESC
LIMIT 10;
