
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
RecentEdits AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS EditDate,
        ph.UserId,
        ph.UserDisplayName,
        ph.Comment,
        ph.Text
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
),
CloseVotes AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
UnionResults AS (
    SELECT 
        p.PostId,
        'Recent Edit' AS Source,
        COUNT(e.EditDate) AS EditCount
    FROM 
        RankedPosts p
    LEFT JOIN 
        RecentEdits e ON p.PostId = e.PostId
    GROUP BY 
        p.PostId

    UNION ALL 

    SELECT 
        p.PostId,
        'Close Votes' AS Source,
        COALESCE(c.CloseCount, 0) AS CloseCount
    FROM 
        RankedPosts p
    LEFT JOIN 
        CloseVotes c ON p.PostId = c.PostId
)

SELECT 
    r.PostId,
    r.Title,
    r.CreationDate,
    r.ViewCount,
    r.Score,
    u.DisplayName AS OwnerDisplayName,
    COALESCE(ub.BadgeCount, 0) AS UserBadgeCount,
    STRING_AGG(DISTINCT ur.Source || ': ' || CAST(ur.EditCount AS TEXT), ', ') AS EditCloseSummary
FROM 
    RankedPosts r
JOIN 
    Users u ON r.OwnerUserId = u.Id
LEFT JOIN 
    UserBadges ub ON ub.UserId = r.OwnerUserId
LEFT JOIN 
    UnionResults ur ON r.PostId = ur.PostId
WHERE 
    r.Rank <= 5 
GROUP BY 
    r.PostId, r.Title, r.CreationDate, r.ViewCount, r.Score, u.DisplayName, ub.BadgeCount
ORDER BY 
    r.Score DESC, r.ViewCount DESC;
