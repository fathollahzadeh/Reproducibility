WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Score, 
        p.CreationDate, 
        u.DisplayName AS Author, 
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1
),
PostVoteCounts AS (
    SELECT 
        v.PostId, 
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes v
    GROUP BY v.PostId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseVotes
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10
    GROUP BY ph.PostId
),
AggregatePostData AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.Author,
        COALESCE(pvc.UpVotes, 0) AS UpVotes,
        COALESCE(pvc.DownVotes, 0) AS DownVotes,
        COALESCE(cp.CloseVotes, 0) AS CloseVotes
    FROM RankedPosts rp
    LEFT JOIN PostVoteCounts pvc ON rp.PostId = pvc.PostId
    LEFT JOIN ClosedPosts cp ON rp.PostId = cp.PostId
    WHERE rp.rn = 1
)
SELECT 
    apd.PostId,
    apd.Title,
    apd.Score,
    apd.CreationDate,
    apd.Author,
    apd.UpVotes,
    apd.DownVotes,
    apd.CloseVotes,
    CASE 
        WHEN apd.CloseVotes > 0 THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM AggregatePostData apd
ORDER BY apd.Score DESC, apd.CreationDate DESC
LIMIT 10;
