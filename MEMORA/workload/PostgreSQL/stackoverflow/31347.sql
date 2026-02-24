WITH RecursivePostHistory AS (
    SELECT 
        ph.Id,
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) as rn
    FROM 
        PostHistory ph
), 
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN ph.PostId END) AS TotalClosedReopenedPosts,
        AVG(COALESCE(p.Score, 0)) AS AvgPostScore,
        SUM(u.UpVotes) - SUM(u.DownVotes) AS ReputationDifference
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        u.Id, u.DisplayName
), 
TopUsers AS (
    SELECT 
        u.UserId,
        u.DisplayName,
        u.TotalPosts,
        u.TotalQuestions,
        u.TotalAnswers,
        u.TotalClosedReopenedPosts,
        u.AvgPostScore,
        RANK() OVER (ORDER BY u.TotalPosts DESC) AS TotalPostsRank
    FROM 
        UserPostStats u
    WHERE 
        u.TotalPosts > 0
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.TotalPosts,
    u.TotalQuestions,
    u.TotalAnswers,
    u.TotalClosedReopenedPosts,
    u.AvgPostScore,
    CASE 
        WHEN u.TotalQuestions > 0 
        THEN CAST(u.TotalAnswers AS DECIMAL) / u.TotalQuestions 
        ELSE NULL 
    END AS AnswerToQuestionRatio,
    u.TotalPostsRank
FROM 
    TopUsers u
WHERE 
    u.TotalPostsRank <= 10 
ORDER BY 
    u.TotalPostsRank;