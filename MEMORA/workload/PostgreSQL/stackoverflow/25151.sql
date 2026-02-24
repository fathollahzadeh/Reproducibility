WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS RankByTags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.Score > 0
),
HighScoringPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.Tags,
        rp.OwnerDisplayName,
        rp.OwnerReputation
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankByTags <= 5 
),
VotesAggregated AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    hsp.PostId,
    hsp.Title,
    hsp.Body,
    hsp.CreationDate,
    hsp.Score,
    hsp.ViewCount,
    hsp.Tags,
    hsp.OwnerDisplayName,
    hsp.OwnerReputation,
    va.VoteCount
FROM 
    HighScoringPosts hsp
JOIN 
    VotesAggregated va ON hsp.PostId = va.PostId
ORDER BY 
    hsp.Title ASC, hsp.Score DESC;