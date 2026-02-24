WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.PostTypeId IN (1, 2) 
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.ViewCount,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
),
PostDetails AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.Score,
        tp.CreationDate,
        tp.ViewCount,
        tp.OwnerDisplayName,
        COALESCE(C.Count, 0) AS CommentCount,
        COALESCE(V.UpVoteCount, 0) AS UpVoteCount,
        COALESCE(V.DownVoteCount, 0) AS DownVoteCount
    FROM 
        TopPosts tp
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS Count FROM Comments GROUP BY PostId) C ON tp.PostId = C.PostId
    LEFT JOIN 
        (SELECT PostId, 
                SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
                SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
         FROM Votes 
         GROUP BY PostId) V ON tp.PostId = V.PostId
)
SELECT 
    pd.Title,
    pd.OwnerDisplayName,
    pd.Score,
    pd.ViewCount,
    pd.CommentCount,
    pd.UpVoteCount,
    pd.DownVoteCount,
    EXTRACT(YEAR FROM pd.CreationDate) AS PostYear,
    CASE 
        WHEN pd.Score >= 100 THEN 'High'
        WHEN pd.Score BETWEEN 50 AND 99 THEN 'Medium'
        ELSE 'Low'
    END AS ScoreCategory
FROM 
    PostDetails pd
WHERE 
    pd.ViewCount > 1000 
ORDER BY 
    pd.Score DESC, pd.CreationDate DESC;