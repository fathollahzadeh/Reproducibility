
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COALESCE(NULLIF(p.Body, ''), 'No Content') AS PostBody
    FROM Posts p
    WHERE p.PostTypeId IN (1, 2) 
),
FilteredBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Badges b
    WHERE b.Class <= 2 
    GROUP BY b.UserId
),
PostHistoryAnalysis AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS ChangeCount,
        MAX(ph.CreationDate) AS LastChangeDate
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (10, 11, 12) 
    GROUP BY ph.PostId, ph.PostHistoryTypeId
),
PopularTags AS (
    SELECT 
        t.TagName,
        SUM(t.Count) AS TotalCount
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY t.TagName
    ORDER BY TotalCount DESC
),
QuestionAnswerStats AS (
    SELECT 
        p.OwnerUserId,
        AVG(COALESCE(a.Score, 0)) AS AvgAnswerScore,
        COUNT(a.Id) AS TotalAnswers,
        SUM(CASE WHEN phh.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS TotalClosed
    FROM Posts p
    LEFT JOIN Posts a ON p.Id = a.ParentId 
    LEFT JOIN PostHistory phh ON phh.PostId = p.Id
    WHERE p.PostTypeId = 1 
    GROUP BY p.OwnerUserId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.PostBody,
    fb.BadgeCount,
    fb.BadgeNames,
    qa.AvgAnswerScore,
    qa.TotalAnswers,
    qa.TotalClosed,
    pt.TagName,
    pt.TotalCount,
    ph.LastChangeDate
FROM Users u
JOIN RankedPosts rp ON u.Id = rp.PostId 
LEFT JOIN FilteredBadges fb ON u.Id = fb.UserId
LEFT JOIN QuestionAnswerStats qa ON u.Id = qa.OwnerUserId
LEFT JOIN PopularTags pt ON pt.TagName = ANY(STRING_TO_ARRAY(rp.PostBody, ' ')) 
LEFT JOIN PostHistoryAnalysis ph ON rp.PostId = ph.PostId AND ph.PostHistoryTypeId = 10 
WHERE rp.rn = 1 
AND fb.BadgeCount IS NOT NULL 
ORDER BY rp.Score DESC, u.Reputation DESC;
