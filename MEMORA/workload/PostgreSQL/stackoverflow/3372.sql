WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) as RankScore,
        COUNT(v.Id) OVER (PARTITION BY p.OwnerUserId) as VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2  
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
        AND p.PostTypeId IN (1, 2)  
),
TopPosts AS (
    SELECT 
        rp.OwnerUserId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.VoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankScore = 1
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    u.DisplayName,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    ub.BadgeCount,
    CASE 
        WHEN ub.BadgeCount IS NULL THEN 'No Badges'
        ELSE 'Has Badges'
    END AS BadgeStatus
FROM 
    Users u
LEFT JOIN 
    TopPosts tp ON u.Id = tp.OwnerUserId
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
WHERE 
    u.Reputation > 1000
ORDER BY 
    tp.Score DESC NULLS LAST;