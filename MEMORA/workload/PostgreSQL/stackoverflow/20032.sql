WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM Posts p
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostsCreated
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.Reputation
),
VoteDetails AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN v.VoteTypeId IN (1, 4, 6) THEN 1 ELSE 0 END) AS SpecialVotes
    FROM Votes v
    GROUP BY v.PostId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes,
        COUNT(*) FILTER (WHERE ph.PostHistoryTypeId IN (10, 11)) AS Closures
    FROM PostHistory ph
    JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE ph.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '2 years'
    GROUP BY ph.PostId
)
SELECT 
    pp.PostId,
    pp.Title,
    pp.CreationDate,
    pp.Score,
    COALESCE(rd.UpVotes, 0) AS UpVotes,
    COALESCE(rd.DownVotes, 0) AS DownVotes,
    COALESCE(rd.SpecialVotes, 0) AS SpecialVotes,
    COALESCE(phd.HistoryTypes, 'No History') AS PostHistory,
    COALESCE(phd.Closures, 0) AS ClosureCount,
    CASE 
        WHEN u.Reputation IS NULL THEN 'New User'
        WHEN u.Reputation < 100 THEN 'Low Reputation'
        WHEN u.Reputation BETWEEN 100 AND 1000 THEN 'Regular User'
        ELSE 'High Reputation'
    END AS UserCategory
FROM RankedPosts pp
LEFT JOIN VoteDetails rd ON pp.PostId = rd.PostId
LEFT JOIN PostHistoryDetails phd ON pp.PostId = phd.PostId
LEFT JOIN Users u ON pp.PostId = u.Id
WHERE pp.PostRank <= 5
ORDER BY pp.CreationDate DESC
LIMIT 100;