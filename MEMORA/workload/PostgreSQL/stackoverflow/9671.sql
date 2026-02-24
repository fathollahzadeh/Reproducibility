
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        U.DisplayName AS Owner,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS Rank,
        p.Tags
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TopTags AS (
    SELECT 
        Tags,
        COUNT(*) AS TotalPosts
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        Tags
    ORDER BY 
        TotalPosts DESC
    LIMIT 10
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.Owner,
    tt.Tags,
    tt.TotalPosts
FROM 
    RankedPosts rp
JOIN 
    TopTags tt ON rp.Tags = tt.Tags
WHERE 
    rp.Rank <= 5 
ORDER BY 
    tt.TotalPosts DESC, rp.Score DESC;
