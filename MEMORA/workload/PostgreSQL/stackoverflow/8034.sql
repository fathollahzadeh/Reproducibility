WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation, 
        u.CreationDate, 
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(v.BountyAmount) AS TotalBounty,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.CreationDate
),
PostEngagement AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(DISTINCT v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.TotalPosts,
        us.TotalComments,
        us.TotalBounty,
        ROW_NUMBER() OVER (ORDER BY us.Reputation DESC) AS Rank
    FROM 
        UserStatistics us
)
SELECT 
    tu.Rank,
    tu.DisplayName,
    tu.Reputation,
    pe.Title,
    pe.CreationDate,
    pe.Score,
    pe.ViewCount,
    pe.TotalComments,
    pe.Upvotes,
    pe.Downvotes,
    tu.TotalPosts,
    tu.TotalComments AS UserTotalComments,
    tu.TotalBounty
FROM 
    TopUsers tu
JOIN 
    PostEngagement pe ON tu.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = pe.PostId)
WHERE 
    tu.Rank <= 10
ORDER BY 
    tu.Rank, pe.ViewCount DESC;
