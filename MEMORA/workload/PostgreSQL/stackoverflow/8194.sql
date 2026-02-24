
WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        TotalComments,
        TotalUpvotes,
        TotalDownvotes,
        RANK() OVER (ORDER BY Reputation DESC, TotalPosts DESC) AS UserRank
    FROM 
        UserStatistics
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS PostUpvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS PostDownvotes,
        COALESCE(SUM(CASE WHEN c.Id IS NOT NULL THEN 1 END), 0) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        PostUpvotes,
        PostDownvotes,
        CommentCount,
        RANK() OVER (ORDER BY PostUpvotes DESC) AS PostRank
    FROM 
        PostStatistics
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tp.Title AS TopPostTitle,
    tp.PostUpvotes,
    tp.PostDownvotes,
    tp.CommentCount
FROM 
    TopUsers tu
JOIN 
    TopPosts tp ON tu.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)
WHERE 
    tu.UserRank <= 10 AND tp.PostRank <= 10
ORDER BY 
    tu.Reputation DESC, tp.PostUpvotes DESC;
