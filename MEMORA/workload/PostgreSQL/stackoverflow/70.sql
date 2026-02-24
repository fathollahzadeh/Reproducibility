
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
        AND p.Score > 10
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.CreationDate
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank = 1
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.ViewCount,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    CASE 
        WHEN tp.UpVotes IS NULL THEN 0
        ELSE tp.UpVotes
    END AS AdjustedUpVotes,
    CASE 
        WHEN tp.DownVotes IS NULL THEN 0
        ELSE tp.DownVotes
    END AS AdjustedDownVotes,
    COALESCE(NULLIF(tp.UpVotes, 0), NULLIF(tp.DownVotes, 0), -1) AS VoteStatus
FROM 
    TopPosts tp
ORDER BY 
    tp.ViewCount DESC
FETCH FIRST 10 ROWS ONLY;
