WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.PostTypeId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
RelevantPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerUserId,
        rp.Rank,
        rp.CommentCount,
        rp.Upvotes,
        rp.Downvotes,
        ub.BadgeCount,
        ub.BadgeNames
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserBadges ub ON rp.OwnerUserId = ub.UserId
    WHERE 
        rp.Rank = 1
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    COALESCE(rp.BadgeCount, 0) AS BadgeCount,
    COALESCE(rp.BadgeNames, 'No badges') AS BadgeNames,
    rp.CommentCount,
    rp.Upvotes,
    rp.Downvotes,
    CASE 
        WHEN rp.Upvotes - rp.Downvotes > 0 THEN 'Positive'
        WHEN rp.Upvotes - rp.Downvotes < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS PostSentiment
FROM 
    RelevantPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
WHERE 
    rp.BadgeCount IS NOT NULL
ORDER BY 
    rp.Upvotes DESC, rp.CommentCount DESC;