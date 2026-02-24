WITH PostTagCounts AS (
    SELECT
        p.Id AS PostId,
        COUNT(DISTINCT t.Id) AS TagCount
    FROM
        Posts p
    JOIN
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS tag_name ON true
    JOIN
        Tags t ON t.TagName = tag_name
    GROUP BY
        p.Id
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(p.Title, 'No Title') AS Title,
        pt.Name AS PostType,
        u.DisplayName AS Owner,
        p.CreationDate,
        p.ViewCount,
        pc.TagCount
    FROM
        Posts p
    JOIN
        PostTypes pt ON p.PostTypeId = pt.Id
    JOIN
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN
        PostTagCounts pc ON p.Id = pc.PostId
    WHERE
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopPostStats AS (
    SELECT
        PostId,
        Title,
        PostType,
        Owner,
        CreationDate,
        ViewCount,
        ROW_NUMBER() OVER (ORDER BY ViewCount DESC) AS Rank
    FROM
        PostDetails
)

SELECT
    tp.PostId,
    tp.Title,
    tp.PostType,
    tp.Owner,
    tp.CreationDate,
    tp.ViewCount,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = tp.PostId) AS CommentCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = tp.PostId AND v.VoteTypeId = 2) AS UpVoteCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = tp.PostId AND v.VoteTypeId = 3) AS DownVoteCount
FROM
    TopPostStats tp
WHERE
    tp.Rank <= 10
ORDER BY
    tp.Rank;