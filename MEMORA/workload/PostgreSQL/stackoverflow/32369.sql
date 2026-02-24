
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COALESCE(SUBSTRING(p.Body, 1, 100), '[No Content]') AS ShortBody,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount
    FROM
        Posts p
    WHERE
        p.CreationDate >= CURRENT_DATE - INTERVAL '6 months'
),
PopularPosts AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.ViewCount,
        rp.ShortBody,
        rp.CommentCount
    FROM
        RankedPosts rp
    WHERE
        rp.Rank <= 5
),
PostEngagements AS (
    SELECT
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        SUM(CASE WHEN v.VoteTypeId = 6 THEN 1 ELSE 0 END) AS CloseVotes
    FROM
        Posts p
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    GROUP BY
        p.Id
)
SELECT
    pp.PostId,
    pp.Title,
    pp.Score,
    pp.CreationDate,
    pp.ViewCount,
    pp.ShortBody,
    pp.CommentCount,
    COALESCE(pe.Upvotes, 0) AS Upvotes,
    COALESCE(pe.Downvotes, 0) AS Downvotes,
    COALESCE(pe.CloseVotes, 0) AS CloseVotes,
    CASE
        WHEN COALESCE(pe.Upvotes, 0) > COALESCE(pe.Downvotes, 0) THEN 'Positive'
        WHEN COALESCE(pe.Upvotes, 0) < COALESCE(pe.Downvotes, 0) THEN 'Negative'
        ELSE 'Neutral'
    END AS EngagementStatus,
    COALESCE(pht.Name, 'No History') AS PostHistoryType
FROM
    PopularPosts pp
LEFT JOIN
    PostEngagements pe ON pp.PostId = pe.PostId
LEFT JOIN
    PostHistory ph ON pp.PostId = ph.PostId
LEFT JOIN
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
WHERE
    pp.ViewCount > 100
ORDER BY
    pp.Score DESC, pp.CreationDate DESC;
