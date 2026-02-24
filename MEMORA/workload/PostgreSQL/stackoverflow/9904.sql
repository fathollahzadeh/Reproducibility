
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.PostTypeId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
)
SELECT 
    t.PostId,
    t.Title,
    t.CommentCount,
    t.UpVotes,
    t.DownVotes,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = t.PostId AND v.VoteTypeId = 10) AS DeletionVotes,
    (SELECT COUNT(*) FROM PostHistory ph WHERE ph.PostId = t.PostId AND ph.PostHistoryTypeId = 10) AS CloseVotes
FROM 
    TopPosts t
ORDER BY 
    t.CommentCount DESC, (t.UpVotes - t.DownVotes) DESC;
