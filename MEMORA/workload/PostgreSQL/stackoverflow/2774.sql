WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.AnswerCount,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.Score > 0
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostCloseReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON cr.Id = CAST(ph.Comment AS SMALLINT) 
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId
)
SELECT 
    up.Id AS UserId,
    up.DisplayName,
    up.Reputation,
    rb.PostId,
    rb.Title,
    rb.Score,
    rb.CreationDate,
    rb.AnswerCount,
    cb.BadgeCount,
    cb.HighestBadgeClass,
    pcr.CloseReasons
FROM 
    Users up
LEFT JOIN 
    RankedPosts rb ON up.Id = rb.PostId
LEFT JOIN 
    UserBadges cb ON up.Id = cb.UserId
LEFT JOIN 
    PostCloseReasons pcr ON rb.PostId = pcr.PostId
WHERE 
    up.Reputation > 1000 
    AND (pcr.CloseReasons IS NOT NULL OR cb.BadgeCount > 0)
ORDER BY 
    up.Reputation DESC, rb.Score DESC;