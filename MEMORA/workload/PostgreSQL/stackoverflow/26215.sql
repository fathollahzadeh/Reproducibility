WITH TagCount AS (
    SELECT
        p.Id AS PostId,
        COUNT(DISTINCT t.TagName) AS DistinctTagCount
    FROM
        Posts p
    JOIN
        Tags t ON t.TagName = ANY(string_to_array(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), '><'))
    GROUP BY
        p.Id
),
PostStatistics AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        pc.AvgCommentLength,
        tc.DistinctTagCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVoteCount
    FROM
        Posts p
    JOIN (
        SELECT
            PostId,
            AVG(LENGTH(Text)) AS AvgCommentLength
        FROM
            Comments
        GROUP BY
            PostId
    ) pc ON pc.PostId = p.Id
    JOIN TagCount tc ON tc.PostId = p.Id
    WHERE
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
)
SELECT
    ps.PostId,
    ps.Title,
    ps.ViewCount,
    ps.AvgCommentLength,
    ps.DistinctTagCount,
    ps.UpVoteCount,
    ps.DownVoteCount,
    (ps.UpVoteCount - ps.DownVoteCount) AS NetVoteCount,
    CASE
        WHEN ps.DistinctTagCount > 5 THEN 'Highly Tagged'
        WHEN ps.DistinctTagCount BETWEEN 3 AND 5 THEN 'Moderately Tagged'
        ELSE 'Less Tagged'
    END AS TagCategory
FROM
    PostStatistics ps
ORDER BY
    NetVoteCount DESC,
    ps.ViewCount DESC
LIMIT 50;