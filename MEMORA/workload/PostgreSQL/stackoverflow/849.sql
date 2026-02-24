
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS ViewRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
        AND p.PostTypeId = 1
), UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS NetVoteScore,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id, u.DisplayName
), PostVoteDetails AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS TotalVotes,
        AVG(v.BountyAmount) AS AverageBounty
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    up.DisplayName,
    rp.Title,
    rp.ViewCount,
    rp.CreationDate,
    us.NetVoteScore,
    us.BadgeCount,
    pvd.TotalVotes,
    pvd.AverageBounty,
    CASE 
        WHEN pvd.TotalVotes IS NULL THEN 'No Votes'
        WHEN pvd.TotalVotes > 50 THEN 'Highly Voted'
        ELSE 'Moderate Votes'
    END AS VoteCategory
FROM 
    RankedPosts rp
JOIN 
    Users up ON rp.PostId = up.Id
JOIN 
    UserStats us ON up.Id = us.UserId
LEFT JOIN 
    PostVoteDetails pvd ON rp.PostId = pvd.PostId
WHERE 
    rp.ViewRank = 1
ORDER BY 
    us.NetVoteScore DESC, rp.ViewCount DESC;
