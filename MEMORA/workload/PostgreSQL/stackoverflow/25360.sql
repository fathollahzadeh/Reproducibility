
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        U.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY SUBSTRING(Tags, 2, LENGTH(Tags) - 2) ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, U.DisplayName, p.Title, p.Tags, p.CreationDate, p.Score, p.ViewCount
),
TopRankedPosts AS (
    SELECT 
        PostId, Title, Tags, CreationDate, Score, ViewCount, CommentCount, OwnerDisplayName
    FROM 
        RankedPosts
    WHERE
        TagRank <= 3
),
AggregatedData AS (
    SELECT 
        t.Tags,
        COUNT(*) AS PostCount,
        SUM(t.Score) AS TotalScore,
        AVG(t.CommentCount) AS AvgComments,
        MAX(t.ViewCount) AS MaxViews
    FROM 
        TopRankedPosts t
    GROUP BY 
        t.Tags
)
SELECT 
    a.Tags,
    a.PostCount,
    a.TotalScore,
    a.AvgComments,
    a.MaxViews,
    pt.Name AS PostType
FROM 
    AggregatedData a
JOIN 
    PostTypes pt ON CARDINALITY(string_to_array(a.Tags, ', ')) = pt.Id
ORDER BY 
    a.TotalScore DESC, a.PostCount DESC;
