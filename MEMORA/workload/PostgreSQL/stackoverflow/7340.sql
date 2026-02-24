
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS NetVotes,
        RANK() OVER (ORDER BY COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) DESC) AS VoteRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
), 
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        TotalPosts, 
        TotalComments, 
        UpVotes, 
        DownVotes, 
        NetVotes 
    FROM 
        UserActivity 
    WHERE 
        VoteRank <= 10
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.TotalComments,
    tu.UpVotes,
    tu.DownVotes,
    tu.NetVotes,
    (SELECT 
        COUNT(*) 
     FROM 
        Posts p 
     WHERE 
        p.OwnerUserId = tu.UserId AND 
        p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 month') AS RecentPosts,
    (SELECT 
        AVG(v.BountyAmount) 
     FROM 
        Votes v 
     JOIN 
        Posts p ON v.PostId = p.Id 
     WHERE 
        p.OwnerUserId = tu.UserId AND 
        v.VoteTypeId = 8) AS AverageBounty
FROM 
    TopUsers tu
ORDER BY 
    tu.NetVotes DESC;
