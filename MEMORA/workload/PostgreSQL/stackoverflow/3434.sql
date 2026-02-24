
WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        p.AnswerCount, 
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) as rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
        AND p.Score > 0
),
PostDetails AS (
    SELECT 
        rp.Id, 
        rp.Title, 
        rp.CreationDate,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COALESCE((SELECT COUNT(*) 
                  FROM Votes v 
                  WHERE v.PostId = rp.Id 
                    AND v.VoteTypeId = 2), 0) AS TotalUpvotes,
        COALESCE((SELECT COUNT(*) 
                  FROM Votes v 
                  WHERE v.PostId = rp.Id 
                    AND v.VoteTypeId = 3), 0) AS TotalDownvotes,
        CASE 
            WHEN rp.CommentCount > 10 THEN 'Highly Discussed'
            WHEN rp.CommentCount > 0 THEN 'Moderately Discussed'
            ELSE 'Less Discussed'
        END AS DiscussionLevel
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Votes v ON rp.Id = v.PostId
    GROUP BY 
        rp.Id, rp.Title, rp.CreationDate, rp.CommentCount
)
SELECT 
    pd.Title,
    pd.CreationDate,
    pd.TotalBounty,
    pd.TotalUpvotes,
    pd.TotalDownvotes,
    pd.DiscussionLevel,
    p.ConversionRate,
    (CASE 
        WHEN pd.TotalUpvotes > pd.TotalDownvotes THEN 'Positive'
        WHEN pd.TotalUpvotes < pd.TotalDownvotes THEN 'Negative'
        ELSE 'Neutral'
    END) AS Sentiment
FROM 
    PostDetails pd
LEFT JOIN (
    SELECT 
        PostId, 
        (SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) * 1.0 / NULLIF(COUNT(*), 0)) * 100 AS ConversionRate
    FROM 
        Votes
    GROUP BY 
        PostId
) p ON pd.Id = p.PostId
WHERE 
    pd.DiscussionLevel = 'Highly Discussed'
ORDER BY 
    pd.TotalBounty DESC, 
    pd.CreationDate DESC;
