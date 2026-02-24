
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Score, 
        p.CreationDate, 
        p.OwnerUserId, 
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.Score, 
        rp.CommentCount, 
        rp.UpVotes, 
        u.DisplayName
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    WHERE 
        rp.UserRank <= 5
),
PostsWithCloseReasons AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        ph.Comment AS CloseReason
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10
)
SELECT 
    tp.PostId, 
    tp.Title, 
    tp.Score, 
    tp.CommentCount, 
    tp.UpVotes, 
    tp.DisplayName, 
    COALESCE(pcr.CloseReason, 'Not Closed') AS CloseReason
FROM 
    TopPosts tp
LEFT JOIN 
    PostsWithCloseReasons pcr ON tp.PostId = pcr.PostId
ORDER BY 
    tp.Score DESC, tp.CommentCount DESC
LIMIT 10;
