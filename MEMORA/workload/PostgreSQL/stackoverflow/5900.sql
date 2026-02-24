WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
HighScoreTags AS (
    SELECT 
        Tags,
        COUNT(*) AS QuestionCount,
        AVG(Score) AS AvgScore,
        SUM(ViewCount) AS TotalViews
    FROM 
        RankedPosts
    WHERE 
        TagRank <= 5 
    GROUP BY 
        Tags
)
SELECT 
    ht.Tags,
    ht.QuestionCount,
    ht.AvgScore,
    ht.TotalViews,
    COUNT(DISTINCT c.Id) AS TotalComments,
    SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
    SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
    SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
FROM 
    HighScoreTags ht
LEFT JOIN 
    Posts p ON p.Tags = ht.Tags AND p.PostTypeId = 1
LEFT JOIN 
    Comments c ON c.PostId = p.Id
LEFT JOIN 
    Badges b ON b.UserId = p.OwnerUserId
GROUP BY 
    ht.Tags, ht.QuestionCount, ht.AvgScore, ht.TotalViews
ORDER BY 
    ht.TotalViews DESC, ht.AvgScore DESC 
LIMIT 10;