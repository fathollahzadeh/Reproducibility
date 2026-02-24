WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        SUM(COALESCE(b.Class, 0)) AS TotalBadgeClass,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.UserId = u.Id
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
TopUsers AS (
    SELECT 
        u.UserId, 
        u.DisplayName, 
        u.TotalPosts,
        u.TotalComments,
        u.TotalUpVotes,
        u.TotalDownVotes,
        RANK() OVER (ORDER BY u.TotalUpVotes DESC) AS UserRank
    FROM 
        UserActivity u
    WHERE 
        u.TotalPosts > 0
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.TotalUpVotes,
    ps.Title AS MostCommentedPost,
    ps.CommentCount
FROM 
    TopUsers tu
JOIN 
    PostStats ps ON tu.UserId = ps.PostId
WHERE 
    tu.UserRank <= 10
ORDER BY 
    tu.UserRank, ps.CommentCount DESC;
