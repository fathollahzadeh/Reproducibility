
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM p.CreationDate) ORDER BY p.Score DESC) AS RankByScore,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM p.CreationDate) ORDER BY p.ViewCount DESC) AS RankByViews
    FROM
        Posts p
    WHERE
        p.PostTypeId = 1
        AND p.CreationDate >= '2021-01-01'
), ActiveUsers AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore
    FROM
        Users u
    JOIN
        Posts p ON u.Id = p.OwnerUserId
    WHERE
        u.Reputation > 100
    GROUP BY
        u.Id, u.DisplayName
), TopTags AS (
    SELECT
        t.TagName,
        COUNT(pt.Id) AS PostCount
    FROM
        Tags t
    JOIN
        Posts pt ON pt.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY
        t.TagName
    ORDER BY
        PostCount DESC
    LIMIT 10
)
SELECT
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    au.DisplayName AS OwnerDisplayName,
    au.PostCount AS OwnerPostCount,
    au.TotalScore AS OwnerTotalScore,
    tt.TagName
FROM
    RankedPosts rp
JOIN
    ActiveUsers au ON EXISTS (
        SELECT 1 FROM Posts p WHERE p.OwnerUserId = au.UserId AND p.Id = rp.PostId
    )
JOIN
    TopTags tt ON rp.Title ILIKE '%' || tt.TagName || '%'
WHERE
    rp.RankByScore <= 5 
    OR rp.RankByViews <= 5 
ORDER BY
    rp.CreationDate DESC;
