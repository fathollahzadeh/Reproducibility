WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS Author,
        COALESCE(a.AcceptedAnswerId, 0) AS HasAcceptedAnswer,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS TagRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON p.Id = a.AcceptedAnswerId
    WHERE 
        p.PostTypeId = 1 
        AND p.Score > 0 
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Tags,
    rp.Score,
    rp.CreationDate,
    rp.ViewCount,
    rp.Author,
    CASE 
        WHEN rp.HasAcceptedAnswer > 0 THEN 'Yes' 
        ELSE 'No' 
    END AS HasAcceptedAnswer,
    CONCAT('Tag Rank: ', rp.TagRank) AS TagRankInfo
FROM 
    RankedPosts rp
WHERE 
    rp.TagRank <= 5 
ORDER BY 
    rp.Tags, 
    rp.Score DESC;