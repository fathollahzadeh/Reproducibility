
WITH RankedPosts AS (
    SELECT
        p.Id,
        p.Title,
        p.CreationDate,
        u.DisplayName AS Owner,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM
        Posts p
    LEFT JOIN
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    WHERE
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year' 
    GROUP BY
        p.Id, p.Title, p.CreationDate, u.DisplayName
),
ClosingPosts AS (
    SELECT
        p.Id,
        p.Title,
        ph.CreationDate AS ClosedDate,
        ph.UserDisplayName AS ClosedBy,
        ph.Comment AS CloseReason
    FROM
        Posts p
    JOIN
        PostHistory ph ON p.Id = ph.PostId
    WHERE
        ph.PostHistoryTypeId = 10
),
RecentRank AS (
    SELECT
        r.*,
        CASE 
            WHEN r.OwnerPostRank = 1 THEN 'Most Recent'
            WHEN r.OwnerPostRank <= 5 THEN 'Top 5'
            ELSE 'Other'
        END AS RankingGroup
    FROM
        RankedPosts r
)
SELECT
    rr.Id,
    rr.Title,
    rr.Owner,
    rr.UpVotes,
    rr.DownVotes,
    c.ClosedDate,
    c.ClosedBy,
    c.CloseReason,
    rr.RankingGroup
FROM
    RecentRank rr
LEFT JOIN
    ClosingPosts c ON rr.Id = c.Id
WHERE
    rr.UpVotes - rr.DownVotes > 5
ORDER BY
    rr.UpVotes DESC, rr.CreationDate ASC
FETCH FIRST 50 ROWS ONLY;
