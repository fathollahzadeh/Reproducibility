
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS RankByViews,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 10 THEN 1 ELSE 0 END), 0) AS DeletionVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.PostTypeId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.RankByViews,
        rp.UpVotes,
        rp.DownVotes,
        (rp.UpVotes - rp.DownVotes) AS NetVotes,
        CASE 
            WHEN rp.DeletionVotes > 0 THEN 'Potentially Deleted'
            ELSE 'Active'
        END AS PostStatus
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankByViews <= 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.NetVotes,
    tp.PostStatus,
    u.DisplayName AS OwnerName,
    (SELECT COUNT(*) 
     FROM Comments c 
     WHERE c.PostId = tp.PostId) AS CommentCount,
    (
        SELECT STRING_AGG(b.Name, ', ')
        FROM Badges b 
        WHERE b.UserId IN (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)
    ) AS OwnerBadges
FROM 
    TopPosts tp
LEFT JOIN 
    Users u ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)
ORDER BY 
    tp.NetVotes DESC, 
    tp.ViewCount DESC
FETCH FIRST 10 ROWS ONLY;
