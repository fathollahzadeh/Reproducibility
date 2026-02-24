
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
        MAX(v.VoteTypeId) OVER (PARTITION BY p.Id) AS MaxVoteType
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId 
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
FilteredPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        CASE 
            WHEN rp.MaxVoteType IS NULL THEN 'No Votes' 
            ELSE 'Has Votes' 
        END AS VoteStatus
    FROM 
        RankedPosts rp
    WHERE 
        rp.Score > 10 AND rp.UserPostRank <= 5
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.Reputation, u.DisplayName
)
SELECT 
    fs.Title,
    fs.Score,
    fs.ViewCount,
    us.DisplayName,
    us.Reputation,
    us.TotalPosts,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    fs.VoteStatus
FROM 
    FilteredPosts fs
JOIN 
    UserStatistics us ON fs.Id = us.UserId
ORDER BY 
    fs.Score DESC, us.Reputation DESC
LIMIT 100;
