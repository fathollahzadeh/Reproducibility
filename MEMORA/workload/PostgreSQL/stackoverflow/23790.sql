
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 /* Questions only */
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.OwnerUserId
),

CloseReason AS (
    SELECT 
        ph.PostId,
        STRING_AGG(crt.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes crt ON CAST(ph.Comment AS int) = crt.Id
    WHERE 
        ph.PostHistoryTypeId = 10 /* Post Closed */
    GROUP BY 
        ph.PostId
),

UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        COUNT(DISTINCT ph.PostId) AS PostsModified
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        PostHistory ph ON u.Id = ph.UserId AND ph.PostHistoryTypeId IN (4, 5, 6) /* Updated Title, Body, or Tags */
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)

SELECT 
    up.UserId,
    up.DisplayName,
    up.Reputation,
    up.GoldBadges,
    up.SilverBadges,
    up.BronzeBadges,
    rp.PostId,
    rp.Title,
    rp.Score,
    COALESCE(cr.CloseReasons, 'No Close Reasons') AS CloseReasons,
    rp.CommentCount,
    CASE 
        WHEN rp.UserPostRank = 1 THEN 'Most Recent'
        WHEN rp.UserPostRank > 1 THEN 'Older Posts'
        ELSE 'No Posts Found'
    END AS PostStatus
FROM 
    UserStats up
JOIN 
    RankedPosts rp ON up.UserId = rp.OwnerUserId
LEFT JOIN 
    CloseReason cr ON rp.PostId = cr.PostId
WHERE 
    up.Reputation > 100 AND 
    (up.GoldBadges > 0 OR up.SilverBadges > 0 OR up.BronzeBadges > 0)
ORDER BY 
    up.Reputation DESC, 
    rp.CreationDate DESC;
