
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(co.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        RANK() OVER (ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments co ON p.Id = co.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 AND  
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, u.DisplayName
), 
TopRankedPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        OwnerDisplayName,
        CommentCount,
        Upvotes,
        Downvotes
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)
SELECT 
    trp.PostId,
    trp.Title,
    trp.CreationDate,
    trp.Score,
    trp.OwnerDisplayName,
    trp.CommentCount,
    trp.Upvotes,
    trp.Downvotes,
    (trp.Upvotes - trp.Downvotes) AS NetVotes,
    COUNT(ph.Id) AS PostHistoryCount
FROM 
    TopRankedPosts trp
LEFT JOIN 
    PostHistory ph ON trp.PostId = ph.PostId
GROUP BY 
    trp.PostId, trp.Title, trp.CreationDate, trp.Score, trp.OwnerDisplayName, trp.CommentCount, trp.Upvotes, trp.Downvotes
ORDER BY 
    trp.Score DESC, trp.CreationDate DESC;
