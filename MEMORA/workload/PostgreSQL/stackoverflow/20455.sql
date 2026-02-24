WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        COUNT(DISTINCT c.Id) AS CommentsMade,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBountyEarned
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    GROUP BY 
        u.Id
),
PostsWithBadges AS (
    SELECT 
        p.Id,
        p.Title,
        b.Class AS BadgeClass,
        b.Name AS BadgeName
    FROM 
        Posts p
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId 
    WHERE 
        b.Class < 3  
),
PostHistoryDetail AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate AS HistoryCreationDate,
        ph.Comment AS CloseReason,
        COUNT(*) OVER (PARTITION BY ph.PostId) AS HistoryCount,
        STRING_AGG(ph.Text, '; ') AS HistoricalTexts
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12) 
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId, ph.CreationDate, ph.Comment
)
SELECT 
    p.Title AS PostTitle,
    u.DisplayName AS OwnerDisplayName,
    rb.BadgeName,
    ue.PostsCreated,
    ue.CommentsMade,
    ue.TotalBountyEarned,
    p.Score,
    p.ViewCount,
    COUNT(DISTINCT c.Id) AS CommentCount,
    ph.HistoryCount,
    ph.HistoricalTexts
FROM 
    RankedPosts rp
JOIN 
    Posts p ON rp.Id = p.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    PostsWithBadges rb ON p.Id = rb.Id
LEFT JOIN 
    UserEngagement ue ON u.Id = ue.UserId
LEFT JOIN 
    Comments c ON c.PostId = p.Id
LEFT JOIN 
    PostHistoryDetail ph ON p.Id = ph.PostId
WHERE 
    (p.PostTypeId = 1 OR p.PostTypeId = 2) 
    AND (p.Score IS NOT NULL OR p.ViewCount > 100)
    AND (p.CreationDate IS NOT NULL OR p.LastEditDate IS NOT NULL)
GROUP BY 
    p.Title, u.DisplayName, rb.BadgeName, ue.PostsCreated, ue.CommentsMade, 
    ue.TotalBountyEarned, p.Score, p.ViewCount, ph.HistoryCount, ph.HistoricalTexts
ORDER BY 
    ue.CommentsMade DESC, ue.TotalBountyEarned DESC, p.Score DESC
LIMIT 100;