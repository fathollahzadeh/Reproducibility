
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 YEAR')
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COALESCE(SUM(p.Score), 0) AS TotalScore,
        COUNT(DISTINCT CASE WHEN b.Id IS NOT NULL THEN b.Id END) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate,
        STRING_AGG(DISTINCT ph.Comment, '; ') AS HistoryComments
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        ph.PostId
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.QuestionCount,
    ups.AnswerCount,
    ups.TotalScore,
    ups.BadgeCount,
    rp.PostId,
    rp.Title AS RecentPostTitle,
    rp.Score AS RecentPostScore,
    COALESCE(phs.EditCount, 0) AS TotalEdits,
    phs.LastEditDate,
    phs.HistoryComments,
    CASE 
        WHEN ups.QuestionCount > 10 THEN 'Veteran'
        WHEN ups.QuestionCount > 5 THEN 'Experienced'
        ELSE 'Novice'
    END AS UserLevel,
    COUNT(DISTINCT pl.RelatedPostId) AS RelatedCount
FROM 
    UserPostStats ups
LEFT JOIN 
    RankedPosts rp ON ups.UserId = rp.OwnerUserId AND rp.RecentPostRank = 1
LEFT JOIN 
    PostHistorySummary phs ON rp.PostId = phs.PostId
LEFT JOIN 
    PostLinks pl ON rp.PostId = pl.PostId
GROUP BY 
    ups.UserId, ups.DisplayName, ups.QuestionCount, ups.AnswerCount, ups.TotalScore, ups.BadgeCount, rp.PostId, rp.Title, rp.Score, phs.EditCount, phs.LastEditDate, phs.HistoryComments
ORDER BY 
    ups.TotalScore DESC, ups.UserId;
