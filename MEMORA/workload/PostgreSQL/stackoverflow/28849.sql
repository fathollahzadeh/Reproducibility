WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND  
        p.Score > 0           
),
MostRecentPosts AS (
    SELECT 
        pr.PostId,
        pr.Title,
        pr.ViewCount,
        pr.Score,
        pr.CreationDate,
        pr.OwnerDisplayName,
        pr.OwnerReputation
    FROM 
        RankedPosts pr
    WHERE 
        pr.PostRank = 1
),
PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(t.Id) AS TagCount
    FROM 
        Posts p
    LEFT JOIN 
        UNNEST(string_to_array(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')) AS tag ON tag IS NOT NULL
    LEFT JOIN 
        Tags t ON t.TagName = tag
    GROUP BY 
        p.Id
),
TopQuestions AS (
    SELECT 
        mp.PostId,
        mp.Title,
        mp.ViewCount,
        mp.Score,
        mp.CreationDate,
        mp.OwnerDisplayName,
        mp.OwnerReputation,
        pt.TagCount
    FROM 
        MostRecentPosts mp
    JOIN 
        PostTagCounts pt ON mp.PostId = pt.PostId
    ORDER BY 
        mp.Score DESC, 
        mp.ViewCount DESC 
    LIMIT 10
)
SELECT 
    tq.PostId,
    tq.Title,
    tq.ViewCount,
    tq.Score,
    tq.CreationDate,
    tq.OwnerDisplayName,
    tq.OwnerReputation,
    tq.TagCount
FROM 
    TopQuestions tq
JOIN 
    Votes v ON v.PostId = tq.PostId AND v.VoteTypeId = 2  
GROUP BY 
    tq.PostId, tq.Title, tq.ViewCount, tq.Score, tq.CreationDate, tq.OwnerDisplayName, tq.OwnerReputation, tq.TagCount
ORDER BY 
    COUNT(v.Id) DESC;