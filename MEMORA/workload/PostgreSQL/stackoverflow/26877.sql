
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.Score,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        COALESCE(CONCAT(CAST(b.Class AS VARCHAR), ' ', b.Name), 'No Badges') AS UserBadges
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year' 
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        UNNEST(string_to_array(p.Tags, '><')) AS Tag
    FROM 
        Posts p
),

QuestionSummary AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.AnswerCount,
        rp.Score,
        rp.OwnerDisplayName,
        STRING_AGG(pt.Tag, ', ') AS Tags
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostTags pt ON rp.PostId = pt.PostId
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.ViewCount, rp.AnswerCount, rp.Score, rp.OwnerDisplayName
)

SELECT 
    qs.PostId,
    qs.Title,
    qs.CreationDate,
    qs.ViewCount,
    qs.AnswerCount,
    qs.Score,
    qs.OwnerDisplayName,
    qs.Tags,
    CASE 
        WHEN qs.Score >= 10 THEN 'Highly Rated'
        WHEN qs.Score BETWEEN 5 AND 9 THEN 'Moderately Rated'
        ELSE 'Low Rated'
    END AS RatingCategory
FROM 
    QuestionSummary qs
ORDER BY 
    qs.Score DESC, 
    qs.ViewCount DESC
LIMIT 50;
