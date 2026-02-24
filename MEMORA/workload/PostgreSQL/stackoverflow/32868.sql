
WITH RecursiveTopPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RN
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
        AND p.Score IS NOT NULL
), 
UserBadges AS (
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
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount
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
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COALESCE(rb.Rank, 'N/A') AS Rank,
    ub.BadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    tp.Title AS TopPostTitle,
    tp.Score AS TopPostScore,
    ps.CommentCount,
    ps.VoteCount
FROM 
    Users u
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN (
    SELECT 
        Id,
        OwnerUserId,
        CASE 
            WHEN RN <= 3 THEN 'Top 3'
            ELSE 'Others'
        END AS Rank
    FROM 
        RecursiveTopPosts
) rb ON u.Id = rb.OwnerUserId
LEFT JOIN 
    RecursiveTopPosts tp ON u.Id = tp.OwnerUserId AND tp.RN = 1  
LEFT JOIN 
    PostStats ps ON tp.Id = ps.PostId
WHERE 
    u.Reputation >= 100  
ORDER BY 
    u.Reputation DESC, 
    TopPostScore DESC;
