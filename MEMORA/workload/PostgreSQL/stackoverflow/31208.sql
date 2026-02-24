
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS OwnerRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
TopPostLinks AS (
    SELECT 
        pl.PostId,
        COUNT(pl.RelatedPostId) AS RelatedCount
    FROM 
        PostLinks pl
    INNER JOIN 
        RankedPosts rp ON pl.PostId = rp.PostId
    GROUP BY 
        pl.PostId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS AwardedBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT cht.Name) AS CloseReasons,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    INNER JOIN 
        PostHistoryTypes cht ON ph.PostHistoryTypeId = cht.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    COALESCE(tpl.RelatedCount, 0) AS RelatedPostCount,
    ub.BadgeCount,
    ub.AwardedBadges,
    COALESCE(phd.CloseReasons, 'No close reasons') AS CloseReasons,
    phd.LastEditDate
FROM 
    RankedPosts rp
LEFT JOIN 
    TopPostLinks tpl ON rp.PostId = tpl.PostId
LEFT JOIN 
    UserBadges ub ON rp.OwnerUserId = ub.UserId
LEFT JOIN 
    PostHistoryDetails phd ON rp.PostId = phd.PostId
WHERE 
    rp.OwnerRank = 1 
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
