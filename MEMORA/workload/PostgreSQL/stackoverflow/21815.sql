WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS RankByViews,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        (SELECT COUNT(*) FROM Comments c WHERE c.UserId = u.Id) AS CommentCount,
        DENSE_RANK() OVER (ORDER BY COALESCE(SUM(v.BountyAmount), 0) DESC) AS EngagementRank
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostHistoryWithReason AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.Comment AS CloseReason,
        ph.PostHistoryTypeId,
        CASE 
            WHEN ph.PostHistoryTypeId IN (10, 11) THEN 'Closure Status Changed'
            ELSE 'Other'
        END AS ActionDescription
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 month'
        AND ph.PostHistoryTypeId IN (10, 11)
)
SELECT 
    up.PostId,
    up.Title,
    up.Score,
    up.ViewCount,
    u.DisplayName AS OwnerName,
    ue.TotalBounty,
    ue.BadgeCount,
    ph.CloseReason,
    ph.ActionDescription
FROM 
    RankedPosts up
JOIN 
    Users u ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = up.PostId)
LEFT JOIN 
    UserEngagement ue ON u.Id = ue.UserId
LEFT JOIN 
    PostHistoryWithReason ph ON up.PostId = ph.PostId
WHERE 
    up.RankByViews <= 5 OR up.RankByScore <= 3
ORDER BY 
    COALESCE(ph.CreationDate, '1970-01-01') DESC,
    ue.TotalBounty DESC;