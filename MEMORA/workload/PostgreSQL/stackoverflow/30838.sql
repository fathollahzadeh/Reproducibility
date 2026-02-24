
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        p.OwnerUserId
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  
),
UsersWithBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadge,
        MAX(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadge,
        MAX(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadge
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.OwnerDisplayName,
    ub.BadgeCount,
    ub.GoldBadge,
    ub.SilverBadge,
    ub.BronzeBadge,
    ps.CommentCount,
    ps.UpVotes,
    ps.DownVotes,
    COALESCE(ps.UpVotes, 0) AS TotalUpVotes,
    COALESCE(ps.DownVotes, 0) AS TotalDownVotes
FROM 
    RankedPosts rp
LEFT JOIN 
    UsersWithBadges ub ON rp.OwnerUserId = ub.UserId
LEFT JOIN 
    PostStats ps ON rp.PostId = ps.PostId
WHERE 
    rp.Rank <= 5  
ORDER BY 
    rp.CreationDate DESC;
