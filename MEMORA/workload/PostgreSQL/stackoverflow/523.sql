WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
        SUM(COALESCE(v.UpVotes, 0)) AS TotalUpVotes,
        SUM(COALESCE(v.DownVotes, 0)) AS TotalDownVotes,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        (SELECT PostId, SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes, 
                          SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
         FROM Votes
         GROUP BY PostId) v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, DisplayName, TotalPosts, TotalQuestions, TotalAnswers, TotalUpVotes, TotalDownVotes
    FROM 
        UserPostStats
    WHERE 
        UserRank <= 10
),
PostHistories AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount,
        COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId = 24 THEN ph.Id END) AS EditCount,
        MAX(ph.CreationDate) AS LastChangeDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    u.DisplayName,
    u.TotalPosts,
    u.TotalQuestions,
    ph.CloseReopenCount,
    ph.EditCount,
    ph.LastChangeDate,
    CASE 
        WHEN ph.CloseReopenCount > 0 THEN 'Closed/Reopened'
        ELSE 'Active'
    END AS Status
FROM 
    TopUsers u
LEFT JOIN 
    PostHistories ph ON u.UserId = ph.PostId
ORDER BY 
    u.TotalPosts DESC, u.TotalUpVotes DESC;
