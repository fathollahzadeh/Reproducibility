
WITH PostStats AS (
    SELECT
        pt.Name AS PostType,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes, 
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes, 
        AVG(p.ViewCount) AS AverageViews 
    FROM
        Posts p
    LEFT JOIN
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    GROUP BY
        pt.Name
)

SELECT
    PostType,
    PostCount,
    TotalUpvotes,
    TotalDownvotes,
    AverageViews
FROM
    PostStats
ORDER BY
    PostCount DESC;
