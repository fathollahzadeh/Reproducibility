WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
), UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(MAX(ps.UpVotes) - MAX(ps.DownVotes), 0) AS VoteNet,
        COUNT(DISTINCT ps.PostId) AS TotalPosts
    FROM 
        Users u
    LEFT JOIN 
        PostStats ps ON u.Id = ps.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation
), PopularUsers AS (
    SELECT 
        UserId,
        Reputation,
        VoteNet,
        TotalPosts,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserReputation
    WHERE 
        TotalPosts > 0
)
SELECT 
    pu.UserId,
    u.DisplayName,
    pu.Reputation,
    pu.VoteNet,
    pu.TotalPosts,
    pu.ReputationRank,
    ARRAY_AGG(ps.Title) AS RecentPosts
FROM 
    PopularUsers pu
JOIN 
    Users u ON pu.UserId = u.Id
LEFT JOIN 
    PostStats ps ON pu.UserId = ps.OwnerUserId
GROUP BY 
    pu.UserId, u.DisplayName, pu.Reputation, pu.VoteNet, pu.TotalPosts, pu.ReputationRank
HAVING 
    COUNT(ps.PostId) > 5
ORDER BY 
    pu.ReputationRank
LIMIT 10;