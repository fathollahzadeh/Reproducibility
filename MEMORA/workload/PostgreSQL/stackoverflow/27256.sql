WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        ARRAY_AGG(DISTINCT pt.Name) AS PostTypeNames
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month'
    GROUP BY 
        p.Id
),

TopPosts AS (
    SELECT 
        PostID,
        Title,
        Tags,
        CreationDate,
        ViewCount,
        Score,
        CommentCount,
        PostTypeNames
    FROM 
        RankedPosts
    WHERE 
        Rank <= 3  
)

SELECT 
    up.DisplayName,
    COUNT(DISTINCT tp.PostID) AS TotalPosts,
    SUM(tp.ViewCount) AS TotalViews,
    AVG(tp.Score) AS AverageScore,
    STRING_AGG(DISTINCT tp.PostTypeNames::text, ', ') AS PostTypes,
    STRING_AGG(DISTINCT tp.Tags, ', ') AS AllTags
FROM 
    TopPosts tp
JOIN 
    Users up ON tp.PostID IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = up.Id)
GROUP BY 
    up.Id
ORDER BY 
    TotalPosts DESC, TotalViews DESC
LIMIT 10;