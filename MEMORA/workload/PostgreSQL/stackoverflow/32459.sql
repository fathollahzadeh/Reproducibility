
WITH RECURSIVE UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS TotalAcceptedAnswers,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY SUM(COALESCE(p.Score, 0)) DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistorySummary AS (
    SELECT 
        ph.UserId,
        COUNT(ph.Id) AS TotalPostHistoryRecords,
        SUM(CASE WHEN pht.Name = 'Post Closed' THEN 1 ELSE 0 END) AS TotalPostClosed,
        SUM(CASE WHEN pht.Name = 'Post Reopened' THEN 1 ELSE 0 END) AS TotalPostReopened
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.UserId
),
UserCombinedStats AS (
    SELECT 
        ups.UserId,
        ups.DisplayName,
        ups.TotalPosts,
        ups.TotalQuestions,
        ups.TotalAnswers,
        ups.TotalAcceptedAnswers,
        ups.TotalScore,
        COALESCE(pSummary.TotalPostHistoryRecords, 0) AS TotalPostHistoryRecords,
        COALESCE(pSummary.TotalPostClosed, 0) AS TotalPostClosed,
        COALESCE(pSummary.TotalPostReopened, 0) AS TotalPostReopened
    FROM 
        UserPostStats ups
    LEFT JOIN 
        PostHistorySummary pSummary ON ups.UserId = pSummary.UserId
)
SELECT 
    ucs.DisplayName,
    ucs.TotalPosts,
    ucs.TotalQuestions,
    ucs.TotalAnswers,
    ucs.TotalAcceptedAnswers,
    ucs.TotalScore,
    ucs.TotalPostHistoryRecords,
    ucs.TotalPostClosed,
    ucs.TotalPostReopened
FROM 
    UserCombinedStats ucs
WHERE 
    ucs.TotalPosts > 10
ORDER BY 
    ucs.TotalScore DESC
LIMIT 10;
