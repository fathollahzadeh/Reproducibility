
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
UserStats AS (
    SELECT 
        u.Id AS UserID,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalQuestions,
        COUNT(DISTINCT a.Id) AS TotalAcceptedAnswers,
        AVG(COALESCE(p.ViewCount, 0)) AS AvgViewsPerQuestion,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 
    LEFT JOIN 
        Posts a ON u.Id = a.OwnerUserId AND a.AcceptedAnswerId IS NOT NULL 
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment,
        ht.Name AS HistoryType,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS RevRank
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes ht ON ph.PostHistoryTypeId = ht.Id
    WHERE 
        ph.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 months' 
),
PostWithHistory AS (
    SELECT 
        p.*, 
        phd.RevRank,
        phd.HistoryType,
        phd.Comment AS HistoryComment
    FROM 
        Posts p
    LEFT JOIN 
        PostHistoryDetails phd ON p.Id = phd.PostId
)
SELECT 
    us.UserID,
    us.DisplayName,
    us.TotalQuestions,
    us.TotalAcceptedAnswers,
    us.AvgViewsPerQuestion,
    us.GoldBadges,
    rp.Title,
    rp.CreationDate AS QuestionCreationDate,
    rp.ViewCount AS QuestionViews,
    rp.Score AS QuestionScore,
    COUNT(DISTINCT pwh.HistoryType) AS TotalHistoryTypes,
    MAX(pwh.HistoryComment) AS LatestHistoryComment
FROM 
    UserStats us
LEFT JOIN 
    RankedPosts rp ON us.UserID = rp.OwnerUserId AND rp.RN = 1
LEFT JOIN 
    PostWithHistory pwh ON rp.PostID = pwh.Id
GROUP BY 
    us.UserID, us.DisplayName, us.TotalQuestions, us.TotalAcceptedAnswers, 
    us.AvgViewsPerQuestion, us.GoldBadges, 
    rp.Title, rp.CreationDate, rp.ViewCount, rp.Score
ORDER BY 
    us.TotalQuestions DESC, us.GoldBadges DESC;
