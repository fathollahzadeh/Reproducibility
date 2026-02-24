WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn
    FROM
        Posts p
    JOIN
        Users u ON p.OwnerUserId = u.Id
    WHERE
        p.PostTypeId = 1 AND 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
),
AggregatedData AS (
    SELECT
        rp.OwnerDisplayName,
        COUNT(rp.PostId) AS QuestionCount,
        SUM(rp.Score) AS TotalScore,
        SUM(rp.ViewCount) AS TotalViews,
        AVG(rp.AnswerCount) AS AvgAnswers,
        AVG(rp.CommentCount) AS AvgComments
    FROM
        RankedPosts rp
    WHERE
        rp.rn <= 5 
    GROUP BY
        rp.OwnerDisplayName
)
SELECT
    ad.OwnerDisplayName,
    ad.QuestionCount,
    ad.TotalScore,
    ad.TotalViews,
    ad.AvgAnswers,
    ad.AvgComments,
    COALESCE(b.TotalBadges, 0) AS TotalBadges
FROM
    AggregatedData ad
LEFT JOIN (
    SELECT
        u.DisplayName,
        COUNT(b.Id) AS TotalBadges
    FROM
        Users u
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    GROUP BY
        u.DisplayName
) b ON ad.OwnerDisplayName = b.DisplayName
ORDER BY
    ad.TotalScore DESC,
    ad.QuestionCount DESC
LIMIT 10;