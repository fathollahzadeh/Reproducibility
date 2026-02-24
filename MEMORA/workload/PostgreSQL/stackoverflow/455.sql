WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS Owner,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1 AND p.Score IS NOT NULL
),
PostVoteCounts AS (
    SELECT 
        PostId,
        COUNT(*) FILTER (WHERE VoteTypeId = 2) AS UpVotes,
        COUNT(*) FILTER (WHERE VoteTypeId = 3) AS DownVotes
    FROM Votes
    GROUP BY PostId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserDisplayName,
        RANK() OVER (ORDER BY ph.CreationDate DESC) AS CloseRank
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Owner,
    rp.Score,
    COALESCE(pvc.UpVotes, 0) AS TotalUpVotes,
    COALESCE(pvc.DownVotes, 0) AS TotalDownVotes,
    cp.CloseRank
FROM RankedPosts rp
LEFT JOIN PostVoteCounts pvc ON rp.PostId = pvc.PostId
LEFT JOIN ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    rp.Rank = 1 
    AND (rp.Score > 10 OR cp.CloseRank IS NOT NULL)
ORDER BY rp.CreationDate DESC;
