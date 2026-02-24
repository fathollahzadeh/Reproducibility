WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.Score > 0
), UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadge
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
), PostHistoryClosed AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
), CountTags AS (
    SELECT 
        p.Id AS PostId,
        CARDINALITY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.Tags IS NOT NULL
)
SELECT 
    up.DisplayName,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rb.BadgeCount,
    rb.HighestBadge,
    pc.CloseCount,
    pc.LastClosedDate,
    ct.TagCount,
    CASE 
        WHEN pc.CloseCount IS NOT NULL THEN 'Closed'
        ELSE 'Active'
    END AS PostStatus
FROM 
    RankedPosts rp
JOIN 
    Users up ON rp.OwnerUserId = up.Id
LEFT JOIN 
    UserBadges rb ON up.Id = rb.UserId
LEFT JOIN 
    PostHistoryClosed pc ON rp.PostId = pc.PostId
LEFT JOIN 
    CountTags ct ON rp.PostId = ct.PostId
WHERE 
    rb.BadgeCount IS NULL OR rb.BadgeCount > 1
ORDER BY 
    rp.Score DESC,
    rp.CreationDate DESC
FETCH FIRST 100 ROWS ONLY;
