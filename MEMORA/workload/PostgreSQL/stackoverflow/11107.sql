
WITH UserStatistics AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT p.AnswerCount) AS TotalAnswers,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(v.BountyAmount) AS TotalBounties,
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
        u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        pt.Name AS PostType,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM
        Posts p
    LEFT JOIN
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    GROUP BY
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, pt.Name
)
SELECT
    us.UserId,
    us.DisplayName,
    us.TotalPosts,
    us.TotalAnswers,
    us.TotalComments,
    us.TotalBounties,
    us.TotalUpvotes,
    us.TotalDownvotes,
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.PostType,
    ps.TotalComments AS PostTotalComments,
    ps.TotalUpvotes AS PostTotalUpvotes,
    ps.TotalDownvotes AS PostTotalDownvotes
FROM
    UserStatistics us
JOIN
    PostStatistics ps ON us.UserId = ps.PostId
ORDER BY
    us.TotalPosts DESC, ps.Score DESC;
