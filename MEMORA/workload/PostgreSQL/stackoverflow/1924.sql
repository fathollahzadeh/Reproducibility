
WITH UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        RANK() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS PostRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
), 
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalComments,
        TotalUpvotes,
        TotalDownvotes,
        PostRank
    FROM UserEngagement
    WHERE PostRank <= 10
), 
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        p.OwnerUserId
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    GROUP BY p.Id, p.Title, p.ViewCount, p.CreationDate, p.OwnerUserId
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.TotalComments,
    tu.TotalUpvotes,
    tu.TotalDownvotes,
    pd.PostId,
    pd.Title,
    pd.ViewCount,
    pd.CommentCount,
    pd.VoteCount,
    CASE
        WHEN pd.VoteCount > 10 THEN 'Highly Voted'
        WHEN pd.VoteCount BETWEEN 5 AND 10 THEN 'Moderate Interest'
        ELSE 'Low Interest' 
    END AS PostInterestLevel
FROM TopUsers tu
INNER JOIN PostDetails pd ON tu.UserId = pd.OwnerUserId
ORDER BY tu.TotalPosts DESC, pd.ViewCount DESC;
