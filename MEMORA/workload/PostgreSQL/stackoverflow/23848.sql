
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM
        Posts p
    WHERE
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year') AND
        p.Score > 0
),
TopUserVotes AS (
    SELECT
        u.Id AS UserId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM
        Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY
        u.Id
    HAVING
        COUNT(v.Id) > 10
),
PostWithTags AS (
    SELECT
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        UNNEST(NULLIF(STRING_TO_ARRAY(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), '><'), '{}')) AS t(TagName) ON TRUE
    WHERE
        p.PostTypeId = 1 
    GROUP BY
        p.Id
)
SELECT
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.Score,
    COALESCE(pt.Tags, 'No Tags') AS Tags,
    tuv.UserId,
    tuv.VoteCount,
    tuv.UpVotes,
    tuv.DownVotes
FROM
    RankedPosts rp
JOIN
    PostWithTags pt ON rp.PostId = pt.PostId
LEFT JOIN
    TopUserVotes tuv ON tuv.UserId = (SELECT u.Id
                                       FROM Users u
                                       WHERE u.Reputation = (SELECT MAX(Reputation)
                                                             FROM Users
                                                             WHERE LastAccessDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 month'))
                                       LIMIT 1)
WHERE
    rp.Rank <= 3
ORDER BY
    rp.Score DESC,
    rp.ViewCount DESC
FETCH FIRST 10 ROWS ONLY;
