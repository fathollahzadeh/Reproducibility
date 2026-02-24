WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(voteCount.VoteCount) AS AverageVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS VoteCount 
        FROM 
            Votes 
        WHERE 
            VoteTypeId IN (2, 3) 
        GROUP BY 
            PostId
    ) voteCount ON p.Id = voteCount.PostId
    WHERE 
        u.Reputation > 1000 
    GROUP BY 
        u.Id, u.DisplayName
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LatestHistoryDate,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(rph.LatestHistoryDate, p.CreationDate) AS MostRecentActivity,
        rph.HistoryTypes,
        ups.TotalPosts AS UserTotalPosts,
        ups.AverageVotes
    FROM 
        Posts p
    LEFT JOIN 
        RecentPostHistory rph ON p.Id = rph.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        UserPostStats ups ON u.Id = ups.UserId
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.MostRecentActivity,
    pd.HistoryTypes,
    pd.UserTotalPosts,
    pd.AverageVotes
FROM 
    PostDetails pd
WHERE 
    pd.MostRecentActivity > cast('2024-10-01' as date) - INTERVAL '30 days' 
ORDER BY 
    pd.UserTotalPosts DESC, pd.AverageVotes DESC
LIMIT 50;