WITH PostStatistics AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= '2023-01-01'
    GROUP BY 
        p.Id, p.Title, p.ViewCount
),
TopPosts AS (
    SELECT 
        Id, 
        Title, 
        ViewCount, 
        UpVotes, 
        DownVotes, 
        CommentCount,
        RANK() OVER (ORDER BY (UpVotes - DownVotes) DESC) AS VoteRank
    FROM 
        PostStatistics
),
ClosedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        ph.CreationDate AS CloseDate,
        ph.UserDisplayName AS ClosedBy,
        ph.Comment AS CloseReason
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10
)
SELECT 
    tp.Title,
    tp.ViewCount,
    tp.UpVotes,
    tp.DownVotes,
    tp.CommentCount,
    cp.CloseDate,
    cp.ClosedBy,
    cp.CloseReason
FROM 
    TopPosts tp
LEFT JOIN 
    ClosedPosts cp ON tp.Id = cp.Id
WHERE 
    tp.VoteRank <= 10
ORDER BY 
    tp.VoteRank;
