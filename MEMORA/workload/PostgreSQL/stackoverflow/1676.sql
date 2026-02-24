WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        DENSE_RANK() OVER (PARTITION BY EXTRACT(YEAR FROM p.CreationDate) ORDER BY p.Score DESC) AS ScoreRank
    FROM
        Posts p
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    WHERE
        p.PostTypeId = 1 AND 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY
        p.Id, p.Title, p.CreationDate, p.Score
),
PostVoteCounts AS (
    SELECT
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM
        Votes v
    GROUP BY
        v.PostId
),
PostHistoryAggregated AS (
    SELECT
        ph.PostId,
        ARRAY_AGG(DISTINCT pt.Name) AS HistoryTypeNames
    FROM
        PostHistory ph
    JOIN
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE
        ph.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY
        ph.PostId
)
SELECT
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rpc.UpVotes,
    rpc.DownVotes,
    php.HistoryTypeNames,
    rp.CommentCount,
    CASE 
        WHEN rp.ScoreRank = 1 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostCategory
FROM
    RankedPosts rp
LEFT JOIN
    PostVoteCounts rpc ON rp.PostId = rpc.PostId
LEFT JOIN
    PostHistoryAggregated php ON rp.PostId = php.PostId
WHERE
    php.HistoryTypeNames IS NOT NULL
ORDER BY
    rp.Score DESC, rp.CreationDate DESC;