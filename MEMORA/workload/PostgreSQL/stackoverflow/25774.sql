WITH RankedPosts AS (
    SELECT p.Id, 
           p.Title,
           p.Tags,
           p.CreationDate,
           p.Score,
           p.ViewCount,
           ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    WHERE p.PostTypeId = 1 
),
FilteredPosts AS (
    SELECT rp.Id, 
           rp.Title,
           rp.Tags,
           rp.CreationDate,
           rp.Score,
           rp.ViewCount
    FROM RankedPosts rp
    WHERE rp.rn <= 5 
),
PostScoreSummary AS (
    SELECT 
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        COUNT(fp.Id) AS QuestionCount,
        SUM(fp.Score) AS TotalScore,
        AVG(fp.ViewCount) AS AverageViewCount
    FROM FilteredPosts fp
    JOIN Posts p ON fp.Id = p.Id
    JOIN LATERAL (
        SELECT unnest(string_to_array(fp.Tags, ',')) AS TagName
    ) AS t ON TRUE 
    GROUP BY t.TagName
)
SELECT 
    ps.Tags,
    ps.QuestionCount,
    ps.TotalScore,
    ps.AverageViewCount,
    CASE 
        WHEN ps.QuestionCount > 10 THEN 'High Engagement'
        WHEN ps.QuestionCount > 5 THEN 'Moderate Engagement'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM PostScoreSummary ps
ORDER BY ps.TotalScore DESC;