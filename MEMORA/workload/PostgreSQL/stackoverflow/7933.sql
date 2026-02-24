WITH RecentVotes AS (
    SELECT 
        v.PostId, 
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN v.VoteTypeId IN (6, 7) THEN 1 END) AS CloseReopenVotes
    FROM Votes v
    WHERE v.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY v.PostId
),
PostAnalytics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COALESCE(rv.UpVotes, 0) AS UpVotes,
        COALESCE(rv.DownVotes, 0) AS DownVotes,
        COALESCE(rv.CloseReopenVotes, 0) AS CloseReopenVotes,
        COALESCE(u.Reputation, 0) AS OwnerReputation,
        p.CreationDate
    FROM Posts p
    LEFT JOIN RecentVotes rv ON p.Id = rv.PostId
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate >= '2023-01-01' AND p.PostTypeId IN (1, 2)
)
SELECT 
    pa.PostId,
    pa.Title,
    pa.Score,
    pa.ViewCount,
    pa.UpVotes,
    pa.DownVotes,
    pa.CloseReopenVotes,
    pa.OwnerReputation,
    pa.CreationDate,
    ROW_NUMBER() OVER (ORDER BY pa.Score DESC, pa.ViewCount DESC) AS Rank
FROM PostAnalytics pa
ORDER BY pa.Score DESC, pa.ViewCount DESC
LIMIT 100;