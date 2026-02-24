WITH RankedPosts AS (
    SELECT
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM
        Posts p
    JOIN
        Users u ON p.OwnerUserId = u.Id
    WHERE
        p.PostTypeId = 1 
        AND p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 YEAR'
),
TopQuestions AS (
    SELECT
        rp.OwnerDisplayName,
        COUNT(rp.Id) AS TotalQuestions,
        SUM(rp.Score) AS TotalScore,
        AVG(rp.ViewCount) AS AvgViewCount,
        MIN(rp.CreationDate) AS FirstQuestionDate,
        MAX(rp.CreationDate) AS LastQuestionDate
    FROM
        RankedPosts rp
    WHERE
        rp.PostRank <= 5 
    GROUP BY
        rp.OwnerDisplayName
)
SELECT
    u.DisplayName,
    u.Reputation,
    u.CreationDate,
    tq.TotalQuestions,
    tq.TotalScore,
    tq.AvgViewCount,
    tq.FirstQuestionDate,
    tq.LastQuestionDate
FROM
    Users u
JOIN
    TopQuestions tq ON u.DisplayName = tq.OwnerDisplayName
WHERE
    u.Reputation > 1000
ORDER BY
    tq.TotalScore DESC,
    tq.TotalQuestions DESC;