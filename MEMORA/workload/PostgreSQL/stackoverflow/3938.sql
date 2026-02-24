WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM Users u
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate >= (cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days')
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.Comment AS CloseReason,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS CloseRank
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10
),
VotesSummary AS (
    SELECT 
        p.Id AS PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
),
CombiningData AS (
    SELECT 
        p.PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        up.UpVotes,
        up.DownVotes,
        cr.UserDisplayName AS ClosedBy,
        cr.CloseReason,
        ur.Reputation AS UserReputation
    FROM RecentPosts p
    LEFT JOIN VotesSummary up ON p.PostId = up.PostId
    LEFT JOIN ClosedPosts cr ON p.PostId = cr.PostId AND cr.CloseRank = 1
    JOIN UserReputation ur ON p.OwnerDisplayName = ur.DisplayName
)
SELECT 
    cd.PostId,
    cd.Title,
    cd.ViewCount,
    cd.CreationDate,
    COALESCE(cd.UpVotes, 0) AS UpVotes,
    COALESCE(cd.DownVotes, 0) AS DownVotes,
    cd.ClosedBy,
    cd.CloseReason,
    cd.UserReputation,
    CASE WHEN cd.UserReputation > 1000 THEN 'Highly Reputed' 
         WHEN cd.UserReputation BETWEEN 500 AND 1000 THEN 'Moderately Reputed' 
         ELSE 'Needs Attention' END AS ReputationStatus
FROM CombiningData cd
WHERE cd.CreationDate >= (cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '7 days')
ORDER BY cd.UserReputation DESC, cd.ViewCount DESC
LIMIT 100;