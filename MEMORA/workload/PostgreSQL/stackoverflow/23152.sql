
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
        SUM(COALESCE(vs.VoteScore, 0)) AS TotalVoteScore,
        SUM(COALESCE(b.Id, 0)) AS TotalBadges
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN (
        SELECT 
            PostId, 
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 WHEN VoteTypeId = 3 THEN -1 ELSE 0 END) AS VoteScore
        FROM Votes
        GROUP BY PostId
    ) vs ON p.Id = vs.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
PostHistoryAnalysis AS (
    SELECT 
        ph.UserId,
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (12, 13) THEN 1 END) AS DeleteUndeleteCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (24) THEN 1 END) AS SuggestedEditsApplied
    FROM PostHistory ph
    GROUP BY ph.UserId, ph.PostId
),
AggregateData AS (
    SELECT 
        ups.UserId,
        ups.DisplayName,
        ups.TotalPosts,
        ups.TotalQuestions,
        ups.TotalAnswers,
        ups.TotalVoteScore,
        ups.TotalBadges,
        COALESCE(SUM(pha.CloseReopenCount), 0) AS TotalCloseReopen,
        COALESCE(SUM(pha.DeleteUndeleteCount), 0) AS TotalDeleteUndelete,
        COALESCE(SUM(pha.SuggestedEditsApplied), 0) AS TotalSuggestedEdit,
        ROW_NUMBER() OVER (ORDER BY ups.TotalVoteScore DESC) AS Rank
    FROM UserPostStats ups
    LEFT JOIN PostHistoryAnalysis pha ON ups.UserId = pha.UserId
    GROUP BY 
        ups.UserId, 
        ups.DisplayName, 
        ups.TotalPosts, 
        ups.TotalQuestions, 
        ups.TotalAnswers, 
        ups.TotalVoteScore, 
        ups.TotalBadges
)

SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    TotalVoteScore,
    TotalBadges,
    TotalCloseReopen,
    TotalDeleteUndelete,
    TotalSuggestedEdit,
    Rank
FROM AggregateData
WHERE TotalVoteScore > 0
ORDER BY TotalVoteScore DESC, TotalPosts DESC
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;
