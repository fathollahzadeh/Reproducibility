
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS HistoryCount 
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '90 days')
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
),
TopPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.Score,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount,
        RANK() OVER (ORDER BY rp.Score DESC) AS Rank
    FROM 
        RecentPosts rp
    WHERE 
        rp.CommentCount > 0 AND rp.Score > 0
)
SELECT 
    tp.Title,
    tp.OwnerDisplayName,
    tp.CreationDate,
    tp.Score,
    tp.CommentCount,
    tp.UpVoteCount,
    tp.DownVoteCount,
    COALESCE(ph.HistoryCount, 0) AS PostHistoryCount,
    CASE 
        WHEN tp.Score > 100 THEN 'Hot' 
        WHEN tp.Score BETWEEN 50 AND 100 THEN 'Warm' 
        ELSE 'Cold' 
    END AS PostTemperature
FROM 
    TopPosts tp
LEFT JOIN 
    PostHistoryStats ph ON tp.PostId = ph.PostId
WHERE 
    tp.Rank <= 10
ORDER BY 
    tp.Score DESC;
