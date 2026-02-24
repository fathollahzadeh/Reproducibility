
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        U.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.OwnerUserId, U.DisplayName
),
BadgedUsers AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount,
        MAX(Date) AS LastBadgeDate
    FROM 
        Badges
    GROUP BY 
        UserId
),
TopBadgedUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        b.BadgeCount,
        b.LastBadgeDate,
        RANK() OVER (ORDER BY b.BadgeCount DESC) AS BadgeRank
    FROM 
        Users u
    JOIN 
        BadgedUsers b ON u.Id = b.UserId
    WHERE 
        b.BadgeCount > 5  
),
PostHistoryRecent AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserId,
        ph.PostHistoryTypeId,
        PHT.Name AS PostHistoryTypeName,
        DENSE_RANK() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS RecentActivity
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes PHT ON ph.PostHistoryTypeId = PHT.Id
    WHERE 
        ph.CreationDate >= CURRENT_DATE - INTERVAL '6 month'
)
SELECT 
    rp.PostID,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.OwnerDisplayName,
    rp.CommentCount,
    tbu.DisplayName AS TopBadgeUser,
    tbu.BadgeCount,
    ph.UserId AS RecentActivityUserId,
    ph.PostHistoryTypeName,
    ph.CreationDate AS ActivityDate
FROM 
    RankedPosts rp
LEFT JOIN 
    TopBadgedUsers tbu ON rp.OwnerUserId = tbu.Id
LEFT JOIN 
    PostHistoryRecent ph ON rp.PostID = ph.PostId AND ph.RecentActivity = 1
WHERE 
    rp.ScoreRank = 1  
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC;
