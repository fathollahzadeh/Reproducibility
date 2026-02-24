WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore
    FROM
        Posts p
    JOIN
        Users u ON p.OwnerUserId = u.Id
    WHERE
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
        AND p.PostTypeId = 1 
),
TopRankedPosts AS (
    SELECT
        PostId,
        Title,
        Score,
        ViewCount,
        OwnerDisplayName
    FROM
        RankedPosts
    WHERE
        RankByScore <= 5
),
PostVoteStatistics AS (
    SELECT
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM
        Votes
    GROUP BY
        PostId
),
PostHistoryInfo AS (
    SELECT
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount,
        STRING_AGG(DISTINCT cht.Name, ', ') AS CloseReasonNames
    FROM
        PostHistory ph
    LEFT JOIN
        CloseReasonTypes cht ON ph.Comment::int = cht.Id AND ph.PostHistoryTypeId = 10
    GROUP BY
        ph.PostId
)
SELECT
    t.PostId,
    t.Title,
    t.OwnerDisplayName,
    t.Score,
    t.ViewCount,
    COALESCE(pvs.UpVotes, 0) AS UpVotes,
    COALESCE(pvs.DownVotes, 0) AS DownVotes,
    phi.CloseCount,
    phi.ReopenCount,
    phi.CloseReasonNames
FROM
    TopRankedPosts t
LEFT JOIN
    PostVoteStatistics pvs ON t.PostId = pvs.PostId
LEFT JOIN
    PostHistoryInfo phi ON t.PostId = phi.PostId
WHERE
    phi.CloseCount >= 1 OR phi.ReopenCount >= 1
ORDER BY
    t.Score DESC, t.ViewCount DESC;