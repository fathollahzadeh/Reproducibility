WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
),
FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        OwnerDisplayName,
        Score,
        ViewCount,
        Tags
    FROM 
        RankedPosts
    WHERE 
        rn = 1 
),
TopTagPosts AS (
    SELECT 
        Tags,
        COUNT(*) AS TagPostCount,
        SUM(Score) AS TotalScore
    FROM 
        FilteredPosts
    GROUP BY 
        Tags
    ORDER BY 
        TagPostCount DESC
    LIMIT 10 
)
SELECT 
    f.OwnerDisplayName,
    f.Title,
    f.CreationDate,
    f.Score,
    f.ViewCount,
    tt.Tags,
    tt.TagPostCount,
    tt.TotalScore
FROM 
    FilteredPosts f
JOIN 
    TopTagPosts tt ON f.Tags = tt.Tags
ORDER BY 
    tt.TotalScore DESC, f.CreationDate DESC;