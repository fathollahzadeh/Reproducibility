
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
        COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswerId
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
PostScoreAnalysis AS (
    SELECT 
        rp.PostId,
        COALESCE(rp.Score, 0) AS AdjustedScore,
        COUNT(c.Id) AS CommentCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON c.PostId = rp.PostId
    GROUP BY 
        rp.PostId, rp.Score
),
AcceptedAnswerInfo AS (
    SELECT 
        p.Id AS QuestionId, 
        a.Id AS AcceptedAnswerId,
        a.Score AS AcceptedAnswerScore
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.AcceptedAnswerId = a.Id
    WHERE 
        p.PostTypeId = 1 
)
SELECT 
    rp.PostId,
    rp.Title,
    sa.AcceptedAnswerId,
    sa.AcceptedAnswerScore,
    psa.CommentCount,
    CASE 
        WHEN psa.AdjustedScore IS NULL THEN 'No Score'
        WHEN psa.AdjustedScore > 0 THEN 'Scored Post'
        ELSE 'Unscored or Negative'
    END AS ScoreCategory,
    CASE 
        WHEN rp.UserPostRank = 1 THEN 'Most Recent Post by User'
        ELSE 'Not Most Recent'
    END AS UserPostStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    PostScoreAnalysis psa ON rp.PostId = psa.PostId
LEFT JOIN 
    AcceptedAnswerInfo sa ON rp.PostId = sa.QuestionId
WHERE 
    (rp.ViewCount > 100 OR psa.CommentCount > 5)
    AND (rp.CreationDate < TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 months' OR sa.AcceptedAnswerId IS NOT NULL)
ORDER BY 
    rp.UserPostRank DESC, 
    psa.AdjustedScore DESC NULLS LAST
LIMIT 50;
