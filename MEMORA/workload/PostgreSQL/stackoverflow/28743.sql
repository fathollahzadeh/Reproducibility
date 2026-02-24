
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerName,
        p.CreationDate,
        p.LastActivityDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
TopPosts AS (
    SELECT
        PostId,
        Title,
        Body,
        Tags,
        OwnerName,
        CreationDate,
        LastActivityDate
    FROM 
        RankedPosts
    WHERE 
        PostRank = 1 
),
TagStatistics AS (
    SELECT 
        unnest(string_to_array(Tags, '><')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        TopPosts
    GROUP BY 
        TagName
),
MostCommonTag AS (
    SELECT 
        TagName,
        TagCount,
        RANK() OVER (ORDER BY TagCount DESC) AS TagRank
    FROM 
        TagStatistics
)
SELECT 
    t.TagName,
    t.TagCount,
    COUNT(tp.PostId) AS PostFrequency,
    AVG(u.Reputation) AS AverageUserReputation,
    MAX(tp.CreationDate) AS LastPostDate
FROM 
    MostCommonTag t
JOIN 
    TopPosts tp ON tp.Tags LIKE CONCAT('%', t.TagName, '%')
JOIN 
    Users u ON tp.OwnerName = u.DisplayName
WHERE 
    t.TagRank <= 5 
GROUP BY 
    t.TagName, t.TagCount
ORDER BY 
    t.TagCount DESC;
