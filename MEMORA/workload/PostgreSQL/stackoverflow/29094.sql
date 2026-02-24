WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  
    AND 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'  
),
TopRankedTags AS (
    SELECT 
        Tags,
        COUNT(*) AS PostCount
    FROM 
        RankedPosts
    WHERE 
        TagRank <= 5  
    GROUP BY 
        Tags
    ORDER BY 
        PostCount DESC
    LIMIT 10  
),
PopularTagsWithDetails AS (
    SELECT 
        tr.Tags,
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        p.ViewCount,
        c.CommentCount,
        COALESCE(b.BadgeCount, 0) AS UserBadgeCount
    FROM 
        TopRankedTags tr
    JOIN 
        Posts p ON p.Tags LIKE '%' || tr.Tags || '%'
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT UserId, COUNT(*) AS BadgeCount FROM Badges GROUP BY UserId) b ON p.OwnerUserId = b.UserId
)
SELECT 
    p.Tags,
    COUNT(p.PostId) AS TotalPosts,
    AVG(p.ViewCount) AS AvgViews,
    AVG(p.CommentCount) AS AvgComments,
    SUM(p.UserBadgeCount) AS TotalUserBadges
FROM 
    PopularTagsWithDetails p
GROUP BY 
    p.Tags
ORDER BY 
    TotalPosts DESC;