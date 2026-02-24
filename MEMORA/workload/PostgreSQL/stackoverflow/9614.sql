WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1  
    GROUP BY p.Id, p.Title, p.CreationDate, p.OwnerUserId, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerUserId,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes
    FROM RankedPosts rp
    WHERE rp.rn = 1
    ORDER BY rp.UpVotes - rp.DownVotes DESC
    LIMIT 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.OwnerDisplayName,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    pht.Name AS PostHistoryType
FROM TopPosts tp
JOIN PostHistory ph ON ph.PostId = tp.PostId
JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
WHERE ph.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
GROUP BY tp.PostId, tp.Title, tp.CreationDate, tp.OwnerDisplayName, tp.CommentCount, tp.UpVotes, tp.DownVotes, pht.Name
ORDER BY tp.UpVotes DESC;