
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
),
UserVoteStats AS (
    SELECT 
        v.UserId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        COUNT(DISTINCT v.PostId) AS TotalPostsVotedOn
    FROM 
        Votes v
    GROUP BY 
        v.UserId
),
PostVoteHistory AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate < CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '6 months'
    GROUP BY 
        p.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS ClosedDate,
        ct.Name AS CloseReason
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes ct ON CAST(ph.Comment AS INTEGER) = ct.Id
    WHERE 
        ph.PostHistoryTypeId = 10  
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    u.TotalUpVotes,
    u.TotalDownVotes,
    u.TotalPostsVotedOn,
    p.VoteCount,
    cp.ClosedDate,
    cp.CloseReason
FROM 
    RankedPosts rp
LEFT JOIN 
    UserVoteStats u ON u.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
LEFT JOIN 
    PostVoteHistory p ON p.PostId = rp.PostId
LEFT JOIN 
    ClosedPosts cp ON cp.PostId = rp.PostId
WHERE 
    rp.Rank <= 5  
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
