
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        SUM(b.Class) AS TotalBadgeClass,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation >= 1000
    GROUP BY 
        u.Id
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS HistoryDate,
        ph.UserDisplayName,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS RowNum
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
)
SELECT 
    up.PostId,
    up.Title,
    up.ViewCount,
    up.CommentCount,
    ur.TotalBadgeClass,
    ur.BadgeCount,
    p_hd.HistoryDate,
    p_hd.UserDisplayName AS HistoryActor,
    p_hd.Comment AS HistoryComment
FROM 
    RankedPosts up
JOIN 
    UserReputation ur ON up.PostId = ur.UserId
LEFT JOIN 
    PostHistoryDetails p_hd ON up.PostId = p_hd.PostId AND p_hd.RowNum = 1
WHERE 
    up.PostRank <= 10
ORDER BY 
    up.Score DESC, up.ViewCount DESC;
