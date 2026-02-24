
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS UserViewRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
        AND p.PostTypeId = 1 
),

UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COUNT(DISTINCT ph.PostId) AS EditedPostCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBountyAmount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (4, 5) 
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON v.UserId = u.Id AND v.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.Reputation, u.DisplayName
),

PopularPosts AS (
    SELECT
        rp.Id,
        rp.Title,
        rp.ViewCount,
        rp.OwnerUserId,
        us.DisplayName AS OwnerDisplayName,
        us.Reputation AS OwnerReputation,
        COUNT(c.Id) AS CommentCount
    FROM 
        RankedPosts rp
    JOIN 
        Users us ON rp.OwnerUserId = us.Id
    LEFT JOIN 
        Comments c ON c.PostId = rp.Id
    WHERE 
        rp.UserViewRank <= 3 
    GROUP BY 
        rp.Id, rp.Title, rp.ViewCount, rp.OwnerUserId, us.DisplayName, us.Reputation
)

SELECT 
    pp.Id,
    pp.Title,
    pp.ViewCount,
    pp.OwnerDisplayName,
    pp.OwnerReputation,
    us.EditedPostCount,
    us.GoldBadges,
    us.TotalBountyAmount,
    pp.CommentCount,
    CASE 
        WHEN pp.ViewCount IS NULL THEN 'No views'
        WHEN pp.ViewCount < 100 THEN 'Low view count'
        WHEN pp.ViewCount BETWEEN 100 AND 500 THEN 'Moderate view count'
        ELSE 'High view count'
    END AS ViewCountCategory
FROM 
    PopularPosts pp
JOIN 
    UserStats us ON pp.OwnerUserId = us.UserId
ORDER BY 
    pp.OwnerReputation DESC, pp.ViewCount DESC;
