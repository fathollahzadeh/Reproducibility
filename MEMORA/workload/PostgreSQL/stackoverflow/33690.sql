WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostStatistics AS (
    SELECT
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        MAX(p.LastActivityDate) AS LastActivityDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id
),
DeletedPosts AS (
    SELECT 
        p.Id AS PostId,
        ph.CreationDate,
        ph.Comment AS DeleteReason
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 12  
),
ActiveThreadStats AS (
    SELECT 
        r.PostId,
        r.Title,
        r.CreationDate,
        r.Score,
        ps.CommentCount,
        ps.VoteCount,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges,
        r.OwnerUserId,
        CASE 
            WHEN dp.PostId IS NOT NULL THEN 'Deleted'
            ELSE 'Active'
        END AS Status
    FROM 
        RankedPosts r
    LEFT JOIN 
        PostStatistics ps ON r.PostId = ps.PostId
    LEFT JOIN 
        UserBadges ub ON r.OwnerUserId = ub.UserId
    LEFT JOIN 
        DeletedPosts dp ON r.PostId = dp.PostId
    WHERE 
        r.Rank = 1  
)
SELECT 
    a.PostId,
    a.Title,
    a.CreationDate,
    a.Score,
    a.CommentCount,
    a.VoteCount,
    a.GoldBadges,
    a.SilverBadges,
    a.BronzeBadges,
    CASE 
        WHEN a.Status = 'Deleted' THEN 'This post has been deleted'
        ELSE 'This post is active'
    END AS PostStatus
FROM 
    ActiveThreadStats a
ORDER BY 
    a.Score DESC, 
    a.CreationDate ASC;