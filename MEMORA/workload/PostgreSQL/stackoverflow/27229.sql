
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
LargeBodyPosts AS (
    SELECT 
        r.PostId,
        r.Title,
        r.Body,
        r.Tags,
        r.CreationDate,
        r.Score,
        r.ViewCount,
        r.AnswerCount,
        r.OwnerDisplayName,
        r.OwnerReputation
    FROM 
        RankedPosts r
    WHERE 
        LENGTH(r.Body) > 1000 
),
FrequentTagUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Tags) AS TagCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(p.Tags) > 10 
),
TopContributors AS (
    SELECT 
        UserId,
        DisplayName,
        SUM(TagCount) AS TotalTags
    FROM 
        FrequentTagUsers
    GROUP BY 
        UserId, DisplayName
    ORDER BY 
        TotalTags DESC
    LIMIT 5
)
SELECT 
    lbp.PostId,
    lbp.Title,
    lbp.Body,
    lbp.CreationDate,
    lbp.Score,
    lbp.ViewCount,
    lbp.AnswerCount,
    lbp.OwnerDisplayName,
    lbp.OwnerReputation,
    tc.DisplayName AS TopContributor,
    tc.TotalTags
FROM 
    LargeBodyPosts lbp
JOIN 
    TopContributors tc ON lbp.OwnerDisplayName = tc.DisplayName
ORDER BY 
    lbp.Score DESC, lbp.ViewCount DESC;
