WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        COALESCE(vote_counts.UpVotes, 0) AS UpVotes,
        COALESCE(vote_counts.DownVotes, 0) AS DownVotes,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC) AS Rank
    FROM
        Posts p
    LEFT JOIN (
        SELECT
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM
            Votes
        GROUP BY
            PostId
    ) vote_counts ON p.Id = vote_counts.PostId
    WHERE
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
),
TopPostedUsers AS (
    SELECT
        OwnerUserId,
        COUNT(Id) AS PostCount
    FROM
        Posts
    GROUP BY
        OwnerUserId
    ORDER BY
        PostCount DESC
    LIMIT 10
),
PostHistoryDetails AS (
    SELECT
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS ClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS ReopenedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 35 OR ph.PostHistoryTypeId = 36 THEN ph.CreationDate END) AS MigrationDate
    FROM
        PostHistory ph
    GROUP BY
        ph.PostId
)
SELECT
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.UpVotes,
    rp.DownVotes,
    CASE 
        WHEN phd.ClosedDate IS NOT NULL AND (phd.ReopenedDate IS NULL OR phd.ReopenedDate < phd.ClosedDate) THEN 'Closed'
        WHEN phd.ReopenedDate IS NOT NULL THEN 'Reopened'
        ELSE 'Active'
    END AS PostStatus,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.PostId) AS CommentCount,
    tu.DisplayName,
    tu.Reputation
FROM
    RankedPosts rp
JOIN
    Posts p ON rp.PostId = p.Id
LEFT JOIN
    PostHistoryDetails phd ON p.Id = phd.PostId
JOIN
    Users tu ON p.OwnerUserId = tu.Id
WHERE
    rp.Rank <= 5
    AND tu.Location IS NOT NULL
    AND tu.Reputation > 100
ORDER BY
    rp.ViewCount DESC;