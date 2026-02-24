
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(v.BountyAmount) AS TotalBounty,
        AVG(COALESCE(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END, 0)) AS AverageUpVotes,
        AVG(COALESCE(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END, 0)) AS AverageDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        DisplayName,
        TotalPosts,
        TotalComments,
        TotalBounty,
        AverageUpVotes,
        AverageDownVotes,
        RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank,
        RANK() OVER (ORDER BY TotalComments DESC) AS CommentRank
    FROM 
        UserActivity
)
SELECT 
    DisplayName,
    TotalPosts,
    TotalComments,
    TotalBounty,
    AverageUpVotes,
    AverageDownVotes,
    PostRank,
    CommentRank
FROM 
    TopUsers
WHERE 
    PostRank <= 10 OR CommentRank <= 10
ORDER BY 
    TotalPosts DESC, TotalComments DESC;
