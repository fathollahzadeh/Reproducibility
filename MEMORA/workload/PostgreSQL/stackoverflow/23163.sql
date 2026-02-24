
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS PopularityRank,
        COUNT(DISTINCT v.Id) AS VoteCount,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM
        Posts AS p
    LEFT JOIN
        Votes AS v ON p.Id = v.PostId AND v.VoteTypeId = 2 
    LEFT JOIN
        Comments AS c ON p.Id = c.PostId
    LEFT JOIN
        UNNEST(string_to_array(substring(p.Tags, 2, LENGTH(p.Tags) - 2), '> <')) AS t (TagName) ON TRUE
    WHERE
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY
        p.Id, p.Title, p.ViewCount, p.CreationDate, p.PostTypeId
),
FilteredPosts AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Tags,
        rp.PopularityRank,
        rp.VoteCount,
        rp.CommentCount
    FROM
        RankedPosts AS rp
    WHERE
        rp.PopularityRank <= 5
),
PostActivity AS (
    SELECT
        ph.PostId,
        ph.PostHistoryTypeId,
        MIN(ph.CreationDate) AS FirstActivityDate,
        MAX(ph.CreationDate) AS LastActivityDate
    FROM
        PostHistory AS ph
    GROUP BY
        ph.PostId, ph.PostHistoryTypeId
),
PostStats AS (
    SELECT
        fp.PostId,
        fp.Title,
        fp.ViewCount,
        fp.Tags,
        fp.VoteCount,
        fp.CommentCount,
        pa.FirstActivityDate,
        pa.LastActivityDate,
        EXTRACT(EPOCH FROM (pa.LastActivityDate - pa.FirstActivityDate)) AS ActivityDuration
    FROM
        FilteredPosts AS fp
    LEFT JOIN
        PostActivity AS pa ON fp.PostId = pa.PostId
)
SELECT
    ps.*,
    CASE
        WHEN ps.ViewCount IS NULL THEN 'No Views'
        ELSE CONCAT('View Count: ', ps.ViewCount)
    END AS ViewCountReport,
    CASE
        WHEN ps.CommentCount = 0 THEN 'No Comments'
        ELSE ps.CommentCount::TEXT
    END AS CommentActivityReport,
    COALESCE(ps.Tags, 'No Tags') AS TagsSummary,
    CASE
        WHEN ps.VoteCount > 10 THEN 'Highly Voted'
        WHEN ps.VoteCount IS NULL THEN 'No Votes'
        ELSE 'Moderately Voted'
    END AS VoteStatus,
    CASE
        WHEN ps.ActivityDuration IS NULL THEN 'No Activity'
        WHEN ps.ActivityDuration < 3600 THEN 'Active (<1 hour)'
        WHEN ps.ActivityDuration < 86400 THEN 'Recently Active (<24 hours)'
        ELSE 'Stale'
    END AS ActivityStatus
FROM
    PostStats AS ps
WHERE
    EXISTS (
        SELECT 1
        FROM Users AS u
        WHERE u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = ps.PostId) 
          AND u.Reputation > 500 
    )
ORDER BY
    ps.VoteCount DESC,
    ps.ViewCount DESC;
