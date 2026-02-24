
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM
        Posts p
    WHERE
        p.PostTypeId = 1 
        AND p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
),
PostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        COALESCE(a.Score, 0) AS AcceptedAnswerScore,
        COUNT(c.Id) AS CommentCount,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpvoteCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownvoteCount
    FROM
        RankedPosts rp
    LEFT JOIN
        Posts a ON rp.AcceptedAnswerId = a.Id
    LEFT JOIN
        Comments c ON rp.PostId = c.PostId
    LEFT JOIN
        Votes v ON rp.PostId = v.PostId
    WHERE
        rp.PostRank = 1
    GROUP BY
        rp.PostId, rp.Title, rp.ViewCount, a.Score
),
TopPostStats AS (
    SELECT
        ps.PostId,
        ps.Title,
        ps.ViewCount,
        ps.AcceptedAnswerScore,
        ps.CommentCount,
        ps.UpvoteCount,
        ps.DownvoteCount,
        (ps.UpvoteCount - ps.DownvoteCount) AS Score
    FROM
        PostStats ps
    ORDER BY
        Score DESC
    LIMIT 10
)
SELECT
    ps.Title,
    ps.ViewCount,
    ps.AcceptedAnswerScore,
    ps.CommentCount,
    ps.UpvoteCount,
    ps.DownvoteCount,
    CASE 
        WHEN ps.AcceptedAnswerScore IS NOT NULL THEN 'Has Accepted Answer'
        ELSE 'No Accepted Answer'
    END AS AnswerStatus,
    CASE 
        WHEN ps.ViewCount IS NULL THEN 'No Views'
        ELSE 'Views Recorded'
    END AS ViewStatus
FROM
    TopPostStats ps
FULL OUTER JOIN
    Tags t ON ps.Title LIKE '%' || t.TagName || '%'
WHERE
    t.IsModeratorOnly IS NULL
    OR t.Count > 0
ORDER BY
    ps.ViewCount DESC NULLS LAST;
