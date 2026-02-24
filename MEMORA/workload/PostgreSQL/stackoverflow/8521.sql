WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
),
PostWithComments AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.Score,
        tp.ViewCount,
        tp.OwnerDisplayName,
        COUNT(c.Id) AS CommentCount
    FROM 
        TopPosts tp
    LEFT JOIN 
        Comments c ON tp.PostId = c.PostId
    GROUP BY 
        tp.PostId, tp.Title, tp.CreationDate, tp.Score, tp.ViewCount, tp.OwnerDisplayName
),
PostHistoryWithVotes AS (
    SELECT 
        p.PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerDisplayName,
        p.CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastClosedDate
    FROM 
        PostWithComments p
    LEFT JOIN 
        Votes v ON p.PostId = v.PostId
    LEFT JOIN 
        PostHistory ph ON p.PostId = ph.PostId
    GROUP BY 
        p.PostId, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerDisplayName, p.CommentCount
)
SELECT 
    ph.PostId,
    ph.Title,
    ph.CreationDate,
    ph.Score,
    ph.ViewCount,
    ph.OwnerDisplayName,
    ph.CommentCount,
    ph.UpVotes,
    ph.DownVotes,
    ph.LastClosedDate,
    DENSE_RANK() OVER (ORDER BY ph.Score DESC) AS GlobalRank
FROM 
    PostHistoryWithVotes ph
ORDER BY 
    ph.Score DESC, ph.ViewCount DESC;