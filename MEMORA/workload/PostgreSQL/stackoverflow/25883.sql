WITH TagCounts AS (
    SELECT
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM
        Tags t
    LEFT JOIN
        Posts p ON p.Tags ILIKE '%' || t.TagName || '%'
    GROUP BY
        t.TagName
),
PopularUsers AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostsCreated,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM
        Users u
    JOIN
        Posts p ON p.OwnerUserId = u.Id
    GROUP BY
        u.Id, u.DisplayName
    ORDER BY
        PostsCreated DESC
    LIMIT 10
),
MostActivePosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS TotalVotes
    FROM
        Posts p
    LEFT JOIN
        Comments c ON c.PostId = p.Id
    LEFT JOIN
        Votes v ON v.PostId = p.Id
    WHERE
        p.ViewCount > 1000
    GROUP BY
        p.Id, p.Title
    ORDER BY
        CommentCount DESC, TotalVotes DESC
    LIMIT 5
)

SELECT
    tc.TagName,
    tc.PostCount,
    pu.DisplayName AS PopularUser,
    pu.PostsCreated,
    pu.TotalScore,
    mp.Title AS ActivePostTitle,
    mp.CommentCount,
    mp.TotalVotes
FROM
    TagCounts tc
CROSS JOIN
    PopularUsers pu
CROSS JOIN
    MostActivePosts mp
ORDER BY
    tc.PostCount DESC,
    pu.PostsCreated DESC,
    mp.CommentCount DESC;
