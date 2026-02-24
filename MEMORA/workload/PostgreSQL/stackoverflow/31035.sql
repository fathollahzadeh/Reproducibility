WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COALESCE(u.DisplayName, 'Anonymous') AS OwnerDisplayName
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.Id,
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
PostDetails AS (
    SELECT 
        tp.Title,
        tp.OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,  
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes   
    FROM 
        TopPosts tp
    LEFT JOIN 
        Comments c ON tp.Id = c.PostId
    LEFT JOIN 
        Votes v ON tp.Id = v.PostId
    GROUP BY 
        tp.Title, tp.OwnerDisplayName
),
FinalResult AS (
    SELECT 
        pd.Title,
        pd.OwnerDisplayName,
        pd.CommentCount,
        pd.UpVotes,
        pd.DownVotes,
        CASE 
            WHEN pd.UpVotes + pd.DownVotes > 0 THEN 
                ROUND((pd.UpVotes * 1.0 / (pd.UpVotes + pd.DownVotes)) * 100, 2) 
            ELSE 0 
        END AS UpvotePercentage
    FROM 
        PostDetails pd
)
SELECT 
    f.Title,
    f.OwnerDisplayName,
    f.CommentCount,
    f.UpVotes,
    f.DownVotes,
    f.UpvotePercentage
FROM 
    FinalResult f
WHERE 
    f.UpvotePercentage > 50 
ORDER BY 
    f.UpVotes DESC, f.CommentCount DESC;