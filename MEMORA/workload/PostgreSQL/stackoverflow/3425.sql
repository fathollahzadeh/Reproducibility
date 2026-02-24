
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName,
        TotalBounty,
        UpVotes,
        DownVotes,
        PostCount,
        CommentCount,
        RANK() OVER (ORDER BY TotalBounty DESC) AS Rank
    FROM 
        UserActivity
),
MostCommentedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS TotalComments,
        DENSE_RANK() OVER (ORDER BY COUNT(c.Id) DESC) AS CommentRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    GROUP BY 
        p.Id, p.Title, p.CreationDate
)
SELECT 
    tu.Rank,
    tu.DisplayName,
    tu.TotalBounty,
    tu.UpVotes,
    tu.DownVotes,
    tu.PostCount,
    tu.CommentCount,
    mcp.PostId,
    mcp.Title AS MostCommentedPostTitle,
    mcp.TotalComments
FROM 
    TopUsers tu
LEFT JOIN 
    MostCommentedPosts mcp ON tu.UserId IN (
        SELECT OwnerUserId 
        FROM Posts 
        WHERE Id = mcp.PostId
    )
WHERE 
    tu.Rank <= 10
ORDER BY 
    tu.Rank, mcp.TotalComments DESC;
