
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY p.Score DESC) AS RankByScore,
        COUNT(com.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Comments com ON p.Id = com.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  
        AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 months' 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, U.Id
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.CommentCount,
        rp.UpvoteCount,
        U.Reputation
    FROM 
        RankedPosts rp
    JOIN 
        Users U ON rp.PostId IN (SELECT AcceptedAnswerId FROM Posts WHERE AcceptedAnswerId IS NOT NULL)
    WHERE 
        rp.RankByScore <= 5  
)
SELECT 
    FP.PostId,
    FP.Title,
    FP.CreationDate,
    FP.ViewCount,
    FP.Score,
    FP.CommentCount,
    FP.UpvoteCount,
    U.DisplayName,
    U.Reputation,
    COUNT(DISTINCT b.Id) AS BadgeCount,
    ARRAY_AGG(DISTINCT b.Name) AS BadgeNames
FROM 
    FilteredPosts FP
JOIN 
    Users U ON FP.Reputation > 1000  
LEFT JOIN 
    Badges b ON U.Id = b.UserId 
WHERE 
    U.Location IS NOT NULL
GROUP BY 
    FP.PostId, FP.Title, FP.CreationDate, FP.ViewCount, FP.Score, FP.CommentCount, FP.UpvoteCount, U.Id, U.DisplayName, U.Reputation
ORDER BY 
    FP.Score DESC, FP.CommentCount DESC
LIMIT 10;
