WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND  
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'  
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        OwnerDisplayName,
        Score,
        ViewCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10  
),
PostStats AS (
    SELECT 
        tp.Title,
        tp.OwnerDisplayName,
        tp.Score,
        tp.ViewCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(COUNT(c.Id), 0) AS CommentCount
    FROM 
        TopPosts tp
    LEFT JOIN 
        Votes v ON tp.PostId = v.PostId
    LEFT JOIN 
        Comments c ON tp.PostId = c.PostId
    GROUP BY 
        tp.PostId, tp.Title, tp.OwnerDisplayName, tp.Score, tp.ViewCount
),
FinalOutput AS (
    SELECT 
        fs.*,
        (UpVotes - DownVotes) AS NetVotes,
        CASE 
            WHEN ViewCount > 1000 THEN 'Popular'
            WHEN ViewCount BETWEEN 501 AND 1000 THEN 'Moderately Popular'
            ELSE 'Less Popular'
        END AS PopularityStatus
    FROM 
        PostStats fs
)
SELECT 
    * 
FROM 
    FinalOutput
ORDER BY 
    Score DESC, ViewCount DESC;