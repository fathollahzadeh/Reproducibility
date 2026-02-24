
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
        AND p.Score > 10
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.OwnerDisplayName,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(v.UpVoteCount, 0) AS UpVoteCount
    FROM 
        RankedPosts rp
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) c ON rp.PostId = c.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON rp.PostId = v.PostId
    WHERE 
        rp.rn = 1
),
FinalResults AS (
    SELECT 
        tp.Title,
        tp.CreationDate,
        tp.OwnerDisplayName,
        tp.CommentCount,
        tp.UpVoteCount,
        CASE 
            WHEN tp.UpVoteCount > 20 THEN 'Hot Post'
            ELSE 'Regular Post'
        END AS PostStatus
    FROM 
        TopPosts tp
)
SELECT 
    f.Title,
    f.CreationDate,
    f.OwnerDisplayName,
    f.CommentCount,
    f.UpVoteCount,
    f.PostStatus
FROM 
    FinalResults f
ORDER BY 
    f.UpVoteCount DESC, f.CreationDate DESC
LIMIT 10;
