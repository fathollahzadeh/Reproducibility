WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
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
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
        AND p.Score > 0
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        Author
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
),
VotesSummary AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS TotalUpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS TotalDownVotes,
        COUNT(CASE WHEN VoteTypeId = 6 THEN 1 END) AS TotalCloseVotes,
        COUNT(CASE WHEN VoteTypeId = 7 THEN 1 END) AS TotalReopenVotes
    FROM 
        Votes
    GROUP BY 
        PostId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.Author,
    COALESCE(vs.TotalUpVotes, 0) AS TotalUpVotes,
    COALESCE(vs.TotalDownVotes, 0) AS TotalDownVotes,
    COALESCE(vs.TotalCloseVotes, 0) AS TotalCloseVotes,
    COALESCE(vs.TotalReopenVotes, 0) AS TotalReopenVotes
FROM 
    TopPosts tp
LEFT JOIN 
    VotesSummary vs ON tp.PostId = vs.PostId
ORDER BY 
    tp.CreationDate DESC;