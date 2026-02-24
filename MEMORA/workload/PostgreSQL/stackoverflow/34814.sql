
WITH RECURSIVE PostHierarchy AS (
    SELECT 
        Id,
        ParentId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        1 AS Level
    FROM 
        Posts 
    WHERE 
        ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.Id
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties,
        AVG(COALESCE(c.Score, 0)) AS AvgCommentScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        TotalBounties,
        RANK() OVER (ORDER BY PostCount DESC, TotalBounties DESC) AS Rank
    FROM 
        UserActivity
    WHERE 
        PostCount > 0
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(ph.Id) AS ChildCount,
        COUNT(c.Id) AS CommentCount,
        MAX(p.CreationDate) AS LastCreated
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON ph.PostId = p.Id AND ph.PostHistoryTypeId = 10 
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    GROUP BY 
        p.Id
)
SELECT 
    tu.DisplayName,
    tu.PostCount,
    tu.TotalBounties,
    ch.ChildCount,
    ch.CommentCount,
    ch.LastCreated,
    p.Level AS PostLevel
FROM 
    TopUsers tu
LEFT JOIN 
    ClosedPosts ch ON tu.UserId IN (SELECT OwnerUserId FROM Posts WHERE Id = ch.PostId)
JOIN 
    PostHierarchy p ON p.Id = ch.PostId
WHERE 
    tu.Rank <= 10 
ORDER BY 
    tu.Rank;
