
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
), 

RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalUpVotes,
        TotalDownVotes,
        RANK() OVER (ORDER BY Reputation DESC) AS UserRank
    FROM 
        UserStats
), 

HighReputationUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalUpVotes,
        TotalDownVotes
    FROM 
        RankedUsers
    WHERE 
        UserRank <= 100
), 

PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.Comment,
        ph.Text,
        p.Title,
        ph.UserId
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days' 
        AND p.OwnerUserId IS NOT NULL
)

SELECT 
    ru.DisplayName,
    ru.Reputation,
    ru.TotalPosts,
    ru.TotalQuestions,
    ru.TotalAnswers,
    ru.TotalUpVotes,
    ru.TotalDownVotes,
    p.Title AS PostTitle,
    phd.CreationDate AS HistoryDate,
    phd.Comment AS HistoryComment,
    phd.Text AS HistoryText
FROM 
    HighReputationUsers ru
LEFT JOIN 
    PostHistoryDetails phd ON ru.UserId = phd.UserId
LEFT JOIN 
    Posts p ON phd.PostId = p.Id
WHERE 
    (p.ViewCount > 100 OR phd.PostHistoryTypeId IN (10, 11, 12))
ORDER BY 
    ru.Reputation DESC, phd.CreationDate DESC;
