
WITH PostSummary AS (
    SELECT
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        AVG(p.Score) AS AverageScore,
        SUM(CASE WHEN vt.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN vt.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM
        Posts p
    JOIN
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN
        Votes vt ON p.Id = vt.PostId
    GROUP BY
        pt.Name
)

SELECT
    PostType,
    TotalPosts,
    AverageScore,
    TotalUpVotes,
    TotalDownVotes
FROM
    PostSummary
ORDER BY
    TotalPosts DESC;
