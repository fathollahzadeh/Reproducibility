
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COUNT(c.Id) FILTER (WHERE c.Id IS NOT NULL) OVER (PARTITION BY p.OwnerUserId) AS CommentCount,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId IN (1, 2)  
        AND p.Score IS NOT NULL
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12, 13)  
),
ActiveUserMetrics AS (
    SELECT 
        u.Id AS UserId,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
)
SELECT 
    u.DisplayName AS UserName,
    u.Reputation,
    ub.BadgeCount,
    ub.BadgeNames,
    rp.PostId,
    rp.Title AS PostTitle,
    rp.Score,
    rp.ViewCount,
    rp.CreationDate,
    rp.CommentCount,
    ph.PostHistoryTypeId,
    ph.Comment AS HistoryComment,
    aum.TotalBounties,
    aum.TotalViews
FROM 
    Users u
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId
LEFT JOIN 
    PostHistoryDetails ph ON rp.PostId = ph.PostId AND ph.HistoryRank = 1  
LEFT JOIN 
    ActiveUserMetrics aum ON u.Id = aum.UserId
WHERE 
    rp.PostRank <= 5  
    AND (ph.PostHistoryTypeId IS NOT NULL OR rp.ViewCount > 100)  
ORDER BY 
    u.Reputation DESC, 
    rp.ViewCount DESC;
