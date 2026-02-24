WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        MAX(v.CreationDate) OVER (PARTITION BY p.Id) AS LastVoteDate
    FROM Posts p
    LEFT JOIN Comments c ON c.PostId = p.Id
    LEFT JOIN Votes v ON v.PostId = p.Id
    WHERE p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId, 
        ph.PostHistoryTypeId, 
        ph.CreationDate AS HistoryCreatedDate, 
        p.Title AS PostTitle,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM PostHistory ph
    JOIN Posts p ON p.Id = ph.PostId
    WHERE ph.PostHistoryTypeId IN (10, 11, 12, 13)
),
InterestingVotes AS (
    SELECT 
        v.PostId, 
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes v
    GROUP BY v.PostId
),
FinalPostAggregation AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        COALESCE(iv.VoteCount, 0) AS TotalVotes,
        COALESCE(iv.UpVotes, 0) AS TotalUpVotes,
        COALESCE(iv.DownVotes, 0) AS TotalDownVotes,
        COALESCE(phd.PostHistoryTypeId, -1) AS RecentHistoryId,
        CASE 
            WHEN phd.HistoryRank = 1 THEN phd.HistoryCreatedDate
            ELSE NULL 
        END AS MostRecentHistoryDate
    FROM RankedPosts rp
    LEFT JOIN InterestingVotes iv ON iv.PostId = rp.PostId
    LEFT JOIN PostHistoryDetails phd ON phd.PostId = rp.PostId AND phd.HistoryRank = 1
)
SELECT 
    f.PostId,
    f.Title,
    f.CreationDate,
    f.Score,
    f.ViewCount,
    f.CommentCount,
    f.TotalVotes,
    f.TotalUpVotes,
    f.TotalDownVotes,
    f.RecentHistoryId,
    f.MostRecentHistoryDate,
    CASE 
        WHEN f.TotalVotes = 0 THEN 'No votes'
        ELSE 
            CASE 
                WHEN f.TotalUpVotes > f.TotalDownVotes THEN 'Net positive'
                WHEN f.TotalUpVotes < f.TotalDownVotes THEN 'Net negative'
                ELSE 'Neutral votes'
            END 
    END AS VoteStatus
FROM FinalPostAggregation f
WHERE f.CommentCount > 0 
  AND (f.Score * 1.0 / NULLIF(f.ViewCount, 0)) > 0.1
ORDER BY f.ViewCount DESC
LIMIT 100;