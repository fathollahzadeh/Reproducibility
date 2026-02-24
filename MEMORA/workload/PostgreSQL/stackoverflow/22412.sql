WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COALESCE(vs.VoteScore, 0) AS VoteScore,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 
                     WHEN VoteTypeId = 3 THEN -1 
                     ELSE 0 END) AS VoteScore
        FROM 
            Votes
        GROUP BY 
            PostId
    ) vs ON p.Id = vs.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > cast('2024-10-01' as date) - INTERVAL '30 days'
),
TopCommenters AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(C.Id) AS TotalComments
    FROM 
        Users U
    JOIN 
        Comments C ON U.Id = C.UserId
    GROUP BY 
        U.Id, U.DisplayName
    HAVING 
        COUNT(C.Id) > 10
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.VoteScore,
        rp.CommentCount,
        rp.ViewCount,
        rp.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        CASE 
            WHEN rp.VoteScore > 0 THEN 'Positive'
            WHEN rp.VoteScore < 0 THEN 'Negative'
            ELSE 'Neutral'
        END AS VoteType,
        RANK() OVER (ORDER BY rp.VoteScore DESC, rp.CommentCount DESC) AS PostRank
    FROM 
        RecentPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    WHERE 
        rp.VoteScore IS NOT NULL
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.VoteScore,
    pd.CommentCount,
    pd.ViewCount,
    pd.OwnerDisplayName,
    pd.OwnerReputation,
    pd.VoteType,
    COALESCE(tc.TotalComments, 0) AS TotalCommentsByTopCommenters
FROM 
    PostDetails pd
LEFT JOIN 
    TopCommenters tc ON pd.OwnerUserId = tc.UserId
WHERE 
    pd.PostRank <= 10
ORDER BY 
    pd.VoteScore DESC,
    TotalCommentsByTopCommenters DESC;