WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),

PostScore AS (
    SELECT 
        p.OwnerUserId,
        SUM(p.Score) AS TotalScore,
        COUNT(p.Id) AS PostCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.OwnerUserId
),

TopContributors AS (
    SELECT 
        ur.UserId,
        ur.DisplayName,
        ur.Reputation,
        ps.TotalScore,
        ps.PostCount,
        ROW_NUMBER() OVER (ORDER BY ur.Reputation DESC, ps.TotalScore DESC) as Rank
    FROM 
        UserReputation ur
    JOIN 
        PostScore ps ON ur.UserId = ps.OwnerUserId
    WHERE 
        ur.Reputation > 1000
)

SELECT 
    tc.Rank,
    tc.DisplayName,
    tc.Reputation,
    tc.TotalScore,
    tc.PostCount,
    COALESCE(b.Name, 'No Badge') AS TopBadge
FROM 
    TopContributors tc
LEFT JOIN 
    (SELECT 
        UserId, 
        Name,
        ROW_NUMBER() OVER (PARTITION BY UserId ORDER BY Class) AS BadgeRank
    FROM 
        Badges) b ON tc.UserId = b.UserId AND b.BadgeRank = 1
WHERE 
    tc.Rank <= 10
ORDER BY 
    tc.Rank;