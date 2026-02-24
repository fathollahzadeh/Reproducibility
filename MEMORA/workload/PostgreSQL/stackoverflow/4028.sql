WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
), UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    up.DisplayName,
    up.Reputation,
    rp.Title AS RecentPostTitle,
    rp.CreationDate AS PostCreationDate,
    ub.BadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    CASE 
        WHEN rp.CommentCount > 0 THEN 'Has Comments'
        WHEN rp.OwnerRank = 1 THEN 'Latest Post'
        ELSE 'No Comments'
    END AS PostStatus,
    COALESCE(vs.VoteType, 'No Votes') AS VoteStatus
FROM 
    RankedPosts rp
JOIN 
    Users up ON rp.OwnerUserId = up.Id
LEFT JOIN 
    UserBadges ub ON up.Id = ub.UserId
LEFT JOIN (
    SELECT 
        PostId,
        STRING_AGG(CASE 
            WHEN VoteTypeId = 2 THEN 'Upvote'
            WHEN VoteTypeId = 3 THEN 'Downvote'
            ELSE 'Other Vote'
        END, ', ') AS VoteType
    FROM 
        Votes
    GROUP BY 
        PostId
) vs ON rp.Id = vs.PostId
WHERE 
    ub.BadgeCount > 0
ORDER BY 
    up.Reputation DESC, rp.CreationDate DESC
FETCH FIRST 10 ROWS ONLY;