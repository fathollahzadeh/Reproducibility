
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS Owner,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY u.Location ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
        AND u.Reputation > 100
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName, u.Location
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Owner,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 5
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Owner,
    tp.CommentCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = tp.PostId AND v.VoteTypeId = 2) AS UpVotes,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = tp.PostId AND v.VoteTypeId = 3) AS DownVotes,
    CASE 
        WHEN tp.CommentCount IS NULL THEN 'No Comments Yet'
        ELSE CAST(tp.CommentCount AS TEXT)
    END AS CommentsStatus,
    COALESCE((SELECT STRING_AGG(name, ', ') 
               FROM PostHistory ph 
               JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id 
               WHERE ph.PostId = tp.PostId AND pht.Name LIKE '%Edit%'), 'No Edits') AS EditHistory
FROM 
    TopPosts tp
ORDER BY 
    tp.CommentCount DESC, 
    tp.CreationDate ASC;
