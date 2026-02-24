
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        COUNT(v.Id) AS VoteCount,
        RANK() OVER (ORDER BY COUNT(v.Id) DESC) AS VoteRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, u.DisplayName, u.Reputation
), 
PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        UNNEST(STRING_TO_ARRAY(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), '><')) AS Tag
    FROM 
        Posts p
    WHERE 
        p.Tags IS NOT NULL
),
TagUsage AS (
    SELECT 
        Tag,
        COUNT(PostId) AS TagCount
    FROM 
        PostTagCounts
    GROUP BY 
        Tag
    ORDER BY 
        TagCount DESC
    LIMIT 10 
),
TopPosts AS (
    SELECT 
        rp.*,
        STRING_AGG(t.Tag, ', ') AS UsedTags
    FROM 
        RankedPosts rp
    JOIN 
        PostTagCounts pt ON rp.PostId = pt.PostId
    JOIN 
        TagUsage t ON pt.Tag = t.Tag
    GROUP BY 
        rp.PostId, rp.Title, rp.Body, rp.Tags, rp.CreationDate, rp.OwnerDisplayName, rp.OwnerReputation, rp.VoteCount, rp.VoteRank
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Body,
    tp.CreationDate,
    tp.OwnerDisplayName,
    tp.OwnerReputation,
    tp.VoteCount,
    tp.VoteRank,
    tp.UsedTags
FROM 
    TopPosts tp
WHERE 
    tp.VoteRank <= 5 
ORDER BY 
    tp.VoteCount DESC;
