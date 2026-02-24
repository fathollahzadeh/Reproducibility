
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        p.Tags,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS UpVotes,  
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS DownVotes,  
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank,
        RANK() OVER (ORDER BY p.CreationDate DESC) AS GlobalRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > (TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year')
        AND p.PostTypeId = 1  
),
UserBadges AS (
    SELECT 
        u.Id AS UserId, 
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
UserDetails AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        ub.BadgeCount,
        CASE 
            WHEN u.LastAccessDate < (TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 months') THEN 'Inactive'
            ELSE 'Active'
        END AS Status
    FROM 
        Users u
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
)
SELECT 
    rp.Id AS PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    ud.DisplayName,
    ud.Reputation,
    ud.BadgeCount,
    rp.UpVotes,
    rp.DownVotes,
    ud.Status AS UserStatus,
    rp.GlobalRank,
    CASE 
        WHEN rp.GlobalRank <= 10 THEN 'Top 10% of Posts'
        ELSE 'Below Top 10%'
    END AS PostRanking
FROM 
    RankedPosts rp
JOIN 
    UserDetails ud ON rp.OwnerUserId = ud.Id
WHERE 
    rp.UserRank <= 5 
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC;
