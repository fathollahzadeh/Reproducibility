WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM
        Posts p
    JOIN
        Users u ON p.OwnerUserId = u.Id
    WHERE
        p.PostTypeId = 1 
),
RecentVotes AS (
    SELECT
        v.PostId,
        v.VoteTypeId,
        COUNT(v.VoteTypeId) AS VoteCount
    FROM
        Votes v
    WHERE
        v.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days' 
    GROUP BY
        v.PostId, v.VoteTypeId
),
PostHistoryStats AS (
    SELECT
        ph.PostId,
        COUNT(*) AS HistoryCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM
        PostHistory ph
    GROUP BY
        ph.PostId
),
FrequentlyEditedPosts AS (
    SELECT
        p.Id,
        p.Title,
        ps.HistoryCount,
        ps.LastEditDate
    FROM
        Posts p
    JOIN
        PostHistoryStats ps ON p.Id = ps.PostId
    WHERE
        ps.HistoryCount > 5 
),
FinalResults AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.OwnerDisplayName,
        COALESCE(rv.VoteCount, 0) AS RecentVoteCount,
        COALESCE(fep.HistoryCount, 0) AS EditCount
    FROM
        RankedPosts rp
    LEFT JOIN
        RecentVotes rv ON rp.PostId = rv.PostId AND rv.VoteTypeId = 2 
    LEFT JOIN
        FrequentlyEditedPosts fep ON rp.PostId = fep.Id
    WHERE
        rp.PostRank = 1 
)

SELECT
    fr.PostId,
    fr.Title,
    fr.CreationDate,
    fr.Score,
    fr.OwnerDisplayName,
    fr.RecentVoteCount,
    fr.EditCount
FROM
    FinalResults fr
ORDER BY
    fr.Score DESC, fr.RecentVoteCount DESC
LIMIT 10;