WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
        AND p.PostTypeId IN (1, 2)  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
PostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        rp.UserPostRank,
        (rp.UpVoteCount - rp.DownVoteCount) AS NetVoteScore
    FROM 
        RankedPosts rp
    WHERE 
        rp.UserPostRank = 1
),
ClosedPostReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    INNER JOIN 
        CloseReasonTypes cr ON cr.Id = CAST(ph.Comment AS int)
    WHERE 
        ph.PostHistoryTypeId = 10  
    GROUP BY 
        ph.PostId
)
SELECT 
    ps.Title,
    ps.Score,
    ps.ViewCount,
    ps.CommentCount,
    ps.NetVoteScore,
    COALESCE(cpr.CloseReasons, 'No closure reasons') AS CloseReason
FROM 
    PostStats ps
LEFT JOIN 
    ClosedPostReasons cpr ON ps.PostId = cpr.PostId
WHERE 
    ps.NetVoteScore > 0 
    AND ps.CommentCount > 10
ORDER BY 
    ps.NetVoteScore DESC,
    ps.ViewCount DESC
LIMIT 10;