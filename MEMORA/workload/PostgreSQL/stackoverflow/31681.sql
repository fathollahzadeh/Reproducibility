WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.PostTypeId, p.Title, p.CreationDate, p.OwnerUserId, p.Score
),

UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        AVG(u.Reputation) OVER () AS AvgReputation
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id, u.DisplayName
),

TopUsers AS (
    SELECT 
        ub.UserId,
        ub.DisplayName,
        ub.BadgeCount,
        RANK() OVER (ORDER BY ub.BadgeCount DESC) AS UserRank
    FROM 
        UserBadges ub
    WHERE 
        ub.BadgeCount > 0
),

MostActivePosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        COUNT(c.Id) AS CommentCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON rp.PostId = c.PostId
    WHERE 
        rp.Rank <= 10
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.Score
)

SELECT 
    u.DisplayName,
    u.AvgReputation,
    tu.UserRank,
    mp.Title AS ActivePostTitle,
    mp.Score AS PostScore,
    mp.CommentCount
FROM 
    MostActivePosts mp
JOIN 
    UserBadges u ON mp.PostId = u.UserId  
JOIN 
    TopUsers tu ON u.UserId = tu.UserId
WHERE 
    u.BadgeCount > 1
ORDER BY 
    mp.CommentCount DESC, u.BadgeCount DESC
LIMIT 20;