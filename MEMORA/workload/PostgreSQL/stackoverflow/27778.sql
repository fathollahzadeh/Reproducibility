
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Body, 
        p.Tags, 
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName, p.CreationDate
),
TopPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.Body,
        rp.Tags,
        rp.OwnerDisplayName,
        rp.CreationDate
    FROM 
        RankedPosts rp
    WHERE 
        rp.TagRank <= 5 
)
SELECT 
    t.Tags,
    COUNT(t.PostId) AS PostCount,
    AVG(u.Reputation) AS AvgOwnerReputation,
    STRING_AGG(t.OwnerDisplayName, ', ') AS TopOwners,
    MAX(t.CreationDate) AS MostRecentPostDate
FROM 
    TopPosts t
JOIN 
    Users u ON t.OwnerDisplayName = u.DisplayName
GROUP BY 
    t.Tags
ORDER BY 
    PostCount DESC, AvgOwnerReputation DESC;
