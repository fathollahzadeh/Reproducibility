WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COALESCE(b.Name, 'No Badge') AS UserBadge,
        U.Reputation
    FROM 
        Posts p
    LEFT JOIN Users U ON p.OwnerUserId = U.Id
    LEFT JOIN Badges b ON U.Id = b.UserId AND b.Class = 1
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostVoteCounts AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.Rank,
    COALESCE(v.UpVotes, 0) AS UpVotes,
    COALESCE(v.DownVotes, 0) AS DownVotes,
    COALESCE(c.CloseCount, 0) AS CloseCount,
    rp.UserBadge,
    rp.Reputation
FROM 
    RankedPosts rp
LEFT JOIN 
    PostVoteCounts v ON rp.PostId = v.PostId
LEFT JOIN 
    ClosedPosts c ON rp.PostId = c.PostId
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Rank, rp.CreationDate DESC;