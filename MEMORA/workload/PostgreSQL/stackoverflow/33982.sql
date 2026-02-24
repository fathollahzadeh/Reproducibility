WITH RECURSIVE UserReputation AS (
    SELECT 
        Id,
        Reputation,
        CreationDate
    FROM 
        Users
    WHERE 
        Reputation > 0
    
    UNION ALL
    
    SELECT 
        u.Id,
        u.Reputation,
        u.CreationDate
    FROM 
        Users u
    INNER JOIN 
        UserReputation ur ON u.Id = ur.Id
    WHERE 
        ur.Reputation < u.Reputation
), 
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
TopUsers AS (
    SELECT 
        u.Id, 
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(pm.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostMetrics pm ON p.Id = pm.PostId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
)
SELECT 
    tu.DisplayName,
    tu.BadgeCount,
    tu.TotalScore,
    pm.PostId,
    pm.Title,
    pm.ViewCount,
    pm.CommentCount,
    pm.UpVotes,
    pm.DownVotes,
    RANK() OVER (PARTITION BY pm.PostId ORDER BY pm.ViewCount DESC) AS ViewRank
FROM 
    TopUsers tu
JOIN 
    PostMetrics pm ON tu.Id = pm.PostId
ORDER BY 
    tu.TotalScore DESC, tu.BadgeCount DESC;