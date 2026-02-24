WITH PostStats AS (
    SELECT
        pt.Name AS PostType,
        COUNT(DISTINCT p.Id) AS PostCount,
        AVG(p.Score) AS AvgScore,
        COUNT(c.Id) AS CommentCount
    FROM
        Posts p
    LEFT JOIN
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    GROUP BY
        pt.Name
),

TopPosts AS (
    SELECT
        p.Id,
        p.Title,
        p.ViewCount,
        pt.Name AS PostType
    FROM
        Posts p
    JOIN
        PostTypes pt ON p.PostTypeId = pt.Id
    ORDER BY
        p.ViewCount DESC
    LIMIT 5
)

SELECT
    ps.PostType,
    ps.PostCount,
    ps.AvgScore,
    ps.CommentCount,
    tp.Title AS TopPostTitle,
    tp.ViewCount AS TopPostViewCount
FROM
    PostStats ps
LEFT JOIN
    TopPosts tp ON ps.PostType = tp.PostType;