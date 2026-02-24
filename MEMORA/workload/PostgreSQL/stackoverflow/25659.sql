
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        ARRAY_LENGTH(string_to_array(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), '><'), 1) AS TagCount,
        COALESCE(COUNT(c.Id), 0) AS CommentCount
    FROM
        Posts AS p
    LEFT JOIN
        Comments AS c ON p.Id = c.PostId
    WHERE
        p.CreationDate >= '2024-10-01 12:34:56'::timestamp - INTERVAL '1 year'
    GROUP BY
        p.Id, p.Title, p.Body
),
PostTypeStatistics AS (
    SELECT
        pt.Name AS PostType,
        AVG(rp.CommentCount) AS AvgComments,
        AVG(rp.TagCount) AS AvgTags
    FROM
        RankedPosts AS rp
    JOIN
        PostTypes AS pt ON rp.PostId IN (
            SELECT Id FROM Posts WHERE PostTypeId = pt.Id
        )
    GROUP BY
        pt.Name
),
MostActiveUsers AS (
    SELECT
        u.DisplayName,
        COUNT(p.Id) AS PostCount
    FROM
        Users AS u
    JOIN
        Posts AS p ON u.Id = p.OwnerUserId
    GROUP BY
        u.DisplayName
    ORDER BY
        PostCount DESC
    LIMIT 10
)
SELECT
    pts.PostType,
    pts.AvgComments,
    pts.AvgTags,
    mau.DisplayName AS MostActiveUser
FROM
    PostTypeStatistics AS pts
CROSS JOIN
    MostActiveUsers AS mau
ORDER BY
    pts.PostType;
