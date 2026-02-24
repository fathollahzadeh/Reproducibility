
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p 
    WHERE 
        p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        SUM(u.UpVotes) - SUM(u.DownVotes) AS NetVotes
    FROM 
        Users u 
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT p.Id) > 10
),
UserBadges AS (
    SELECT 
        ub.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges ub 
    JOIN 
        Users u ON ub.UserId = u.Id
    JOIN 
        (SELECT Id, Name FROM PostHistoryTypes WHERE Class = 1) b ON ub.Name = b.Name
    GROUP BY 
        ub.UserId
)
SELECT 
    tu.DisplayName,
    tu.PostCount,
    tu.TotalBounty,
    tu.NetVotes,
    rb.PostId,
    rb.Title,
    rb.CreationDate,
    rb.ViewCount,
    rb.Score,
    COALESCE(ub.BadgeNames, 'No Badges') AS Badges
FROM 
    TopUsers tu
LEFT JOIN 
    RankedPosts rb ON tu.UserId = rb.PostId
LEFT JOIN 
    UserBadges ub ON tu.UserId = ub.UserId
WHERE 
    rb.PostRank = 1
ORDER BY 
    tu.TotalBounty DESC, tu.NetVotes DESC
LIMIT 10;
