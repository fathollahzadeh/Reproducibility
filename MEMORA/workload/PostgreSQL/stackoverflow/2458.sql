
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes, 
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes  
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        rp.* 
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
),
PostHistoryAggregates AS (
    SELECT 
        ph.PostId,
        STRING_AGG(ph.Comment, '; ') AS Comments,
        COUNT(ph.Id) AS HistoryCount
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '2 years'
    GROUP BY 
        ph.PostId
)
SELECT 
    tp.Id,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.CommentCount,
    COALESCE(pa.Comments, 'No Comments') AS PostComments,
    pa.HistoryCount,
    (tp.UpVotes - tp.DownVotes) AS NetVotes,
    CASE 
        WHEN tp.Score >= 10 THEN 'Hot'
        WHEN tp.Score BETWEEN 5 AND 9 THEN 'Warm'
        ELSE 'Cold'
    END AS Popularity
FROM 
    TopPosts tp
LEFT JOIN 
    PostHistoryAggregates pa ON tp.Id = pa.PostId
ORDER BY 
    tp.Score DESC
LIMIT 10;
