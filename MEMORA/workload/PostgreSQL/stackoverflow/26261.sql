WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.PostTypeId = 1 
),
FilteredPosts AS (
    SELECT 
        Id,
        Title,
        Body,
        CreationDate,
        ViewCount,
        AnswerCount,
        CommentCount,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        TagRank <= 5 
),
PostInsights AS (
    SELECT 
        fp.Title,
        fp.ViewCount,
        fp.AnswerCount,
        fp.CommentCount,
        COUNT(c.Id) AS TotalComments,
        COUNT(DISTINCT b.Id) AS TotalBadges
    FROM 
        FilteredPosts fp
    LEFT JOIN 
        Comments c ON fp.Id = c.PostId
    LEFT JOIN 
        Users u ON fp.OwnerDisplayName = u.DisplayName
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        fp.Title, fp.ViewCount, fp.AnswerCount, fp.CommentCount
)
SELECT 
    Title,
    ViewCount,
    AnswerCount,
    CommentCount,
    TotalComments,
    TotalBadges,
    ROUND((ViewCount + AnswerCount * 2 + CommentCount * 0.5) / NULLIF(TotalBadges + 1, 0), 2) AS EngagementScore
FROM 
    PostInsights
ORDER BY 
    EngagementScore DESC
LIMIT 10;