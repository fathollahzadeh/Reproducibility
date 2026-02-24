
WITH UserScores AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(v.BountyAmount) AS TotalBounties,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        AVG(p.Score) AS AveragePostScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        pt.Name AS PostType,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, pt.Name
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.TotalBounties,
        us.TotalUpvotes,
        us.TotalDownvotes,
        us.TotalPosts,
        us.AveragePostScore,
        ROW_NUMBER() OVER (ORDER BY us.TotalUpvotes DESC, us.TotalBounties DESC) AS Rank
    FROM 
        UserScores us
)
SELECT 
    tu.Rank,
    tu.DisplayName,
    tu.TotalPosts,
    tu.TotalUpvotes,
    tu.TotalBounties,
    p.Title AS TopPostTitle,
    p.CreationDate AS PostCreationDate,
    p.ViewCount AS PostViewCount,
    p.TotalComments AS PostTotalComments,
    p.Upvotes AS PostUpvotes,
    p.Downvotes AS PostDownvotes,
    p.PostType AS PostType
FROM 
    TopUsers tu
LEFT JOIN 
    PostStats p ON tu.TotalPosts = (SELECT MAX(TotalPosts) FROM UserScores)
WHERE 
    tu.Rank <= 10
ORDER BY 
    tu.Rank;
