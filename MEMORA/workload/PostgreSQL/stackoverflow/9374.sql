
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        U.DisplayName AS Owner,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 2 THEN v.Id END) AS UpvoteCount,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 3 THEN v.Id END) AS DownvoteCount,
        RANK() OVER (ORDER BY p.Score DESC, p.CreationDate DESC) AS ScoreRank
    FROM 
        Posts p
    LEFT JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  
        AND p.CreationDate >= '2024-10-01 12:34:56'::timestamp - INTERVAL '30 days'  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, U.DisplayName
), TopPosts AS (
    SELECT 
        rp.*,
        ROW_NUMBER() OVER (ORDER BY rp.ViewCount DESC) AS ViewRank
    FROM 
        RankedPosts rp
)
SELECT 
    t.PostId,
    t.Title,
    t.CreationDate,
    t.ViewCount,
    t.Score,
    t.Owner,
    t.CommentCount,
    t.UpvoteCount,
    t.DownvoteCount,
    t.ScoreRank,
    t.ViewRank
FROM 
    TopPosts t
WHERE 
    t.ScoreRank <= 10  
    AND t.ViewRank <= 10  
ORDER BY 
    t.ScoreRank, t.ViewRank;
