
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2) AS CleanedTags, 
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
        U.DisplayName AS OwnerDisplayName,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount
    FROM 
        Posts p
    JOIN Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.PostTypeId = 1 
),
FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        ViewCount,
        Score,
        CleanedTags,
        OwnerDisplayName,
        CommentCount
    FROM 
        RankedPosts
    WHERE 
        UserPostRank <= 3 
),
TagStatistics AS (
    SELECT 
        UNNEST(string_to_array(CleanedTags, '><')) AS Tag, 
        COUNT(*) AS TagCount
    FROM 
        FilteredPosts
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag, 
        TagCount,
        ROW_NUMBER() OVER (ORDER BY TagCount DESC) AS Rank
    FROM 
        TagStatistics
),
PostStatistics AS (
    SELECT 
        F.OwnerDisplayName,
        SUM(F.Score) AS TotalScore,
        SUM(F.ViewCount) AS TotalViews,
        SUM(F.CommentCount) AS TotalComments
    FROM 
        FilteredPosts F
    GROUP BY 
        F.OwnerDisplayName
)
SELECT 
    P.OwnerDisplayName,
    P.TotalScore,
    P.TotalViews,
    P.TotalComments,
    TT.Tag,
    TT.TagCount
FROM 
    PostStatistics P
JOIN 
    TopTags TT ON TT.Rank = 1 
ORDER BY 
    P.TotalScore DESC, 
    P.OwnerDisplayName;
