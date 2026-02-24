
WITH UserStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        AVG(p.Score) AS AvgPostScore
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    GROUP BY
        u.Id, u.DisplayName
)
SELECT
    u.UserId,
    u.DisplayName,
    u.TotalPosts,
    u.TotalComments,
    u.TotalUpVotes,
    u.TotalDownVotes,
    u.AvgPostScore
FROM
    UserStats u
ORDER BY
    u.TotalPosts DESC,
    u.TotalComments DESC;
