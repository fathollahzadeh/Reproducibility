
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AcceptedAnswerId,
        p.CreationDate,
        p.LastActivityDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS RankScore,
        COUNT(*) OVER (PARTITION BY t.TaggedName) AS TagCount
    FROM 
        Posts p
    CROSS JOIN 
        LATERAL (SELECT unnest(string_to_array(Tags, '>')) AS TaggedName) AS t
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ' ORDER BY b.Class) AS BadgeNames,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostCloseReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS CloseReasonNames
    FROM 
        PostHistory ph
    LEFT JOIN 
        CloseReasonTypes cr ON cr.Id = CAST(ph.Comment AS INT)
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId
)
SELECT 
    up.DisplayName,
    up.Reputation,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    ub.BadgeNames,
    pcr.CloseReasonNames,
    CASE 
        WHEN rp.RankScore <= 5 THEN 'Top Posts'
        WHEN rp.TagCount > 10 THEN 'Popular Tags'
        ELSE 'Other'
    END AS PostCategory
FROM 
    Users up
JOIN 
    Posts p ON p.OwnerUserId = up.Id
JOIN 
    RankedPosts rp ON rp.PostId = p.Id
LEFT JOIN 
    UserBadges ub ON ub.UserId = up.Id
LEFT JOIN 
    PostCloseReasons pcr ON pcr.PostId = rp.PostId
WHERE 
    up.Reputation > (SELECT AVG(Reputation) FROM Users) 
    AND (p.Score IS NOT NULL OR p.ViewCount IS NOT NULL) 
    AND (p.LastActivityDate IS NULL OR p.LastActivityDate > p.CreationDate)
ORDER BY 
    up.Reputation DESC, rp.Score DESC
LIMIT 100;
