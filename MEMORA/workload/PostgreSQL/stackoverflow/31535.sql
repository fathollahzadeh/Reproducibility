
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS OwnerPostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId, Title, CreationDate, Score, ViewCount, OwnerDisplayName, CommentCount
    FROM 
        RankedPosts
    WHERE 
        OwnerPostRank <= 3 
),
PostVoteStats AS (
    SELECT 
        PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Votes v
    GROUP BY 
        PostId
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        ph.CreationDate AS ClosedDate,
        cr.Name AS CloseReason
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    JOIN 
        CloseReasonTypes cr ON CAST(ph.Comment AS integer) = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10 
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.OwnerDisplayName,
    COALESCE(ps.TotalUpVotes, 0) AS TotalUpVotes,
    COALESCE(ps.TotalDownVotes, 0) AS TotalDownVotes,
    tp.CommentCount,
    cp.ClosedDate,
    cp.CloseReason
FROM 
    TopPosts tp
LEFT JOIN 
    PostVoteStats ps ON tp.PostId = ps.PostId
LEFT JOIN 
    ClosedPosts cp ON tp.PostId = cp.PostId
ORDER BY 
    tp.Score DESC, tp.CreationDate DESC;
