
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS Author,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, u.DisplayName, p.PostTypeId, p.CreationDate
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        Author, 
        CommentCount, 
        UpVotes, 
        DownVotes
    FROM 
        RankedPosts
    WHERE 
        rn <= 5
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.Author,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    CASE 
        WHEN tp.UpVotes IS NULL THEN 'No votes yet'
        ELSE CONCAT('Ratio: ', COALESCE(tp.UpVotes::DECIMAL / NULLIF(tp.UpVotes + tp.DownVotes, 0), 0), ':1')
    END AS VoteRatio,
    COALESCE(ph.Comment, 'No history available') AS PostHistory
FROM 
    TopPosts tp
LEFT JOIN 
    PostHistory ph ON ph.PostId = tp.PostId AND ph.PostHistoryTypeId IN (10, 11, 12)
ORDER BY 
    tp.CommentCount DESC
LIMIT 50;
