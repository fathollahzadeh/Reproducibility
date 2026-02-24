
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        ARRAY_AGG(t.TagName) AS TagsArray 
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON t.ExcerptPostId = p.Id
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId, 
        MAX(ph.CreationDate) AS LastClosed 
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON ph.PostId = p.Id 
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        p.Id
),
UserBadges AS (
    SELECT 
        u.Id AS UserId, 
        COUNT(b.Id) AS BadgeCount 
    FROM 
        Users u 
    LEFT JOIN 
        Badges b ON u.Id = b.UserId 
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    WHERE 
        u.Reputation > 1000
)

SELECT 
    tp.UserId,
    tp.DisplayName,
    tp.Reputation,
    tp.BadgeCount,
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.Rank,
    cp.LastClosed,
    CASE
        WHEN rp.Rank = 1 THEN 'Top Post'
        WHEN cp.LastClosed IS NOT NULL THEN 'Closed Recently'
        ELSE 'Regular Post'
    END AS PostStatus
FROM 
    TopUsers tp
JOIN 
    RankedPosts rp ON rp.Rank <= 3 AND rp.PostId IN (
        SELECT 
            r.PostId 
        FROM 
            RankedPosts r 
        WHERE 
            r.Rank <= 3 
        ORDER BY 
            r.Score DESC
    )
LEFT JOIN 
    ClosedPosts cp ON cp.PostId = rp.PostId
ORDER BY 
    tp.Reputation DESC, rp.Score DESC
LIMIT 100;
