
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
        AND p.ViewCount > 0
),
TopPosts AS (
    SELECT 
        rp.PostID,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.Author
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
),
PostVoteCounts AS (
    SELECT 
        p.Id AS PostID,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
DetailedPostInfo AS (
    SELECT 
        tp.PostID,
        tp.Title,
        tp.CreationDate,
        tp.Score,
        tp.ViewCount,
        tp.Author,
        p.UpVotes,
        p.DownVotes,
        p.TotalVotes
    FROM 
        TopPosts tp
    JOIN 
        PostVoteCounts p ON tp.PostID = p.PostID
)

SELECT 
    dpi.PostID,
    dpi.Title,
    dpi.CreationDate,
    dpi.Score,
    COALESCE(dpi.ViewCount, 0) AS ViewCount,
    COALESCE(dpi.Author, 'Unknown Author') AS Author,
    COALESCE(dpi.UpVotes, 0) AS UpVotes,
    COALESCE(dpi.DownVotes, 0) AS DownVotes,
    CASE 
        WHEN dpi.Score IS NULL THEN 'No Score Available'
        WHEN dpi.Score > 0 THEN 'Positive Feedback'
        ELSE 'Negative Feedback'
    END AS Feedback
FROM 
    DetailedPostInfo dpi
LEFT JOIN 
    PostHistory ph ON dpi.PostID = ph.PostId AND ph.PostHistoryTypeId IN (10, 11) 
ORDER BY 
    dpi.Score DESC, dpi.CreationDate ASC
LIMIT 100;
