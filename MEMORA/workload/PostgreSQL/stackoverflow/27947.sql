
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS Rank
    FROM
        Posts p
    LEFT JOIN
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    LEFT JOIN
        UNNEST(string_to_array(p.Tags, '>')) AS t(TagName) ON t.TagName IS NOT NULL
    WHERE
        p.PostTypeId = 1 
    GROUP BY
        p.Id, p.Title, p.CreationDate, u.DisplayName
),
PopularTags AS (
    SELECT
        t.TagName AS PopularTag
    FROM
        Posts p
    JOIN
        UNNEST(string_to_array(p.Tags, '>')) AS t(TagName) ON t.TagName IS NOT NULL
    GROUP BY
        t.TagName
    ORDER BY
        COUNT(*) DESC
    LIMIT 10 
),
TagStatistics AS (
    SELECT
        pt.PopularTag,
        COUNT(rp.PostId) AS PostsCount,
        SUM(rp.UpVoteCount) AS TotalUpVotes,
        SUM(rp.DownVoteCount) AS TotalDownVotes,
        AVG(rp.CommentCount) AS AverageComments
    FROM
        PopularTags pt
    LEFT JOIN
        RankedPosts rp ON rp.Tags @> ARRAY[pt.PopularTag]
    GROUP BY
        pt.PopularTag
)
SELECT
    ts.PopularTag,
    ts.PostsCount,
    ts.TotalUpVotes,
    ts.TotalDownVotes,
    ts.AverageComments,
    CONCAT('Tag: ', ts.PopularTag, 
           ' | Total Posts: ', ts.PostsCount, 
           ' | UpVotes: ', ts.TotalUpVotes,
           ' | DownVotes: ', ts.TotalDownVotes,
           ' | Average Comments: ', ROUND(ts.AverageComments, 2)) AS Summary
FROM
    TagStatistics ts
ORDER BY
    ts.PostsCount DESC;
